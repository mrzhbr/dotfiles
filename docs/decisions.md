# Decisions

- Use mise as the primary bootstrap, dotfile, task, and developer-tool manager.
- Keep a public-safe baseline and a separate private, non-secret overlay.
- Keep Pi Harness as an independent repository.
- Standardize Python on mise plus uv; Conda is not part of the baseline.
- Replace NVM with mise while preserving Node 23.3.0 for the migration.
- Use Temurin Java 25 LTS globally; projects may pin Java 17.
- Keep Rust and Java/Maven; omit R/RStudio and Solana/Anchor.
- Manage Neovim and VS Code only.
- Install Pi, Claude Code, Codex, and OpenCode; keep their instructions independent.
- Preserve Herdr's existing `Ctrl-s` configuration byte-for-byte and keep tmux
  during the Herdr evaluation period.
- Use generic public remote aliases; real mappings belong in the private layer.
- Install PostgreSQL 18 on new machines without auto-starting it. Existing
  PostgreSQL 14 data migration is separate and manual.
- Keep Docker Desktop and Ollama on-demand; omit Spotifyd.
- Retain Homebrew only as the native package/cask layer under mise bootstrap.
- Never store raw secrets in either repository, including the private one.
