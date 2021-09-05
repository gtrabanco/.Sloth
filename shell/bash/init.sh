#!/usr/bin/env bash
# Rigth prompt for bash definition
__right_prompt() {
  local LAST_CODE="$?"
  return_code() {
    return "${1:-0}"
  }

  RIGHT_PROMPT=""
  [[ -n $RPS1 ]] && RIGHT_PROMPT=$RPS1 || RIGHT_PROMPT=$RPROMPT
  if [[ -n $RIGHT_PROMPT ]]; then
    n=$((COLUMNS - ${#RIGHT_PROMPT} + (${#RIGHT_PROMPT} / 3)))
    printf "%${n}s$RIGHT_PROMPT\\r"
  fi

  if [[ -n "${THEME_COMMAND:-}" ]] && declare -F "$THEME_COMMAND" &> /dev/null; then
    return_code "$LAST_CODE"
    "$THEME_COMMAND"
  fi
}

PATH=$(
  IFS=":"
  echo "${path[*]:-}"
)
export PATH

themes_paths=()
if [[ -n "${DOTFILES_PATH:-}" && -d "$DOTFILES_PATH/shell/bash/themes" ]]; then
  themes_paths+=(
    "$DOTFILES_PATH/shell/bash/themes"
  )
fi
themes_paths+=(
  "${SLOTH_PATH:-${DOTLY_PATH:-}}/shell/bash/themes"
)

# brew Bash completion & completions
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
    #shellcheck source=/dev/null
    . "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
  else
    for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
      #shellcheck source=/dev/null
      [[ -r "$COMPLETION" ]] && . "$COMPLETION"
    done
    unset COMPLETION
  fi
fi

#shellcheck disable=SC2068
for THEME_PATH in ${themes_paths[@]}; do
  THEME_PATH="${THEME_PATH}/${SLOTH_THEME:-${DOTLY_THEME:-codely}}.sh"
  THEME_COMMAND=""
  #shellcheck source=/dev/null
  [ -f "$THEME_PATH" ] && . "$THEME_PATH" && THEME_COMMAND="${PROMPT_COMMAND:-}" && break
done
# Now we know which theme we should use, so define right prompt
PROMPT_COMMAND="__right_prompt"
export THEME_COMMAND PROMPT_COMMAND

for completion in $(find "${SLOTH_PATH:-${DOTLY_PATH:-}}/shell/bash/completions/" "${DOTFILES_PATH:-/dev/null}/shell/bash/completions/" -name "_*" -print0 -exec echo {} \; 2> /dev/null | xargs -0 -I _ echo _); do
  [[ -z "$completion" ]] && continue
  #shellcheck source=/dev/null
  . "$completion" || echo -e "\033[0;31mBASH completion '$completion' could not be loaded\033[0m"
done
unset completion THEME_PATH
