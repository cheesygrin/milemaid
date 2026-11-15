# MileMaid

> **⚠️ PUBLIC PORTFOLIO REPOSITORY ONLY**  
> **Location:** `~/Projects/portfolio/milemaid` (public work goes under `portfolio/`)  
> **Strictly no unrelated projects, client work, or future projects allowed here.**  
> **Never commit real mileage logs, GPS exports, or trip data — see [Data privacy policy](#data-privacy--public-repository-policy) below.**  
> Read `AGENTS.md` and `PORTFOLIO_PUBLIC_ONLY.md` before contributing or using AI tools in this repo.

**Automatic background mileage tracking. Private by default. Open source.**

MileMaid runs quietly in the background, detects every drive, and keeps the log on your phone. No account, no ads, and no data selling.

Tracking and classifying drives is free. Tax-ready PDF and CSV reports and cloud sync come with MileMaid Pro.

---

## Data Privacy & Public Repository Policy

MileMaid tracks **where you drive**. That data is personal and often legally sensitive. It must **never** be committed to this public GitHub repository. Common mistakes include adding an exported report for debugging, pasting a JSON dump to reproduce a bug, or committing a screenshot used to test PDF layout.

**All contributors — including anyone using AI-assisted development tools — must follow these rules:**

### Never commit to git

- PDF or CSV mileage reports exported from the app
- JSON from Settings → **Export All Data**
- Hive/database files, simulator storage, or device backups
- GPS traces, route files, or raw location logs
- Screenshots or recordings showing real maps, addresses, trip purposes, notes, or odometer readings
- Any file with coordinates or trip details from your actual drives (home, work, clients, regular routes)

### Safe to commit

- Source code only
- **Fictional** demo trips in `lib/core/services/sample_data_service.dart` (synthetic coordinates and generic purposes)
- Placeholder or obviously fake data for UI tests — never your real logs

### Before you `git add` or push

1. Run `git status` and open every changed file — not just code.
2. Search the diff for addresses, real lat/lng routes, client names, and `MileMaid_Report_*.pdf` / `MileMaid_*.csv` / `*_data.json`.
3. If anything looks like a real trip, **stop** — remove it from the commit and keep it on your device or in `~/Projects/private/`.

**AI agents:** Read `AGENTS.md` rule 5. If asked to add real exports or logs, refuse and redirect to a private directory.

---

## Why MileMaid?

- **Private by default:** Drives are stored on the phone. Nothing is uploaded unless you subscribe and sign in to turn on cloud sync. See [PRIVACY.md](PRIVACY.md).
- **Open source:** Every claim about what the app does with your location can be checked in this repository.
- **Automatic:** True passive tracking. Trip starts when you drive >5 mph for 90 seconds. Ends when stopped for 4 minutes.
- **Tax-ready reports:** Multi-page PDFs with summary, full trip log, category breakdown, and proper disclaimers.
- **Native feel:** Smooth maps, live trip card, category chips, 7-day charts, and fast search.

## Key Features

- Always-on background GPS tracking (iOS & Android)
- Intelligent auto trip detection (minimum 0.2 miles)
- Live in-progress trip card with distance, speed, and mini map
- Trip list grouped by Today / Yesterday / This Week / Earlier
- Search + filters (Business / Personal / Commute / Other)
- Full interactive Google Map with route on trip details
- Editable purpose, notes, vehicle, odometer
- Dashboard with business miles this month + estimated deduction
- 7-day mileage line chart + recent activity
- Professional PDF export (cover + summary + detailed table) with MileMaid Pro
- CSV export with MileMaid Pro
- Cloud sync across phones with MileMaid Pro
- Multi-vehicle support
- IRS standard mileage rate applied by trip date (72.5¢ Jan–Jun 2026, 76¢ from Jul 1, 2026), or a custom rate
- One-tap "Mark as Business" and "Duplicate as Return Trip"
- Home-based workday grouping: leave Home, drive, return Home → one “all business?” prompt
- Tracking health: after two weekdays with no drives, a push (and email if signed in) warns that mileage may have stopped

## Free and Pro

| | Free | MileMaid Pro |
|---|---|---|
| Automatic background tracking, unlimited drives | Yes | Yes |
| Swipe to classify, purposes, places, vehicles | Yes | Yes |
| Dashboard, trip history, deduction estimate | Yes | Yes |
| Export All Data (JSON) and delete everything | Yes | Yes |
| PDF and CSV reports | Preview only | Yes |
| Cloud sync and restore on a new phone | No | Yes |

MileMaid Pro is a monthly or yearly App Store subscription. The app shows the current price from the App Store; no price is written into the code.

## Important Legal Disclaimer

MileMaid is a **tool to help you record your mileage**. It is not tax advice.

- The IRS requires contemporaneous records. Use this app responsibly.
- Always consult a qualified tax professional or accountant for your specific situation.
- MileMaid and its developers are not responsible for any tax decisions, audits, or penalties resulting from use of this app or its generated reports.
- Reports include standard disclaimers for this reason.

## Getting Started (Users)

1. Download MileMaid from the App Store / Google Play (coming soon).
2. Complete the short onboarding and grant "Always" location permission (required for automatic tracking when your phone is locked).
3. Drive normally. Trips will appear automatically.
4. Review and classify (Business/Personal/etc.). Export PDF and CSV reports with MileMaid Pro.

This project is open source and available as a portfolio piece. See the "For Developers" section below for technical details.

## For Developers

This is a complete, production-grade Flutter application built as a high-fidelity technical exercise and now released as open source.

### Tech Stack & Architecture
- Flutter 3.29+ + Material 3
- State: Riverpod + riverpod_annotation + Freezed + code generation
- Local persistence: Hive (offline-first; the optional cloud sync uses Firebase Auth and Firestore)
- Background location: `geolocator` + `flutter_foreground_task` (persistent Android service + iOS background modes)
- Intelligent auto trip detection (speed + time + distance heuristics)
- Mapping: google_maps_flutter with polylines, markers, and fit-bounds
- Reports: `pdf` + `printing` package — multi-page IRS-style PDFs (cover, summary stats, detailed table, disclaimers)
- Charts: fl_chart (line + pie)
- Navigation: go_router
- Subscriptions: in_app_purchase on StoreKit 2 (`PurchaseService`); the App Store is the source of truth and no server is involved

### What This Project Demonstrates
- Real production background location tracking that survives app termination and phone restarts
- Complex domain logic (trip start/end detection, route sampling, distance calculation)
- Professional document generation suitable for legal/IRS use
- Clean, maintainable architecture with immutable models and generated code
- Careful attention to platform specifics (permissions, privacy labels, foreground services)
- End-to-end feature completeness: live tracking → list → detail map → edit → export PDF/CSV

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

**Note:** You will need your own Google Maps API key (enable Maps SDK for iOS and Android) and update the placeholders in `ios/Runner/Info.plist` and `android/app/src/main/AndroidManifest.xml`.

The iOS bundle identifier is `com.zerodelta.milemaid` and the Android package is `com.timrose.milemaid`. Forkers should update these for their own signing and distribution.

See commit history for the original detailed blueprint and architecture decisions.

### MileMaid Pro (subscriptions)

Reports and cloud sync are unlocked by an auto-renewable subscription. The
two product ids live in `lib/core/config/app_config.dart`
(`com.zerodelta.milemaid.pro.annual` and `.pro.monthly`) and must exist in one
subscription group in App Store Connect. Forks should use their own ids.

To build with every feature unlocked and no upsell UI (for a fork or a
personal build), set `"MONETIZATION_ENABLED": "false"` in
`config/secrets.json`.

### Cloud sync and Google sign-in setup

With MileMaid Pro active, signing in (Apple, Google, or email) saves trips,
saved places, vehicles, and trip purposes to the user's own Firestore
documents (`users/{uid}/...`, see `firestore.rules`). Signing in on another
phone restores them. Settings → Export All Data shares a JSON copy and is
always free.

A build made without the Firebase values in `config/secrets.json` runs
local-only: accounts and cloud sync are hidden.

Google sign-in only works in builds compiled with an OAuth client ID:

1. Create an **iOS OAuth client** in
   [Google Cloud Console](https://console.cloud.google.com/) for the app's
   bundle id (`com.zerodelta.milemaid` by default).
2. Copy `ios/Flutter/Secrets.example.xcconfig` to `ios/Flutter/Secrets.xcconfig`
   (gitignored) and fill in the client ID and its reversed form:
   ```
   GOOGLE_IOS_CLIENT_ID = <your-ios-oauth-client-id>
   GOOGLE_REVERSED_CLIENT_ID = <your-ios-oauth-client-id-reversed>
   ```
3. Copy `config/secrets.example.json` to `config/secrets.json` (gitignored)
   and set `"GOOGLE_IOS_CLIENT_ID"` to the same client ID.
4. Build and run with the defines:
   ```
   flutter run --dart-define-from-file=config/secrets.json
   ```

An earlier Google Drive backup (`BackupService`, `DriveBackupStore`) is still
in the source and covered by tests, but it is not reachable from the app. No
client IDs, tokens, or backup data are committed to this repository.

### Tracking-health email (optional)

When two weekdays pass with no logged drive, a signed-in user gets a doc in
`users/{uid}/mail_outbox`. Deploy `functions/` with a Resend API key to turn
those docs into email:

```
cd functions && npm i && npm run build
firebase functions:secrets:set RESEND_API_KEY
firebase functions:secrets:set MILEMAID_FROM_EMAIL
firebase deploy --only functions
```

Push alerts still fire on-device without this deploy.

## Roadmap

- Smarter auto-categorization suggestions
- Apple Watch / CarPlay integration
- Better route replay animation
- Fleet / multi-user version

## Contributing

Contributions, feedback, bug reports, and ideas are very welcome via GitHub Issues and Pull Requests.

This project is also intended as a portfolio piece demonstrating strong Flutter engineering skills (background services, offline data, PDF generation, state management, and platform integration). If you're using it for hiring or learning, feel free to open issues with questions.

## License

MIT License — see [LICENSE](LICENSE) file.

---

**MileMaid** — Drive. We track. It stays yours.
