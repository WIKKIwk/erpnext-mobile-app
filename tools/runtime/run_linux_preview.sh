#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

flutter pub get
API_URL="${MOBILE_API_BASE_URL:-https://core.wspace.sbs}"
flutter run -d linux --dart-define=MOBILE_API_BASE_URL="$API_URL"
