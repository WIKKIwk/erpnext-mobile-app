#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GARAGE_DIR="$REPO_ROOT/garbage"
CORE_URL="${CORE_URL:-http://127.0.0.1:8081}"
TUNNEL_NAME="${TUNNEL_NAME:-accord-vision-core}"
PUBLIC_HOSTNAME="${PUBLIC_HOSTNAME:-core.wspace.sbs}"
SKIP_PUBLIC_HEALTHCHECK="${SKIP_PUBLIC_HEALTHCHECK:-0}"
mkdir -p "$GARAGE_DIR"
TUNNEL_LOG="$GARAGE_DIR/.core_domain_tunnel.log"
TUNNEL_PID="$GARAGE_DIR/.core_domain_tunnel.pid"
TUNNEL_URL_FILE="$GARAGE_DIR/.core_domain_url"
TUNNEL_CONFIG="$GARAGE_DIR/.core_domain_tunnel.yml"

BACKEND_ROOT="${BACKEND_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
API_URL="$CORE_URL" BACKEND_ROOT="$BACKEND_ROOT" "$SCRIPT_DIR/../bootstrap/ensure_core.sh"

TUNNEL_ID="$(cloudflared tunnel list 2>/dev/null | awk -v name="$TUNNEL_NAME" '$2 == name {print $1; exit}')"
if [ -z "${TUNNEL_ID:-}" ]; then
	echo "Tunnel topilmadi: $TUNNEL_NAME" >&2
	exit 1
fi

CREDENTIALS_FILE="$HOME/.cloudflared/${TUNNEL_ID}.json"
if [ ! -f "$CREDENTIALS_FILE" ]; then
	echo "Tunnel credentials topilmadi: $CREDENTIALS_FILE" >&2
	exit 1
fi

stop_existing_tunnel() {
	pids_file=""
	if [ -f "$TUNNEL_PID" ]; then
		pids_file="$(cat "$TUNNEL_PID" 2>/dev/null || true)"
	fi
	pids_match="$(pgrep -f "cloudflared tunnel --config $TUNNEL_CONFIG run $TUNNEL_NAME" || true)"
	pids="$(printf '%s\n%s\n' "$pids_file" "$pids_match" | tr ' ' '\n' | awk 'NF' | sort -u | paste -sd' ' -)"
	if [ -n "${pids:-}" ]; then
		echo "Stopping stale domain tunnel process(es): $pids"
		kill $pids 2>/dev/null || true
		sleep 1
		alive="$(for pid in $pids; do kill -0 "$pid" 2>/dev/null && echo "$pid"; done || true)"
		if [ -n "${alive:-}" ]; then
			echo "Force killing stale domain tunnel process(es): $alive"
			kill -9 $alive 2>/dev/null || true
		fi
	fi
	rm -f "$TUNNEL_PID" "$TUNNEL_URL_FILE"
}

current_service=""
if [ -f "$TUNNEL_CONFIG" ]; then
	current_service="$(sed -n 's/^    service: //p' "$TUNNEL_CONFIG" | head -n1 | tr -d '\r')"
fi

if [ -f "$TUNNEL_PID" ]; then
	PID="$(cat "$TUNNEL_PID" 2>/dev/null || true)"
	if [ -n "${PID:-}" ] && kill -0 "$PID" 2>/dev/null && [ "$current_service" = "$CORE_URL" ]; then
		printf 'https://%s\n' "$PUBLIC_HOSTNAME" >"$TUNNEL_URL_FILE"
		cat "$TUNNEL_URL_FILE"
		exit 0
	fi
	stop_existing_tunnel
elif [ -n "$current_service" ] && [ "$current_service" != "$CORE_URL" ]; then
	stop_existing_tunnel
fi

cat >"$TUNNEL_CONFIG" <<EOF
tunnel: $TUNNEL_ID
credentials-file: $CREDENTIALS_FILE

ingress:
  - hostname: $PUBLIC_HOSTNAME
    service: $CORE_URL
  - service: http_status:404
EOF

rm -f "$TUNNEL_LOG"
setsid cloudflared tunnel --config "$TUNNEL_CONFIG" run "$TUNNEL_NAME" >"$TUNNEL_LOG" 2>&1 < /dev/null &
echo $! >"$TUNNEL_PID"

if [ "$SKIP_PUBLIC_HEALTHCHECK" = "1" ]; then
	sleep 0.5
	if kill -0 "$(cat "$TUNNEL_PID")" 2>/dev/null; then
		printf 'https://%s\n' "$PUBLIC_HOSTNAME" >"$TUNNEL_URL_FILE"
		cat "$TUNNEL_URL_FILE"
		exit 0
	fi
	echo "domain tunnel exited early; see $TUNNEL_LOG" >&2
	exit 1
fi

for _ in $(seq 1 80); do
	if curl -fsS "https://$PUBLIC_HOSTNAME/healthz" >/dev/null 2>&1; then
		printf 'https://%s\n' "$PUBLIC_HOSTNAME" >"$TUNNEL_URL_FILE"
		cat "$TUNNEL_URL_FILE"
		exit 0
	fi
	sleep 0.5
done

echo "domain tunnel failed; see $TUNNEL_LOG" >&2
exit 1
