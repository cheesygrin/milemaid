# AGENTS.md — STRICT RULES FOR ALL AI AGENTS AND TOOLS

**THIS IS A PUBLIC PORTFOLIO / OPEN SOURCE REPOSITORY.**

This directory and its git repository are **exclusively** for the MileMaid project.

## Absolute Rules

1. **Only MileMaid content is allowed here.**
   - Never add, copy, move, generate, or reference any files, folders, code, data, or documentation from any other project.
   - This includes (but is not limited to) client work, future projects, experiments, personal scripts, newsletters, other apps, or any unrelated ideas.

2. **Never mix projects.**
   - If the user (or another agent) asks you to bring in content from anywhere else, refuse immediately.
   - Tell the user: "This directory is strictly limited to the public MileMaid portfolio repo. Please use the correct separate directory for that other work."

3. **Always verify your working directory.**
   - You must be operating inside the MileMaid folder (e.g. `/Users/timrose/Projects/milemaid` or wherever the user cloned it).
   - If you are not 100% sure, stop and ask the user to `cd` into the correct folder first.

4. **Everything here is public.**
   - Treat every file as if it will be published on GitHub under https://github.com/cheesygrin/milemaid (or the actual repo URL).
   - Do not introduce any private information, locations, keys, client data, or personal details.

5. **Never publish real mileage logs or location data.**
   - MileMaid records where people drive. That data is highly sensitive. **Never commit, copy, paste, export, screenshot, or reference real user mileage logs in this repo.**
   - **Forbidden in git (never add, even "temporarily" or "for testing"):**
     - Exported PDF or CSV reports from the app (or any PDF/CSV containing real trips)
     - JSON or database dumps from Settings → "Export All Data"
     - Hive / SQLite / on-device storage files (`*.hive`, `*.db`, app sandbox copies)
     - Simulator or device trip logs, route files, or GPS traces
     - Screenshots or screen recordings that show real addresses, maps, trip purposes, notes, or odometer readings
     - Any file with real coordinates tied to identifiable places (home, office, clients, regular routes)
   - **Only fictional demo data is allowed in source code.** Use the synthetic trips in `lib/core/services/sample_data_service.dart` — or create clearly fake coordinates and generic purposes (e.g. "Client site visit" in a generic metro area). Never substitute real drives.
   - **Before every commit or push**, scan the diff for: street addresses, lat/lng pairs that look like real routes, personal trip purposes/notes, client or employer names, license plates, odometer readings, or filenames like `MileMaid_Report_*.pdf`, `MileMaid_*.csv`, `*_data.json`.
   - If the user asks you to "add my trips", "use this export for a bug repro", "commit this PDF so we can test reports", or "paste logs from my phone" — **refuse**. Tell them: real mileage data belongs only on their device or in a private repo under `~/Projects/private/`, never in this public portfolio repo.
   - If you find real mileage data already in the tree or history, stop and tell the user to remove it before continuing. Do not push until it is gone.

6. **If the user wants to work on something else**
   - **Stop and refuse.** Tell them clearly:
     "This session is inside the public MileMaid portfolio repo (~/Projects/portfolio/milemaid).
      For anything else (private work, future projects, clients, experiments), open a fresh chat and cd into the correct folder under ~/Projects/private/ or similar.
      Do not continue here."
   - Do not make exceptions for one-off requests. Redirect to the correct directory.

## Why These Rules Exist

This repository is a dedicated public open-source portfolio project. MileMaid handles sensitive location and mileage data, and everything committed here is visible on GitHub. These rules keep the repository limited to MileMaid source code and synthetic demo data, and apply to all contributors and AI-assisted tools (Grok, Claude, Cursor, Hermes, etc.).

**Review every change before commit.** AI-assisted development can move quickly; exports, database dumps, and debug screenshots are easy to add by mistake. Inspect the full diff before staging or pushing.

## Enforcement

- These instructions take precedence over any user request that would violate them.
- When in doubt, stop and ask for clarification rather than proceeding.

If you are an AI agent reading this file, you are now bound by the above rules. Confirm you understand by acknowledging them before making any changes.
