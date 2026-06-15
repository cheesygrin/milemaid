# MileMaid

**Automatic background mileage tracking. Professional IRS-ready reports. Half the price of MileIQ.**

MileMaid runs silently in the background, detects every drive using smart motion + GPS, and produces clean, multi-page PDF reports you can hand to your accountant.

No buttons to press. No subscriptions to MileIQ's $14/month.

**Pricing:** $4.99/month or $49/year (or $9/month for the premium tier with priority support & future cloud sync).

---

## Why MileMaid?

- **Cheaper:** $4.99/mo or $49/yr vs MileIQ's $14/mo or $130/yr.
- **Automatic:** True passive tracking. Trip starts when you drive >5 mph for 90 seconds. Ends when stopped for 4 minutes.
- **IRS-friendly reports:** Beautiful, multi-page PDFs with summary, full trip log, category breakdown, and proper disclaimers.
- **Private by design:** Everything stored locally with Hive. Export or delete your data anytime.
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
- Professional PDF export (cover + summary + detailed table)
- CSV export
- Multi-vehicle support
- Custom mileage rate (defaults to 2026 IRS rate of $0.72/mi)
- One-tap "Mark as Business" and "Duplicate as Return Trip"

## Pricing & Plans

| Plan          | Price          | What's Included                          |
|---------------|----------------|------------------------------------------|
| **Starter**   | Free           | Basic tracking, limited trips, watermarked PDFs |
| **Pro**       | $4.99/mo or $49/yr | Unlimited trips, full professional PDFs, all exports, more vehicles |
| **Premium**   | $9/mo or $89/yr  | Everything in Pro + priority support, early access to cloud backup & sync |

*Prices subject to change. Annual plans save ~18%.*

## Important Legal Disclaimer

MileMaid is a **tool to help you record your mileage**. It is not tax advice.

- The IRS requires contemporaneous records. Use this app responsibly.
- Always consult a qualified tax professional or accountant for your specific situation.
- MileMaid and its developers are not responsible for any tax decisions, audits, or penalties resulting from use of this app or its generated reports.
- Reports include standard disclaimers for this reason.

## Getting Started (Users)

1. Download MileMaid from the App Store / Google Play (coming soon — join the waitlist below).
2. Complete the short onboarding and grant "Always" location permission (required for automatic tracking when your phone is locked).
3. Drive normally. Trips will appear automatically.
4. Review, classify (Business/Personal/etc.), and export professional PDFs whenever you need them.

**Early access / beta:** [Sign up link placeholder]

## For Developers

This project was originally built as a high-fidelity technical exercise following a detailed production-ready Flutter blueprint.

Interested in the tech?

- Flutter 3.29+
- Riverpod + Freezed + codegen
- `geolocator` + `flutter_foreground_task` for reliable background tracking
- `pdf` + `printing` for multi-page IRS-style reports
- Google Maps with polyline rendering
- Fully offline-first with Hive

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

**Note:** You will need your own Google Maps API key (enable Maps SDK for iOS and Android).

See the original technical blueprint and architecture decisions in the commit history / docs.

## Roadmap

- In-app subscriptions (Pro / Premium)
- Cloud sync option (optional, encrypted)
- Smarter auto-categorization suggestions
- Apple Watch / CarPlay integration
- Better route replay animation
- Fleet / multi-user version

## Contributing

For now this is primarily a solo project while we get the core experience solid. Feedback, bug reports, and ideas are welcome via GitHub Issues.

If you're a Flutter developer looking for interesting background location + document generation work, feel free to reach out.

## License

MIT License — see [LICENSE](LICENSE) file.

---

**MileMaid** — Drive. We track. For less.

*Not affiliated with MileIQ.*
