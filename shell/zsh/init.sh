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
if ! ${SLOTH_DISABLE_ZIMFW:-false} && [[ -n "${ZIM_HOME:-}" && -d "${ZIM_HOME:-}" && -r "${ZIM_HOME}/init.zsh" ]]; then
  [[ -z "${ZSH_HIGHLIGHT_HIGHLIGHTERS:-}" ]] && ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
  
  #shellcheck disable=SC1091
  . "${ZIM_HOME}/init.zsh" || echo "Error loading ZimFW"
  { [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Loaded ZimFW"; } || true
fi

# Async mode for autocompletion
# shellcheck disable=SC2034
[[ -z "${ZSH_AUTOSUGGEST_USE_ASYNC:-}" ]] && ZSH_AUTOSUGGEST_USE_ASYNC=true
# shellcheck disable=SC2034
[[ -z "${ZSH_HIGHLIGHT_MAXLENGTH:-}" ]] && ZSH_HIGHLIGHT_MAXLENGTH=300

tmp_fpath=("${fpath[@]}")
fpath=()
if [[ -n "${DOTFILES_PATH:-}" && -d "$DOTFILES_PATH" ]]; then
  fpath+=("${DOTFILES_PATH}/shell/zsh/themes")
  fpath+=("${DOTFILES_PATH}/shell/zsh/completions")
fi

fpath+=("${SLOTH_PATH}/shell/zsh/themes")
fpath+=("${SLOTH_PATH}/shell/zsh/completions")
fpath+=("${tmp_fpath[@]}")

# Brew ZSH Completions
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  fpath+=(
    "${HOMEBREW_PREFIX}/share/zsh-completions"
    "${HOMEBREW_PREFIX}/share/zsh/site-functions"
  )
fi

autoload -Uz promptinit && promptinit
prompt "${SLOTH_ZSH_THEME:-${SLOTH_THEME:-${DOTLY_THEME:-codely}}}"

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

unset tmp_fpath
