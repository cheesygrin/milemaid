# MileMaid Privacy Policy

_Last updated: November 13, 2026_

MileMaid is a mileage log. It records your drives so you can classify them and build reports for your own records. This policy says what the app stores, what leaves your phone, and what you can do about it. The app's source code is public, so every statement here can be checked against the code in this repository.

## The short version

- Your drives are stored on your iPhone. You do not need an account to use MileMaid.
- Nothing is uploaded to us unless you subscribe to MileMaid Pro **and** sign in to turn on cloud sync.
- We do not sell your data, show ads, or track you across other companies' apps or websites.
- You can export or delete your data at any time, with or without a subscription.

## What MileMaid stores on your phone

- **Location.** With your permission, MileMaid uses your precise location in the background to detect when a drive starts and ends, and stores a sampled route, the distance, and the start and end times of each drive.
- **What you add.** Trip categories, purposes and notes, tolls and parking, vehicles, saved places, work hours, and the name and email address you choose to show on reports.

This stays in the app's storage on your device.

## What leaves your phone, and when

**Cloud sync (optional, MileMaid Pro).** If you subscribe to MileMaid Pro and sign in with Apple, Google, or an email address, your trips (including routes, addresses, purposes and notes), saved places, vehicles, and trip purposes are saved to your account in Google Firebase (Authentication and Cloud Firestore) so they can be restored on another phone. This links your email address, your name if Apple or Google provides it, and an account identifier to your trip history. Access is restricted so that only your signed-in account can read or write your data. If you are not signed in, or your subscription is not active, nothing is uploaded.

**Address lookup (optional, off by default).** If you turn on "Record addresses" in Settings, the start and end coordinates of each drive are sent to Apple's geocoding service to look up a street address.

**Route maps.** Where the app shows a map of a route, the map is drawn by the Google Maps SDK, which receives the area being displayed.

**Subscriptions.** MileMaid Pro is sold through Apple's in-app purchase system. Apple processes the payment. MileMaid receives only confirmation that a subscription is active and never sees your card or billing details.

**Reports and exports.** PDF and CSV reports and "Export All Data" files are created on your phone and go only where you send them.

## What we do not do

- We do not sell or rent personal data.
- We do not use your data for advertising, and the app contains no ad or analytics SDKs.
- We do not track you across apps or websites owned by other companies.

## Keeping and deleting data

- **On your phone:** data stays until you delete trips or use Settings → Delete All Data, or delete the app.
- **In the cloud:** data stays in your account until you delete it. Settings → Delete account permanently removes your sign-in and the cloud copy of your trips, places, vehicles, and purposes. Deleting an account does not require a subscription. If you signed in with Apple, MileMaid's access to your Apple ID is revoked as part of deletion.
- Ending a subscription pauses cloud sync. It does not delete anything on your phone.

## Your choices

- Use the app without an account.
- Turn location access off in iOS Settings at any time (automatic tracking stops).
- Leave "Record addresses" off.
- Export everything from Settings → Export All Data.
- Delete your data and your account from Settings.

## Children

MileMaid is intended for drivers and is not directed at children under 13.

## Changes

If this policy changes, the updated version will be published at this address with a new date. The history of this file is public in the repository.

## Contact

Questions and data requests: open an issue at https://github.com/cheesygrin/milemaid/issues.

MileMaid is a record-keeping tool and does not provide tax, legal, or accounting advice.
