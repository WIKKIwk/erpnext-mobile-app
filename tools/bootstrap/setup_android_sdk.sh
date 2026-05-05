#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDK_ROOT="${ANDROID_HOME:-$HOME/Android/Sdk}"
JDK_ROOT="${JDK_HOME:-/usr/lib/jvm/java-17-openjdk}"
CMDLINE_VERSION="${ANDROID_CMDLINE_VERSION:-13114758}"
ZIP_URL="https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_VERSION}_latest.zip"
TMP_DIR="$(mktemp -d)"
ZIP_PATH="$TMP_DIR/cmdline-tools.zip"

mkdir -p "$SDK_ROOT/cmdline-tools"

if [ ! -x "$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
	echo "Downloading Android command line tools..."
	curl -L "$ZIP_URL" -o "$ZIP_PATH"
	rm -rf "$SDK_ROOT/cmdline-tools/latest"
	mkdir -p "$SDK_ROOT/cmdline-tools/latest"
	unzip -q "$ZIP_PATH" -d "$TMP_DIR/unpacked"
	cp -R "$TMP_DIR/unpacked/cmdline-tools/." "$SDK_ROOT/cmdline-tools/latest/"
fi

export ANDROID_HOME="$SDK_ROOT"
export ANDROID_SDK_ROOT="$SDK_ROOT"
export PATH="$SDK_ROOT/cmdline-tools/latest/bin:$SDK_ROOT/platform-tools:$PATH"

set +o pipefail
yes | sdkmanager --licenses >/dev/null || true
set -o pipefail
sdkmanager \
	"platform-tools" \
	"platforms;android-36" \
	"platforms;android-35" \
	"build-tools;35.0.0" \
	"build-tools;28.0.3" >/dev/null

flutter config --android-sdk "$SDK_ROOT" >/dev/null
if [ -d "$JDK_ROOT" ]; then
	flutter config --jdk-dir "$JDK_ROOT" >/dev/null
fi

cat >"$REPO_ROOT/android/local.properties" <<EOF
sdk.dir=$SDK_ROOT
flutter.sdk=$HOME/.local/flutter
EOF

rm -rf "$TMP_DIR"
echo "Android SDK ready at $SDK_ROOT"
