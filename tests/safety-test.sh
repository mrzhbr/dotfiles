#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="$ROOT/scripts/check-safety.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/good"
# shellcheck disable=SC2016 # keep the environment reference literal in the fixture
printf 'service_key = "${SERVICE_KEY}"\n' >"$tmp/good/config.toml"
"$CHECK" "$tmp/good" >/dev/null

mkdir -p "$tmp/bad-file"
printf 'placeholder\n' >"$tmp/bad-file/.env"
if "$CHECK" "$tmp/bad-file" >/dev/null 2>&1; then
  echo "expected a tracked .env file to fail" >&2
  exit 1
fi

mkdir -p "$tmp/bad-path"
printf '/%s/%s/private\n' 'Users' 'someone' >"$tmp/bad-path/config.txt"
if "$CHECK" "$tmp/bad-path" >/dev/null 2>&1; then
  echo "expected an absolute home path to fail" >&2
  exit 1
fi

echo "Safety fixture tests passed."
