#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRIVATE_ROOT="${DOTFILES_PRIVATE_ROOT:-$HOME/Developer/dotfiles-private}"
mode="${1:---dry-run}"
case "$mode" in
  --dry-run|--apply) ;;
  *) echo "usage: $0 [--dry-run|--apply]" >&2; exit 2 ;;
esac

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_root="${DOTFILES_BACKUP_DIR:-$HOME/Developer/dotfiles-backups/$timestamp}"
plan="$(mktemp)"
trap 'rm -f "$plan"' EXIT

python3 - "$ROOT/mise.toml" "$PRIVATE_ROOT/mise.toml" >"$plan" <<'PY'
from pathlib import Path
import json
import os
import sys
import tomllib

home = Path.home()
seen: set[Path] = set()
for config_path in map(Path, sys.argv[1:]):
    with config_path.open("rb") as handle:
        config = tomllib.load(handle)
    for target_text, value in config.get("dotfiles", {}).items():
        value = value if isinstance(value, dict) else {"source": value}
        target = Path(os.path.expanduser(target_text))
        source = Path(os.path.expanduser(value.get("source", target_text)))
        mode = value.get("mode", "symlink")
        targets = [target]
        if mode == "symlink-each" and source.is_dir():
            targets = [target / path.relative_to(source) for path in source.rglob("*") if path.is_file()]
        for item in targets:
            try:
                item.relative_to(home)
            except ValueError as exc:
                raise SystemExit(f"refusing target outside HOME: {item}") from exc
            if item in seen:
                continue
            seen.add(item)
            print(json.dumps({"target": str(item), "mode": mode}))
PY

count=0
while IFS= read -r entry; do
  target="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["target"])' "$entry")"
  [[ -e "$target" || -L "$target" ]] || continue
  relative="${target#"$HOME"/}"
  destination="$backup_root/home/$relative"
  count=$((count + 1))
  if [[ "$mode" == "--dry-run" ]]; then
    printf 'would back up: ~/%s\n' "$relative"
    continue
  fi
  mkdir -p "$(dirname "$destination")"
  if [[ -L "$target" ]]; then
    cp -a "$target" "$destination"
  else
    ditto "$target" "$destination"
  fi
done <"$plan"

if [[ "$mode" == "--dry-run" ]]; then
  echo "Dry run: $count existing managed target(s) would be backed up."
  exit 0
fi

chmod -R go-rwx "$backup_root"
cp "$plan" "$backup_root/managed-targets.jsonl"
chmod 600 "$backup_root/managed-targets.jsonl"
printf 'Backup complete: %s target(s) copied to %s\n' "$count" "$backup_root"
