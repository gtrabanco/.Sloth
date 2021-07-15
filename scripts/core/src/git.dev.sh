#!/usr/bin/env bash

#;
# git::git()
# Abstraction function to use with GIT
#"
git::git() {
  local git_bin
  if [[ -n "$SLOTH_USE_GIT_BIN" ]]; then
    git_bin="$SLOTH_USE_GIT_BIN"
  elif command -v git 2>/dev/null; then
    git_bin="$(command -v )"
}

git rev-list HEAD...origin/HEAD --count

git::is_in_repo() {
  git "$@" rev-parse HEAD > /dev/null 2>&1
}

# shellcheck disable=SC2120
git::current_branch() {
  git "$@" branch --show-current
}
