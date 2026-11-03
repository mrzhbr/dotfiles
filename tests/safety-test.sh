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

# Personal identifiers are supplied from private metadata, not hard-coded here.
printf 'example-denied-host\n' >"$tmp/private-identifiers.txt"
"$CHECK" --denylist "$tmp/private-identifiers.txt" "$tmp/good" >/dev/null
mkdir -p "$tmp/bad-identifier"
printf 'Example-Denied-Host\n' >"$tmp/bad-identifier/config.txt"
if "$CHECK" --denylist "$tmp/private-identifiers.txt" "$tmp/bad-identifier" >"$tmp/identifier-output" 2>&1; then
  echo "expected a configured private identifier to fail" >&2
  exit 1
fi
grep -q 'private identifier in config.txt' "$tmp/identifier-output"
if grep -qi 'example-denied-host' "$tmp/identifier-output"; then
  echo "private identifier values must not be printed in diagnostics" >&2
  exit 1
fi
: >"$tmp/empty-identifiers.txt"
ln -s "$tmp/private-identifiers.txt" "$tmp/linked-identifiers.txt"
for invalid in missing-identifiers.txt empty-identifiers.txt linked-identifiers.txt; do
  if "$CHECK" --denylist "$tmp/$invalid" "$tmp/good" >/dev/null 2>&1; then
    echo "expected a missing, empty or symlink denylist to fail" >&2
    exit 1
  fi
done
if "$CHECK" --denylist >/dev/null 2>&1; then
  echo "expected a missing denylist argument to fail" >&2
  exit 1
fi

# Generated artifacts may contain private runtime context. Neither scanner may
# read them, but tracked artifacts must fail even when force-added past ignores.
fixture="$tmp/generated"
mkdir -p "$fixture/.pi/subagents" "$fixture/.ruff_cache"
printf '.pi/subagents/\n.ruff_cache/\n.env\n' >"$fixture/.gitignore"
printf '/%s/%s/private\n' 'Users' 'someone' >"$fixture/.pi/subagents/transcript.jsonl"
printf 'runtime cache\n' >"$fixture/.ruff_cache/tool.log"
git -C "$fixture" init --quiet
"$CHECK" "$fixture" >/dev/null

# An ignored but untracked forbidden file outside generated roots still fails.
printf 'placeholder\n' >"$fixture/.env"
if "$CHECK" "$fixture" >/dev/null 2>&1; then
  echo "expected an ignored untracked .env to fail" >&2
  exit 1
fi
rm "$fixture/.env"

# The exception is not the entire .pi directory.
printf '/%s/%s/private\n' 'Users' 'someone' >"$fixture/.pi/source.txt"
if "$CHECK" "$fixture" >/dev/null 2>&1; then
  echo "expected non-generated .pi source to be scanned" >&2
  exit 1
fi
rm "$fixture/.pi/source.txt"

# Staging happens only in disposable fixture repositories, never this checkout.
for generated in .pi/subagents .ruff_cache; do
  tracked="$tmp/tracked-${generated//\//-}"
  mkdir -p "$tracked/$generated"
  git -C "$tracked" init --quiet
  printf '%s/\n' "$generated" >"$tracked/.gitignore"
  printf 'ordinary generated data\n' >"$tracked/$generated/artifact.txt"
  git -C "$tracked" add --force "$generated/artifact.txt"
  if "$CHECK" "$tracked" >"$tmp/scan-output" 2>&1; then
    echo "expected force-tracked $generated to fail" >&2
    exit 1
  fi
  grep -q 'generated artifact must not be tracked' "$tmp/scan-output"
done

echo "Safety fixture tests passed (including private identifiers, generated roots and untracked files)."
