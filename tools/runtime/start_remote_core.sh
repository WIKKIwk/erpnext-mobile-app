#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GARAGE_DIR="$REPO_ROOT/garbage"
CORE_URL="${CORE_URL:-http://127.0.0.1:8081}"
mkdir -p "$GARAGE_DIR"
TUNNEL_LOG="$GARAGE_DIR/.core_tunnel.log"
TUNNEL_PID="$GARAGE_DIR/.core_tunnel.pid"
TUNNEL_URL_FILE="$GARAGE_DIR/.core_tunnel_url"

BACKEND_ROOT="${BACKEND_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
API_URL="$CORE_URL" BACKEND_ROOT="$BACKEND_ROOT" "$SCRIPT_DIR/../bootstrap/ensure_core.sh"

if [ -f "$TUNNEL_PID" ]; then
	PID="$(cat "$TUNNEL_PID" 2>/dev/null || true)"
	if [ -n "${PID:-}" ] && kill -0 "$PID" 2>/dev/null; then
		if [ -f "$TUNNEL_URL_FILE" ] && grep -q '^https://.*trycloudflare.com' "$TUNNEL_URL_FILE"; then
			cat "$TUNNEL_URL_FILE"
			exit 0
		fi
	fi
	rm -f "$TUNNEL_PID" "$TUNNEL_URL_FILE"
fi

rm -f "$TUNNEL_LOG" "$TUNNEL_URL_FILE"
setsid cloudflared tunnel --url "$CORE_URL" --no-autoupdate >"$TUNNEL_LOG" 2>&1 < /dev/null &
echo $! >"$TUNNEL_PID"

for _ in $(seq 1 80); do
	if [ -f "$TUNNEL_LOG" ]; then
		URL="$(grep -o 'https://[-a-zA-Z0-9.]*trycloudflare.com' "$TUNNEL_LOG" | tail -n 1 || true)"
		if [ -n "${URL:-}" ]; then
			printf '%s\n' "$URL" >"$TUNNEL_URL_FILE"
			printf '%s\n' "$URL"
			exit 0
		fi
	fi
	sleep 0.5
done

echo "remote tunnel failed; see $TUNNEL_LOG" >&2
exit 1
