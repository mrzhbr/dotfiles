#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

scan="$(mktemp -d)"
trap 'rm -rf "$scan"' EXIT

python3 - "$ROOT" "$scan" <<'PY'
from pathlib import Path
import re
import shutil
import subprocess
import sys

root = Path(sys.argv[1]).resolve()
if not root.is_dir():
    raise SystemExit(f"not a directory: {root}")

forbidden_names = {
    ".env", "auth.json", "credentials.json", "known_hosts",
    "id_rsa", "id_ed25519", "id_ecdsa", "id_dsa",
}
forbidden_parts = {"sessions", "history", "histories", "cache", "caches"}
forbidden_suffixes = {".log", ".sock", ".db", ".sqlite", ".sqlite3", ".pem", ".key"}
private_aliases = ["pot" + "sdam", "frank" + "enthal"]
home_path = re.compile(r"/Users/[A-Za-z0-9._-]+")
tailnet_ip = re.compile(r"\b100\.(?:6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])(?:\.\d{1,3}){2}\b")
email = re.compile(r"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", re.I)
secret_key = re.compile(
    r"(?:api[_-]?key|secret|token|password|credential|private[_-]?key|bearer)\s*[:=]\s*([^\s,}\]]+)",
    re.I,
)
allowed_value = re.compile(r"^(?:[\"']?\$\{|[\"']?\$[A-Z_]|[\"']?<[^>]+>|[\"']?(?:none|not-needed|keychain)[\"']?$)", re.I)

# These exact generated roots are never public source. Reject tracked files
# there before skipping their content; arbitrary gitignore entries are NOT used.
generated = (Path(".pi/subagents"), Path(".ruff_cache"))
tracked = subprocess.run(
    ["git", "-C", str(root), "ls-files", "-z", "--", *(str(path) for path in generated)],
    capture_output=True, check=False,
)
errors: list[str] = []
if tracked.returncode == 0:
    for name in tracked.stdout.decode().split("\0"):
        if name:
            errors.append(f"generated artifact must not be tracked: {name}")
elif (root / ".git").exists():
    raise SystemExit("cannot check tracked generated artifacts")
if errors:
    raise SystemExit("Safety check failed:\n  - " + "\n  - ".join(sorted(set(errors))))

export = Path(sys.argv[2])
for path in root.rglob("*"):
    rel = path.relative_to(root)
    if rel.parts[0] == ".git" or any(rel.is_relative_to(prefix) for prefix in generated):
        continue
    lower_parts = {part.lower() for part in rel.parts}
    if path.is_file():
        lower_name = path.name.lower()
        if (
            lower_name in forbidden_names
            or (lower_name.startswith(".env.") and lower_name != ".env.example")
            or path.suffix.lower() in forbidden_suffixes
            or forbidden_parts.intersection(lower_parts)
        ):
            errors.append(f"forbidden tracked path: {rel}")
            continue
        # Gitleaks receives this same reviewed source set, including untracked
        # source and ignored files outside the two explicit generated roots.
        target = export / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target, follow_symlinks=False)
        if rel.as_posix() == "scripts/check-safety.sh":
            continue
        try:
            raw = path.read_bytes()
        except OSError as exc:
            errors.append(f"cannot read {rel}: {exc}")
            continue
        if b"\0" in raw:
            continue
        text = raw.decode("utf-8", errors="replace")
        if home_path.search(text):
            errors.append(f"absolute macOS home path in {rel}")
        if tailnet_ip.search(text):
            errors.append(f"private tailnet address in {rel}")
        lowered = text.lower()
        if any(alias in lowered for alias in private_aliases):
            errors.append(f"private host alias in {rel}")
        for match in email.finditer(text):
            candidate = match.group(0).lower()
            if candidate == "git@github.com" or candidate.endswith("@example.com"):
                continue
            errors.append(f"email/account identifier in {rel}")
            break
        for match in secret_key.finditer(text):
            if not allowed_value.search(match.group(1)):
                errors.append(f"literal secret-shaped assignment in {rel}")
                break

if errors:
    print("Safety check failed:", file=sys.stderr)
    for error in sorted(set(errors)):
        print(f"  - {error}", file=sys.stderr)
    raise SystemExit(1)
print(f"Safety path/content checks passed: {root}")
PY

if command -v gitleaks >/dev/null 2>&1; then
  gitleaks dir --no-banner --redact "$scan"
  echo "Gitleaks scan passed."
else
  echo "warning: gitleaks is unavailable; built-in safety checks passed." >&2
fi
