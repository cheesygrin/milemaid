#!/usr/bin/env bash
set -euo pipefail

# Resolve the repo root from this script's own path.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

flutter pub get
flutter analyze --no-fatal-infos
flutter test
