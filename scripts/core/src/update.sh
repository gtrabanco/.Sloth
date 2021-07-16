#!/usr/bin/env bash

# https://github.com/Homebrew/brew/blob/master/Library/Homebrew/cmd/update.sh

update::git_upstream_branch() {
  local upstream_branch

  upstream_branch="$(git::get_remote_head_upstream_branch "$@")"
  if [[ -z "${upstream_branch}" ]]; then
    git remote set-head origin --auto > /dev/null
    upstream_branch="$(git::get_remote_head_upstream_branch "$@")"
  fi
  upstream_branch="${upstream_branch#origin/}"
  [[ -z "${upstream_branch}" ]] && upstream_branch="master"
  echo "${upstream_branch}"
}
