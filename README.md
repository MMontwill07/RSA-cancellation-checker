# SlotScout — iPhone Home Screen MVP

A static Progressive Web App for **simulated** RSA driving-test cancellation alerts. No access to RSA, accounts, actual test slots, or real push server. Test centres and matching demo dates are configurable, and preferences are saved in localStorage.

## Run immediately

To preview the screens on a computer, open `index.html` in a modern browser. The website is intended to be hosted to enable installing it as an iPhone Home Screen app.

## Publish from an iPhone using GitHub Pages (public demo)

1. Create a GitHub account (if needed), then a new **public** repository (e.g. `slotscout-demo`).
2. Upload **all six kinds of files** from the extracted `SlotScoutWebApp` folder to the repository root: `index.html`, `manifest.webmanifest`, `sw.js`, `icon.svg`, and the three `.png` icon files. GitHub's browser uploader may be simpler in desktop-site mode on iPhone.
3. Go to repository **Settings → Pages**, choose **Deploy from a branch**, select `main` and `/ (root)`, then Save.
4. GitHub provides an HTTPS URL such as `https://USERNAME.github.io/slotscout-demo/`. Open it in **Safari** on iPhone, use **Share → Add to Home Screen → Add**, then launch SlotScout from the new icon.
5. Choose **Preferences**, pick a test centre and deadline, then **Simulate a cancellation**. Matching samples appear under Alerts.

Do not put private information in a public GitHub repository. The files shipped here contain no private keys.

## Notification limitations

The MVP generates an in-app alert every time a simulated slot matches the saved filters. It can **optionally attempt a local browser notification** while the app is running, after permission is granted, on supported iOS Home Screen installations. This is **not a remote push service**: it cannot notify you when the app is closed based on new slots, and no ongoing background checking exists. That needs a server, Web Push subscriptions/VAPID credentials, notification APIs, and an authorised availability data source.

## Important

Not affiliated with RSA. The generated test appointments are fictional and may not represent actual services or offered times. The link to MyRoadSafety opens the official website only; no live detection or reservation is provided.
