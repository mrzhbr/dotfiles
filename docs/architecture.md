# Architecture

## Repository composition

The public checkout lives at `~/Developer/dotfiles`. Its `mise.toml` is linked
to `~/.config/mise/conf.d/10-public.toml` when dotfiles are eventually applied.
A separate private checkout provides `90-private.toml`, so private additions
load after the public baseline.

The public layer contains no credentials, private addresses, personal host
aliases, account identifiers, histories, sessions, or generated application
state. Authentication remains in Keychain or each application's own login
store.

## Bootstrap layers

1. mise is installed or upgraded manually through Homebrew.
2. `mise bootstrap` installs native packages and casks.
3. An idempotent task clones the canonical Pi Harness repository only when it
   is missing; existing checkouts are never updated, reset, or cleaned.
4. It applies public dotfiles.
5. It installs mise-managed tools.
6. The idempotent bootstrap task prepares directories, installs VS Code
   extensions, and validates contracts.
7. The private repository is applied separately after authentication.

## Behavioral contracts

Herdr's complete current `Ctrl-s` keymap is release-blocking and tested.
tmux retains its `C-s` prefix while Herdr is evaluated. Pi, Claude Code, Codex,
and OpenCode keep independent instructions.

## Safety boundary

The public bootstrap never reads Keychain values, `.env` files, auth stores,
SSH keys, histories, or sessions. Destructive cleanup and PostgreSQL migration
are separate, explicitly approved operations.
