# Cutover checklist

Nothing in this checklist is automatic. Stop after each phase and verify before
continuing.

## 1. Repository review

- Validate both repositories and Pi Harness.
- Review uncommitted files and create local commits.
- Confirm both repositories still have no unintended remotes.
- Confirm Pi Harness public templates contain no private endpoint.

## 2. Backup

`mise run backup:dry-run` currently identifies the exact existing targets that
would be replaced. After approval, run `mise run backup:apply`. Backups are
created under `~/Developer/dotfiles-backups/`, outside both repositories, with
owner-only permissions. The script copies only declared managed targets; it
never copies auth stores, `.env`, sessions, histories, SSH keys, or AWS
credentials.

## 3. Install replacements without removing legacy tools

- Run the locked mise tool installation and verify versions.
- Install PostgreSQL 18 without starting it.
- Decide whether Homebrew should adopt the existing unmanaged VS Code app.
- Do not remove NVM, Conda, PostgreSQL 14, Solana, or other legacy paths yet.

## 4. Apply public dotfiles

Use mise's forced dotfile replacement only after the backup is verified. Test a
new login shell before closing the current terminal. Confirm Herdr and tmux
retain their complete `Ctrl-s` contracts.

## 5. Apply Pi and private overlays

Run Pi Harness with host Pi, global helper, shell mutation, model replacement,
and sandbox installation disabled. Then apply the private overlay, which owns
Git identity, SSH mappings, Keychain helper functions, AI-tool configuration,
AWS profile metadata, and the private Pi model provider.

## 6. Verify before cleanup

- Shell and project-local mise activation
- Node, Python/uv, Rust, Java/Maven, and selected CLIs
- Generic SSH aliases and GitHub credential helper
- Neovim, VS Code, Ghostty, Herdr, and tmux
- Independent Pi, Claude, Codex, and OpenCode instructions
- PostgreSQL 14 data remains intact and PostgreSQL 18 is not running unless
  deliberately started

Legacy cleanup is a separate approval after these checks pass.
