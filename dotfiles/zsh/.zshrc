# Public interactive shell configuration. Private helpers belong in private.zsh.

# Fast completion initialization using the existing completion dump when valid.
autoload -Uz compinit
compinit -C

# mise owns runtime/tool activation and project-specific environments.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# Optional private overlay. This file is never part of the public repository.
[[ -r "$HOME/.config/zsh/private.zsh" ]] && source "$HOME/.config/zsh/private.zsh"
