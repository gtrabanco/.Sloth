#!/usr/bin/env bash
#shellcheck disable=SC2034

#
#  - You can force the usage of specific git binary by defining GIT_EXECUTABLE.
#  - Also can pass git args forcely to all these git command by passing an array
#  of args with the array variable ALWAYS_USE_GIT_ARGS.
#

if
  [[ -z "${GIT_EXECUTABLE:-}" ]] ||
  [[
    -n "${GIT_EXECUTABLE:-}"  &&
    ! -x "$GIT_EXECUTABLE"
  ]] && command -v git &> /dev/null
then
  GIT_EXECUTABLE="$(command -v git)"

elif command -v git &> /dev/null; then
  GIT_EXECUTABLE="$(command -v git)"

elif
  [[ -z "${GIT_EXECUTABLE:-}" ]] ||
  [[
    -n "${GIT_EXECUTABLE:-}"  &&
    ! -x "$GIT_EXECUTABLE"
  ]]
then
  echoerr "No git binary found, please install it or review your env \`PATH\` variable or check if defined that \`GIT_EXECUTABLE\` has a right value" | log::file "Error trying to locate git command"
fi
export GIT_EXECUTABLE

#;
# git::git()
# Abstraction function to use with GIT
#"
git::git() {
  [[ ! -x "$GIT_EXECUTABLE" ]] && return 1

  if [[ -n "${ALWAYS_USE_GIT_ARGS[*]}" && ${#ALWAYS_USE_GIT_ARGS[@]} -gt 0 ]]; then
    "$GIT_EXECUTABLE" "${ALWAYS_USE_GIT_ARGS[@]}" "$@"
  else
    "$GIT_EXECUTABLE" "$@"
  fi
}

#;
# git::is_in_repo()
# check if a directory is a repository
#"
git::is_in_repo() {
  git::git "$@" rev-parse -q --verify HEAD &> /dev/null
}

#;
# git::current_branch()
# Get the current active branch
#"
git::current_branch() {
  git::git "$@" branch --show-current 2> /dev/null || return
}
