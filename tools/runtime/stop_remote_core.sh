#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GARAGE_DIR="$REPO_ROOT/garbage"
mkdir -p "$GARAGE_DIR"

for FILE in ".core_tunnel.pid" ".core_domain_tunnel.pid" ".mobileapi.pid"; do
	if [ -f "$GARAGE_DIR/$FILE" ]; then
		PID="$(cat "$GARAGE_DIR/$FILE" 2>/dev/null || true)"
		if [ -n "${PID:-}" ]; then
			kill "$PID" 2>/dev/null || true
		fi
		rm -f "$GARAGE_DIR/$FILE"
	fi
done

rm -f "$GARAGE_DIR/.core_tunnel_url" "$GARAGE_DIR/.core_domain_url" "$GARAGE_DIR/.core_domain_tunnel.yml"
