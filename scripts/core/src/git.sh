#!/usr/bin/env bash

#
#  - You can force the usage of specific git binary by defining SLOTH_USE_GIT_BIN.
#  - Also can pass git args forcely to all these git command by passing an array
#  of args with the array variable SLOTH_ALWAYS_USE_GIT_ARGS.
#

if
  [[ -z "$SLOTH_USE_GIT_BIN" ]] ||
  [[ -n "$SLOTH_USE_GIT_BIN" ]] &&
  [[ ! -x "$SLOTH_USE_GIT_BIN" ]] &&
  command -v git &>/dev/null
then
  SLOTH_USE_GIT_BIN="$(command -v git)"
elif command -v git &>/dev/null; then
  SLOTH_USE_GIT_BIN="$(command -v git)"
else
  echoerr "No git binary found, please install it or review your env \`PATH\` variable or check if defined that \`SLOTH_USE_GIT_BIN\` has a right value" | log::file "Error trying to locate git command"
fi
export SLOTH_USE_GIT_BIN

#;
# git::git()
# Abstraction function to use with GIT
#"
git::git() {
  [[ ! -x "$SLOTH_USE_GIT_BIN" ]] && return 1

  if [[ -n "${SLOTH_ALWAYS_USE_GIT_ARGS[*]}" && ${#SLOTH_ALWAYS_USE_GIT_ARGS[@]} -gt 0 ]]; then
    "$SLOTH_USE_GIT_BIN" "${SLOTH_ALWAYS_USE_GIT_ARGS[@]}" "$@"
  else
    "$SLOTH_USE_GIT_BIN" "$@"
  fi
}

git::is_in_repo() {
  git::git "$@" rev-parse -q --verify HEAD &> /dev/null
}

git::current_branch() {
  git::git "$@" branch --show-current
}

git::current_commit_hash() {
  local -r branch="${1:-HEAD}"
  [[ -n "${1:-}" ]] && shift
  git::git "$@" rev-parse -q --verify "${branch}"
}

git::is_valid_commit() {
  local -r commit="${1:-HEAD}"
  [[ -n "${1:-}" ]] && shift

  git::is_in_repo "$@" && [[ $(git::git "$@" cat-file -t "$commit") == commit ]]
}

#;
# git::remote_branch_exists()
# Check if branch exists in remote
# @param string remote If only provide one param it will be the branch and takes the remote as origin
# @param string branch
# @param any args Additional arguments that will be passed to git
# @return boolean
#"
git::remote_branch_exists() {
  local remote_branch

  if [[ $# -gt 1 ]]; then
    remote="$1"
    branch="$2"
    shift 2
  elif [[ $# -eq 1 ]]; then
    branch="$1"
    remote="origin"
    shift
  else
    branch="master"
    remote="origin"
  fi

  [[ -n "$(git::git "$@" branch --remotes --list "${remote}/${branch}" 2>/dev/null)" ]]
}

#;
# git::count_different_commits_with_remote_branch()
# Count number of commits in difference with remote. It will count local against remote and vice-versa, which means that if you are one commit ahead it will show you 1 as if you were 1 commit behind.
# @param string local_branch HEAD by default
# @param string remote_branch HEAD by default
# @param string remote
# @param any args Additional args for git
# @return int
#"
git::count_different_commits_with_remote_branch() {
  local local_branch="${1:-HEAD}" remote_branch remote_name

  [[ -n "${1:-}" ]] && shift

  if [[ $# -gt 1 ]]; then
    remote_branch="$1"
    remote_name="$2"
    shift 2
  elif [[ $# -eq 1 ]]; then
    remote_branch="$1"
    remote_name="origin"
    shift
  else
    remote_branch="HEAD"
    remote_name="origin"
  fi

  ! git::remote_branch_exists "$@" "${remote_name}" "${local_branch}" && echo -n 0 && return
  git::git "$@" rev-list "${local_branch}...${remote_name}/${remote_branch}" --count 2>/dev/null
}

git::check_current_branch_is_behind() {
  # git status --ahead-behind | head -n2 | tail -n1 | awk '{NF--; print $4"\n"$NF}'
  [[ $(git status --ahead-behind 2>/dev/null | head -n2 | tail -n1 | awk '{print $4}') == "behind" ]]
}


git::get_remote_head_upstream_branch() {
  local remote="${1:-origin}"
  [[ -n "${1:-}" ]] && shift
  git::git "$@" symbolic-ref --short "refs/remotes/${remote}/HEAD" 2>/dev/null
}

git::check_file_exists_in_previous_commit() {
  [[ -n "${1:-}" ]] && ! git::git "${@:1:}" rev-parse @~:"${1:-}" > /dev/null 2>&1
}

git::get_file_last_commit_timestamp() {
  [[ -n "${1:-}" ]] && git rev-list --all --date-order --timestamp -1 "${1:-}" 2> /dev/null | awk '{print $1}'
}

git::get_commit_timestamp() {
  [[ -n "${1:-}" ]] && git rev-list --all --date-order --timestamp | grep "${1:-}" | awk '{print $1}'
}

git::check_file_is_modified_after_commit() {
  local file_path file_commit_date commit_to_check commit_to_check_date
  file_path="${1:-}"
  commit_to_check="${2:-}"
  { [[ -z "$file_path" ]] || [[ -z "${commit_to_check:-}" ]] || [[ ! -e "$file_path" ]]; } && return 1

  file_commit_date="$(git::get_file_last_commit_timestamp "${file_path:-}" 2> /dev/null)"

  [[ -z "$file_commit_date" ]] && return 0 # File path did not exists previously then
  # it is more recent than any commit 😅

  commit_to_check_date="$(git::get_commit_timestamp "$commit_to_check")"
  [[ "$file_commit_date" -gt "$commit_to_check_date" ]]
}


myfunc() {
  echo "${@:1}"
}