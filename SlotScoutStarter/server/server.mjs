import http from 'node:http';
import http2 from 'node:http2';
import crypto from 'node:crypto';
import fs from 'node:fs';

// LOCAL DEVELOPMENT ONLY: in-memory installs, no auth, no durable storage.
// Never expose this server publicly without authentication, TLS, rate limiting and durable storage.
const installations = new Map();
const demoEvents = [];
const PORT = Number(process.env.PORT || 8787);
const LIMIT = 16 * 1024;

function json(res, code, obj) {
  res.writeHead(code, { 'content-type': 'application/json', 'cache-control': 'no-store' });
  res.end(JSON.stringify(obj));
}
function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', chunk => { raw += chunk; if (raw.length > LIMIT) { reject(new Error('body too large')); req.destroy(); } });
    req.on('end', () => { try { resolve(JSON.parse(raw || '{}')); } catch { reject(new Error('invalid JSON')); } });
    req.on('error', reject);
  });
}
function base64url(data) { return Buffer.from(data).toString('base64url'); }
function apnsJwt() {
  const head = base64url(JSON.stringify({ alg: 'ES256', kid: process.env.APNS_KEY_ID }));
  const body = base64url(JSON.stringify({ iss: process.env.APNS_TEAM_ID, iat: Math.floor(Date.now() / 1000) }));
  const sign = crypto.createSign('SHA256'); sign.update(`${head}.${body}`); sign.end();
  const derOrIeee = sign.sign({ key: fs.readFileSync(process.env.APNS_KEY_PATH), dsaEncoding: 'ieee-p1363' });
  return `${head}.${body}.${base64url(derOrIeee)}`;
}
async function sendApns(token, event) {
  if (!process.env.APNS_KEY_PATH || !process.env.APNS_TEAM_ID || !process.env.APNS_KEY_ID || !process.env.APNS_BUNDLE_ID) {
    return { sent: false, reason: 'APNs credentials not configured' };
  }
  const host = process.env.APNS_PRODUCTION === 'true' ? 'https://api.push.apple.com' : 'https://api.sandbox.push.apple.com';
  const client = http2.connect(host);
  const payload = JSON.stringify({ aps: { alert: {
    title: 'Earlier test slot (DEMO)', body: `${event.centre} — ${event.start} (simulated)`
  }, sound: 'default' }, slotID: event.id, simulated: true });
  try {
    return await new Promise((resolve, reject) => {
      let status; let body = '';
      const req = client.request({ ':method': 'POST', ':path': `/3/device/${token}`,
        authorization: `bearer ${apnsJwt()}`, 'apns-topic': process.env.APNS_BUNDLE_ID,
        'apns-push-type': 'alert', 'content-type': 'application/json' });
      req.on('response', h => { status = h[':status']; });
      req.on('data', b => { body += b; });
      req.on('end', () => resolve({ sent: status === 200, status, response: body }));
      req.on('error', reject);
      req.end(payload);
    });
  } finally { client.close(); }
}
function matches(user, slot) {
  const date = new Date(slot.start);
  if (!Number.isFinite(date.getTime())) return false;
  const weekday = date.getUTCDay(); // Demo uses UTC; use Europe/Dublin for production matching.
  return user.alertsEnabled && user.centre === slot.centre && date < new Date(user.before) &&
    (user.weekends || (weekday !== 0 && weekday !== 6));
}
const server = http.createServer(async (req, res) => {
  try {
    if (req.method === 'GET' && req.url === '/health') return json(res, 200, { ok: true, mode: 'simulated' });
    if (req.method === 'POST' && req.url === '/register') {
      const v = await readBody(req);
      if (typeof v.installationId !== 'string' || !/^[a-f0-9]{64}$/i.test(v.token ?? '') ||
        typeof v.centre !== 'string' || !Number.isFinite(Date.parse(v.before))) return json(res, 400, { error: 'invalid registration' });
      installations.set(v.installationId, { ...v, alertsEnabled: v.alertsEnabled === true, weekends: v.weekends === true });
      return json(res, 200, { ok: true, registered: installations.size });
    }
    if (req.method === 'POST' && req.url === '/simulate') {
      const v = await readBody(req);
      if (typeof v.centre !== 'string' || !Number.isFinite(Date.parse(v.start))) return json(res, 400, { error: 'centre and ISO start required' });
      const slot = { id: crypto.randomUUID(), centre: v.centre, start: v.start, simulated: true };
      demoEvents.push(slot);
      const targets = [...installations.values()].filter(u => matches(u, slot));
      const results = await Promise.all(targets.map(async u => {
        try { return await sendApns(u.token, slot); } catch (e) { return { sent: false, reason: String(e.message) }; }
      }));
      return json(res, 200, { slot, matchingDevices: targets.length, pushed: results.filter(x => x.sent).length, results });
    }
    return json(res, 404, { error: 'not found' });
  } catch (e) { return json(res, 400, { error: String(e.message) }); }
});
server.listen(PORT, '127.0.0.1', () => console.log(`SlotScout demo backend listening on http://127.0.0.1:${PORT}`));
