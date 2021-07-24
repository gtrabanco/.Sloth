#!/usr/bin/env bash
PROMPT_COMMAND="sloth_theme"

GREEN_COLOR="32"
RED_COLOR="31"
YELLOW_COLOR="33"

GIT_EXECUTABLE="${GIT_EXECUTABLE:-$(command -vp git || true)}"

# SLOTH_THEME_MINIMAL
# SLOTH_THEME_MULTILINE
# SLOTH_THEME_NOT_SHOW_UNTRACKED

prompt_sloth_autoupdate() {
  if [[ -f "$DOTFILES_PATH/.sloth_update_available" ]]; then
    printf "📥  | "
  fi
}

prompt_sloth_git_info_has_unpushed_commits() {
  local -r branch="${1:-}"
  [[ -z "$branch" ]] && return 1
  local -r upstream_branch="$("${GIT_EXECUTABLE}" config --get "branch.${branch}.merge" || echo -n)"
  if [[ -n "$upstream_branch" ]]; then
    # @{u} or @{upstream} can be used but to keep compatibility with older git versions I use this way
    [[ $("${GIT_EXECUTABLE}" rev-list --count "${upstream_branch}..HEAD") -gt 0 ]]
    [[ $("${GIT_EXECUTABLE}" rev-list --count "@{u}..HEAD") -gt 0 ]]
  fi
}

prompt_sloth_git_info_has_untracked_files() {
  [[ $("${GIT_EXECUTABLE}" ls-files --exclude-standard --others --directory | wc -l) -gt 0 ]]
}

prompt_sloth_git_info_is_clean_repository() {
  "${GIT_EXECUTABLE}" diff-index --no-ext-diff --quiet --exit-code --ignore-submodules="all" HEAD --
}

prompt_sloth_git_info_is_behind() {
  local -r branch="${1:-}"
  [[ -z "$branch" ]] && return 1
  local -r upstream_branch="$("${GIT_EXECUTABLE}" config --get "branch.${branch}.merge" || echo -n)"
  if [[ -n "$upstream_branch" ]]; then
    # @{u} or @{upstream} can be used but to keep compatibility with older git versions I use this way
    [[ $("${GIT_EXECUTABLE}" rev-list --count "HEAD..${upstream_branch}") -gt 0 ]]
  fi
}

prompt_sloth_git_info() {
  local prompt_output=""
  [[ ! -x "$GIT_EXECUTABLE" ]] && return
  ! "$GIT_EXECUTABLE" rev-parse --is-inside-work-tree &> /dev/null && return
  local -r branch="$("$GIT_EXECUTABLE" branch --show-current --no-color 2> /dev/null || true)"
  [[ -z "$branch" ]] && return

  # Unpushed commits show branch on yellow
  if prompt_sloth_git_info_has_unpushed_commits "$branch"; then
    prompt_output="on (\e[${YELLOW_COLOR}m${branch}\e[m)"
  else
    prompt_output="on (\e[${GREEN_COLOR}m${branch}\e[m)"
  fi

  if ! ${SLOTH_THEME_NOT_SHOW_BEHIND:-false} && prompt_sloth_git_info_is_behind "$branch"; then
    prompt_output="${prompt_output} \e[${RED_COLOR}m(☜)\e[m"
  fi

  # Untracked files in the repository shows yellow U
  if ! ${SLOTH_THEME_NOT_SHOW_UNTRACKED:-false} && prompt_sloth_git_info_has_untracked_files; then
    prompt_output="${prompt_output} (\e[${YELLOW_COLOR}mU\e[m)"
  fi

  # Dirty git dir shows green check or red cross
  if prompt_sloth_git_info_is_clean_repository; then
    prompt_output="${prompt_output} \e[${GREEN_COLOR}m✓\e[m"
  else
    prompt_output="${prompt_output} \e[${RED_COLOR}m✗\e[m"
  fi

  echo -ne "$prompt_output"
}

sloth_theme() {
  LAST_CODE="$?"
  current_dir=$(dot core short_pwd)
  STATUS_COLOR=$GREEN_COLOR

  if [ $LAST_CODE -ne 0 ]; then
    STATUS_COLOR=$RED_COLOR
  fi

  if ${SLOTH_THEME_MINIMAL:-false}; then
    PS1="(\[\e[${STATUS_COLOR}m\]⦿\[\e[m\] ω \[\e[${STATUS_COLOR}m\]⦿\[\e[m\])"
  else
    PS1="(\[\e[${STATUS_COLOR}m\]⦿\[\e[m\] ω \[\e[${STATUS_COLOR}m\]⦿\[\e[m\]) \[\e[33m\]${current_dir}\[\e[m\] \$(prompt_sloth_git_info)"
  fi

  if ${SLOTH_THEME_MULTILINE:-}; then
    PS1="$PS1 "
  else
    PS1="⎡$PS1\n⎣ ☞"
  fi
  export PS1
}
