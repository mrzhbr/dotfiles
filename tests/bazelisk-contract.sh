#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
runtime="$TMP/runtime with spaces"
mkdir -p "$runtime"
printf '#!/bin/sh\nprintf "argument=<%%s>\\n" "$@"\n' >"$runtime/bazelisk"
chmod +x "$runtime/bazelisk"
bash "$ROOT/scripts/setup-bazelisk.sh" "$runtime"
[[ "$(readlink "$runtime/bazel")" == bazelisk ]]
[[ "$("$runtime/bazel" 'two words')" == 'argument=<two words>' ]]
bash "$ROOT/scripts/setup-bazelisk.sh" "$runtime"
rm "$runtime/bazel"
printf 'keep me\n' >"$runtime/bazel"
if bash "$ROOT/scripts/setup-bazelisk.sh" "$runtime" 2>/dev/null; then
	echo 'Unexpected file was overwritten' >&2
	exit 1
fi
[[ "$(<"$runtime/bazel")" == 'keep me' ]]
rm "$runtime/bazel"
ln -s missing "$runtime/bazel"
if bash "$ROOT/scripts/setup-bazelisk.sh" "$runtime" 2>/dev/null; then
	echo 'Unexpected dangling symlink was overwritten' >&2
	exit 1
fi
[[ "$(readlink "$runtime/bazel")" == missing ]]
if bash "$ROOT/scripts/setup-bazelisk.sh" "$TMP/absent" 2>/dev/null; then
	echo 'Missing runtime was accepted' >&2
	exit 1
fi
printf 'Bazelisk alias contract passed.\n'
