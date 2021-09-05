#!/usr/bin/env bash

# Theme configuration
SLOTH_THEME_MINIMAL=${SLOTH_THEME_MINIMAL:-false}
SLOTH_THEME_MULTILINE=${SLOTH_THEME_MULTILINE:-false}
SLOTH_THEME_SHOW_UNTRACKED=${SLOTH_THEME_SHOW_BEHIND:-true}
SLOTH_THEME_SHOW_BEHIND=${SLOTH_THEME_SHOW_BEHIND:-true}
SLOTH_USE_RIGHT_PROMPT=${SLOTH_USE_RIGHT_PROMPT:-true} # Only used when no minimal theme is set

# Internal variables
GREEN_COLOR="32"
RED_COLOR="31"
YELLOW_COLOR="33"

PROMPT_COMMAND="sloth_theme"

# Theme implementation
prompt_git_command() {
  GIT_EXECUTABLE="${GIT_EXECUTABLE:-$(command -vp git || true)}"
  "$GIT_EXECUTABLE" "$@"
}

prompt_sloth_autoupdate() {
  if [[ -f "$DOTFILES_PATH/.sloth_update_available" ]]; then
    printf "📥  | "
  fi
}

prompt_sloth_git_info_has_unpushed_commits() {
  local -r branch="${1:-}"
  [[ -z "$branch" ]] && return 1
  local -r upstream_branch="$(prompt_git_command config --get "branch.${branch}.merge" || echo -n)"
  if [[ -n "$upstream_branch" ]]; then
    # @{u} or @{upstream} can be used but to keep compatibility with older git versions I use this way
    [[ $(prompt_git_command rev-list --count "${upstream_branch}..HEAD") -gt 0 ]]
  fi
}

prompt_sloth_git_info_has_untracked_files() {
  [[ $(prompt_git_command ls-files --exclude-standard --others --directory | wc -l) -gt 0 ]]
}

prompt_sloth_git_info_is_clean_repository() {
  prompt_git_command diff-index --no-ext-diff --quiet --exit-code --ignore-submodules="all" HEAD --
}

prompt_sloth_git_info_is_behind() {
  local -r branch="${1:-}"
  [[ -z "$branch" ]] && return 1
  local -r upstream_branch="$(prompt_git_command config --get "branch.${branch}.merge" || echo -n)"
  if [[ -n "$upstream_branch" ]]; then
    # @{u} or @{upstream} can be used but to keep compatibility with older git versions I use this way
    [[ $(prompt_git_command rev-list --count "HEAD..${upstream_branch}") -gt 0 ]]
  fi
}

prompt_sloth_git_info() {
  local clean_prompt untracked_prompt behind_prompt branch_prompt
  [[ ! -x "$GIT_EXECUTABLE" ]] && return
  ! "$GIT_EXECUTABLE" rev-parse --is-inside-work-tree &> /dev/null && return
  local -r branch="$("$GIT_EXECUTABLE" branch --show-current --no-color 2> /dev/null || true)"
  [[ -z "$branch" ]] && return

  # Unpushed commits show branch on yellow
  if prompt_sloth_git_info_has_unpushed_commits "$branch"; then
    branch_prompt="\e[${YELLOW_COLOR}m${branch}\e[m"
  else
    branch_prompt="\e[${GREEN_COLOR}m${branch}\e[m"
  fi

  if ! ${SLOTH_THEME_SHOW_BEHIND:-true} && prompt_sloth_git_info_is_behind "$branch"; then
    behind_prompt="\e[${RED_COLOR}m⬇︎\e[m"
  fi

  # Untracked files in the repository shows yellow U
  if ! ${SLOTH_THEME_SHOW_UNTRACKED:-true} && prompt_sloth_git_info_has_untracked_files; then
    untracked_prompt="\e[${YELLOW_COLOR}mU\e[m"
  fi

  # Dirty git dir shows green check or red cross
  if prompt_sloth_git_info_is_clean_repository; then
    clean_prompt="\e[${GREEN_COLOR}m✓\e[m"
  else
    clean_prompt="\e[${RED_COLOR}m✗\e[m"
  fi

  # Depending on configuration set the git prompt
  if ! ${SLOTH_THEME_MULTILINE:-false} && ! ${SLOTH_THEME_MINIMAL:-false} && ${SLOTH_USE_RIGHT_PROMPT:-true}; then
    echo -ne "${clean_prompt:-} (${branch_prompt:-}${untracked_prompt:+:$untracked_prompt}${behind_prompt:+[$behind_prompt]})"
  else
    echo -ne "on (${branch_prompt:-}${untracked_prompt:+:$untracked_prompt}${behind_prompt:+[$behind_prompt]})${clean_prompt:+ $clean_prompt}"
  fi
}

sloth_theme() {
  local current_dir STATUS_COLOR="$GREEN_COLOR" LAST_CODE="$?"
  current_dir=$(dot core short_pwd)

  if [[ $LAST_CODE -ne 0 ]]; then
    STATUS_COLOR="$RED_COLOR"
  fi

  PS1="(\[\e[${STATUS_COLOR}m\]⦿\[\e[m\] ω \[\e[${STATUS_COLOR}m\]⦿\[\e[m\]) \[\e[33m\]${current_dir}\[\e[m\]"

  if ${SLOTH_THEME_MULTILINE:-false}; then
    if ! ${SLOTH_THEME_MINIMAL:-false}; then
      PS1="${PS1} \[\$(prompt_sloth_git_info)\]"
    fi

    if [[ $LAST_CODE -eq 0 ]]; then
      PS1="\n${PS1}\n   ︶   ⎣ ☞ "
    else
      PS1="\n${PS1}\n   －   ⎣ ☞ "
    fi

  else
    if ! ${SLOTH_THEME_MINIMAL:-false} && ! ${SLOTH_USE_RIGHT_PROMPT:-false}; then
      RPS1="$(prompt_sloth_git_info)"
    elif ! ${SLOTH_THEME_MINIMAL:-false}; then
      PS1="${PS1} \[\$(prompt_sloth_git_info)\]"
    fi

    PS1+=" "
  fi
  export PS1 RPS1
}
