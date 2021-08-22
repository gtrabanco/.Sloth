#!/usr/bin/env zsh
#shellcheck disable=SC2148
reverse-search() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail HIST_FIND_NO_DUPS 2> /dev/null

  #shellcheck disable=SC2207
  selected=( $(fc -rl 1 |
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" fzf) )
  local ret=$?
  if [ -n "${selected[*]:-}" ]; then
    num=${selected[1]}
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}

# ZSH Ops
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FCNTL_LOCK
setopt +o nomatch
# setopt autopushd

# Start zim
if [[ -n "${ZIM_HOME:-}" && -d "${ZIM_HOME:-}" && -r "${ZIM_HOME}/init.zsh" ]]; then
  #shellcheck disable=SC1091
  . "${ZIM_HOME}/init.zsh"
fi

# Async mode for autocompletion
# shellcheck disable=SC2034
ZSH_AUTOSUGGEST_USE_ASYNC=true
# shellcheck disable=SC2034
ZSH_HIGHLIGHT_MAXLENGTH=300

fpath=()
if [[ -n "${DOTFILES_PATH:-}" && -d "$DOTFILES_PATH" ]]; then
  fpath+=(
    "${DOTFILES_PATH}/shell/zsh/themes"
    "${DOTFILES_PATH}/shell/zsh/autocompletions"
  )
fi

fpath+=(
  "${SLOTH_PATH}/shell/zsh/themes"
  "${SLOTH_PATH}/shell/zsh/completions"
  "${fpath[@]}"
)

# Brew ZSH Completions
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  fpath+=("${HOMEBREW_PREFIX}/share/zsh-completions")
  fpath+=("${HOMEBREW_PREFIX}/share/zsh/site-functions")
fi

autoload -Uz promptinit && promptinit
prompt "${SLOTH_THEME:-${DOTLY_THEME:-codely}}"

if
  [[
    -r "${SLOTH_PATH}/shell/zsh/bindings/dot.zsh" &&
    -r "${SLOTH_PATH}/shell/zsh/bindings/reverse_search.zsh"
  ]]
then
  . "${SLOTH_PATH}/shell/zsh/bindings/dot.zsh"
  . "${SLOTH_PATH}/shell/zsh/bindings/reverse_search.zsh"
fi

if [[ -r "${DOTFILES_PATH}/shell/zsh/key-bindings.zsh" ]]; then
  . "${DOTFILES_PATH}/shell/zsh/key-bindings.zsh"
fi
