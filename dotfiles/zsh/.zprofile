# Login-shell paths. Interactive environment switching happens in .zshrc.
typeset -U path PATH
path=(
  "$HOME/.local/share/mise/shims"
  "$HOME/.local/bin"
  /opt/homebrew/opt/postgresql@18/bin
  /opt/homebrew/bin
  /opt/homebrew/sbin
  $path
)
export PATH

[[ -d /opt/homebrew/share/man ]] && export MANPATH="/opt/homebrew/share/man:${MANPATH:-}"
[[ -d /opt/homebrew/share/info ]] && export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
