# SlotScout — iOS cancellation alert prototype

An independent SwiftUI iPhone starter app with onboarding, test-centre and date preferences, matching simulated appointments, an alert inbox, local test notifications, and optional Apple Push Notification service (APNs) demo backend.

**Not an RSA integration.** No actual RSA slots are fetched, checked, held, or booked. Not affiliated with the Road Safety Authority. No App Store approval is claimed.

## Run the iOS app

1. On a Mac, install Xcode (iOS 17 SDK or later) and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).
2. In the folder containing `project.yml`, run `xcodegen generate`.
3. Open `SlotScout.xcodeproj` in Xcode; update the `PRODUCT_BUNDLE_IDENTIFIER` and select your Apple development team.
4. Run on iOS Simulator or an iPhone. Open **Preferences → Enable iPhone notifications**, then **Home → Simulate a cancellation**. A matching sample item is added to the UI and a local notification is scheduled about two seconds later if allowed. Notification banners may depend on system settings and app state.
5. On a physical device, APNs registration additionally requires a valid Push Notifications capability, provisioning profile, and Apple Developer account; the simulator/local alert demo does not need real APNs credentials.

## Optional demo backend (Node 20+)

```sh
cd server
node server.mjs
curl http://127.0.0.1:8787/health
curl -X POST http://127.0.0.1:8787/simulate -H 'content-type: application/json' -d '{"centre":"Tallaght","start":"2026-10-15T09:30:00Z"}'
```

By default no iOS API URL is configured. Set Xcode Scheme → Run → Arguments → Environment Variables `SLOTSCOUT_API_BASE_URL` to `http://127.0.0.1:8787` **for the iOS simulator only**. For a physical iPhone, use an HTTPS backend reachable from that iPhone and adjust the server network binding and security before use. The backend listens only on loopback intentionally.

The server's `/register` accepts device tokens and preferences; `/simulate` filters registrations and attempts remote pushes for matches. It runs locally, in memory, and has no authentication — **never put it on the public internet as-is**.

To test real APNs remote pushes (not necessary for local alerts), provide these variables to Node: `APNS_KEY_PATH` (private Apple .p8 key), `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_BUNDLE_ID` (matching app), and optionally `APNS_PRODUCTION=true`. Never commit keys. The phone must successfully register its token with the demo backend. The development/sandbox APNs endpoint is the default.

## Before public release

- Obtain explicit permission or another licensed/authorised source for slot availability; no automated RSA access is included.
- Implement real user authentication, consent, database persistence, encryption/TLS, token lifecycle and deletion, rate limiting, anti-abuse controls, and notification preference synchronization.
- Secure the simulation endpoint and separate it completely from production data ingestion.
- Validate centre list and timezones (`Europe/Dublin`) against an authorised source; current list is illustrative.
- Add a privacy policy, account/data deletion experience, legal review, accessibility tests, production monitoring, and App Store listing materials. Avoid implying official RSA endorsement.
- For production replace the demo APNs sender with an authenticated queue/retry system, manage expired tokens and revoke invalid tokens.
- Never ask users for RSA account credentials or promise bookings.
