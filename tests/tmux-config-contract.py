#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
text = (root / "dotfiles/tmux/tmux.conf").read_text()
required = [
    "unbind C-b",
    "set -g prefix C-s",
    "bind C-s send-prefix",
    "bind h split-window -h -c '#{pane_current_path}'",
    "bind v split-window -v -c '#{pane_current_path}'",
    "bind r source-file ~/.tmux.conf",
]
missing = [line for line in required if line not in text]
if missing:
    raise SystemExit(f"tmux Ctrl-s contract is missing: {missing}")
print("tmux Ctrl-s configuration contract passed.")
