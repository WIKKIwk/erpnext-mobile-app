#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

flutter pub get
flutter run -d linux --dart-define=MOBILE_API_BASE_URL=http://127.0.0.1:8081
