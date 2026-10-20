#!/usr/bin/env bash
# Expose Bazelisk's conventional bazel entry point inside the mise-owned prefix.
set -euo pipefail
runtime="${1:?usage: setup-bazelisk.sh <mise-bazelisk-install-path>}"
if [[ ! -x "$runtime/bazelisk" ]]; then
	echo "Bazelisk executable missing from the supplied install prefix" >&2
	exit 1
fi
if [[ -L "$runtime/bazel" ]] && [[ "$(readlink "$runtime/bazel")" == bazelisk ]]; then
	exit 0
fi
if [[ -e "$runtime/bazel" || -L "$runtime/bazel" ]]; then
	echo "Refusing to replace an unexpected bazel entry point" >&2
	exit 1
fi
ln -s bazelisk "$runtime/bazel"
