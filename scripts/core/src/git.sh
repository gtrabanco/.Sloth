#!/usr/bin/env bash
#shellcheck disable=SC2034

#
#  - You can force the usage of specific git binary by defining GIT_EXECUTABLE.
#  - Also can pass git args forcely to all these git command by passing an array
#  of args with the array variable ALWAYS_USE_GIT_ARGS.
#

if
  [[ -z "${GIT_EXECUTABLE:-}" ]] ||
  [[ -n "${GIT_EXECUTABLE:-}" ]] &&
  [[ ! -x "$GIT_EXECUTABLE" ]] &&
  command -v git &>/dev/null
then
  GIT_EXECUTABLE="$(command -v git)"
elif command -v git &>/dev/null; then
  GIT_EXECUTABLE="$(command -v git)"
else
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
# git::get_submodule_property()
# Get the property of a submodule, by default get properties of DOTFILES_PATH submodules
# @param string gitmodules_path The path to .gitmodules file
# @param string submodule directory if no gitmodules is provided this will be the first argument
# @param string property
# @return string|void
#"
git::get_submodule_property() {
  local gitmodules_path submodule_directory property default_submodule_path
  

  if [ $# -gt 2 ]; then
    gitmodules_path="$1"
    shift
    submodule_directory="$1"
  fi

  gitmodules_path="${gitmodules_path:-${DOTFILES_PATH:-}/.gitmodules}"
  submodule_directory="${submodule_directory:-modules/${1:-}}"
  property="${2:-}"

  [[ -f "$gitmodules_path" ]] && echo "gitmodules" &&
    [[ -n "$submodule_directory" ]] && echo "submodule" &&
    [[ -n "$property" ]] && echo "property" &&
    echo git config -f "$gitmodules_path" submodule."$submodule_directory"."$property" || return
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
  git::git "$@" branch --show-current 2>/dev/null || return
}

#;
# git::check_remote_exists()
# @param string remote Optional remote, use "origin" as default
#"
git::check_remote_exists() {
  local -r remote="${1:-origin}"
  [[ -n "${1:-}" ]] && shift
  git::git "$@" remote get-url "$remote" &> /dev/null
}

#;
# git::check_unpushed_commits()
# Check if there are commits without pushed to remote
# @param string remote Optional remote, use "origin" as default
# @param string branch Optional branch, use "master" as default
# @return boolean
#"
git::check_unpushed_commits() {
  local -r remote="${1:-origin}"
  local -r branch="${2:-master}"
  case $# in
    1)  shift    ;;
    0)           ;;
    *)  shift 2  ;;
  esac
  git::git "$@" cherry -v "${remote}/${branch}" &> /dev/null
}

#;
# git::is_clean()
# Checks if the repository has local changes even if they were commited
# @param string remote Optional remote, use "origin" as default
# @param string branch Optional branch, use "master" as default
# @param any args Additional git command args. Mandatory to pass previous two arguments (remote & branch) to give arguments to git command.
# @return boolean
#"
git::is_clean() {
  local -r remote="${1:-origin}"
  local -r branch="${2:-master}"
  case $# in
    1)  shift    ;;
    0)           ;;
    *)  shift 2  ;;
  esac
  
  [[ $(git::git "$@" status --porcelain | wc -l) -eq 0 ]] && git::git "$@" diff --quiet --exit-code "${remote}/${branch}" &> /dev/null
}

#;
# git::current_commit_hash()
# Get the most recent commit of given branch or HEAD
# @param string branch Optional, by default is HEAD
#"
git::current_commit_hash() {
  local -r branch="${1:-HEAD}"
  [[ -n "${1:-}" ]] && shift
  git::git "$@" rev-parse -q --verify "${branch}"
}

#;
# git::is_valid_commit()
# Check if a given commit is a valid commit in the local repository
#"
git::is_valid_commit() {
  local -r commit="${1:-HEAD}"
  [[ -n "${1:-}" ]] && shift

  [[ $(git::git "$@" cat-file -t "$commit") == commit ]]
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
# git::local_latest_tag_version()
# Get the latest tag version in the local repository
# @param any args Additional arguments that will be passed to git command
# @return string|void (output) if any
#"
git::local_latest_tag_version() {
  local -r remote_url="${1:-}"
  [[ -z "$remote_url" ]] && return

  git::git "${@:2}" describe --tags "$(git::git "${@:2}" rev-list --tags --max-count=1)" 2>/dev/null | sed 's/^v//'
}

#;
# git::remote_latest_tag_version()
# Get the latest tag version of a given repository url or upstream
# @param string remote_url Remote upstream or repository url
# @param string version_pattern Pattern to match the version by default is "v*"
# @param any args Additional arguments that will be passed to git command. You must define previous args if you want to give additional arguments to git command.
# @return string|void (output) if any
#"
git::remote_latest_tag_version() {
  local -r remote_url="${1:-}"
  local -r version_pattern="${2:-v*}"
  [[ -z "$remote_url" ]] && return

  git::git "${@:3}" ls-remote --tags --refs "$remote_url" 'v*' 2>/dev/null | awk '{print $NF}' | sed 's#refs/tags/v##g' | sort -r | head -n1 || true
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

#;
# git::get_current_branch_status()
# Get the current branch status (ahead, up, behind)
#"
git::check_current_branch_is_behind() {
  # git status --ahead-behind | head -n2 | tail -n1 | awk '{NF--; print $4"\n"$NF}'
  [[ $(git::git "$@" status --ahead-behind 2>/dev/null | head -n2 | tail -n1 | awk '{print $4}') == "behind" ]]
}

#;
# git::get_remote_head_upstream_branch()
# Get which is the branch or the remote head if any
# @param string remote Optional, by default is "origin"
# @param any args Additional arguments that will be passed to git command
# @return string|false
#"
git::get_remote_head_upstream_branch() {
  local -r remote="${1:-origin}"
  [[ -n "${1:-}" ]] && shift
  git::git "$@" symbolic-ref --short "refs/remotes/${remote}/HEAD" | xargs 2>/dev/null
}

#;
# git::set_remote_head_upstream_branch()
# Set which is the branch HEAD considered as remote/HEAD for a remote
#"
git::set_remote_head_upstream_branch() {
  local remote branch
  if [[ $# -gt 1 ]]; then
    remote="$1"
    branch="$2"
    shift 2
  elif [[ $# -eq 1 ]]; then
    remote="origin"
    branch="$1"
    shift
  else
    remote="origin"
    branch="master"
  fi

  git::git "$@" remote set-head "$remote" master
}

#;
# git::check_file_exists_in_previous_commit()
#"
git::check_file_exists_in_previous_commit() {
  [[ -n "${1:-}" ]] && ! git::git "${@:1:}" rev-parse @~:"${1:-}" > /dev/null 2>&1
}

#;
# git::get_file_last_commit_timestamp()
# The timestamp of were a file was modified/included/deleted in a commit
# @param string file
#"
git::get_file_last_commit_timestamp() {
  [[ -n "${1:-}" ]] && git rev-list --all --date-order --timestamp -1 "${1:-}" 2> /dev/null | awk '{print $1}'
}

#;
# git::get_commit_timestamp()
# @param string commit
#"
git::get_commit_timestamp() {
  [[ -n "${1:-}" ]] && git rev-list --all --date-order --timestamp 2> /dev/null | grep "${1:-}" | awk '{print $1}'
}

#;
# git::check_file_is_modified_after_commit()
# Given a file and commit gets if the file was modified after that commit
# @param string file
# @param string commit
# @return boolean
#"
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

#;
# git::check_working_dir_is_clean()
# @return boolean
#"
git::check_working_dir_is_clean() {
  [[ $(git::git "$@" status -sb 2> /dev/null | wc -l) -eq 1 ]]
}

#;
# git::check_is_shallow()
# Check if a repository is a shallow repository
#"
git::check_is_shallow() {
  [[ -f "${1:-}/.git/shallow" ]]
}

#;
# git::unshallow()
#"
git::unshallow() {
  git::git "$@" fetch --unsallow 1>&2
}

#;
# git::clone_track_branch()
# Clone and track a remote branch
# @param string remote If no second parameter is give, this will be the branch
# @param string branch
#"
git::clone_track_branch() {
  local remote branch
  if [[ $# -ge 2 ]]; then
    remote="${1:-}"
    branch="${2:-}"
    shift 2
  elif [[ $# -eq 1 ]]; then
    remote="origin"
    branch="${1:-}"
    shift
  else
    remote="origin"
    branch="master"
  fi

  ! git::check_remote_exists "$remote" "$@" && return 1
  [[ -z "$(git::git "$@" branch --list "$branch")" ]] && git::git "$@" checkout -t "remotes/${remote}/${branch}" 1>&2
  [[ -n "$(git::git "$@" branch --list "$branch")" ]] && git::git "$@" branch --set-upstream-to="${remote}/${branch}" "$branch" 1>&2
}

#;
# git::clone_branches()
# Bulk clone of remote branches
#"
git::clone_branches() {
  local remote_branch branch
  local -r remote="${1:-origin}"
  [[ -n "${1:-}" ]] && shift

  for remote_branch in $(git::git "$@" branch -a | sed -n "/\/HEAD /d; /\/master$/d; /remotes/p;" | xargs -I _ echo _ | grep "^remotes/${remote}"); do
    branch="${remote_branch//remotes\/${remote}\//}"
    git::clone_track_branch "$remote" "$branch" "$@" 1>&2
  done
}

#;
# git::current_branch_is_tracked()
#"
git::current_branch_is_tracked() {
  git::git "$@" rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null
}

#;
# git::update_repositry()
# Update repository to the latest version discarding local changes and not commited changes
# @param string remote
# @param string branch
# @param any args Additional arguments to pass to git command
#"
git::update_repository() {
  local -r remote="${1:-origin}"
  local -r branch="${2:-master}"

  case $# in
    2)  shift 2  ;;
    1)  shift    ;;
  esac
  
  git::git "$@" clean -f -q 1>&2
  git::clone_track_branch "$remote" "$branch" "$@"
  git::git "$@" fetch --all --tags --force 1>&2
  git::git "$@" reset --hard "${remote}/${branch}" 1>&2
  git::git "$@" pull --all -s recursive -X theirs 1>&2
  git::git "$@" reset --hard 1>&2
}

#;
# git::pull_branch()
# Pull a branch without fetching it
# @param string remote
# @param string branch
# @param any args Additional arguments to pass to git command
#"
git::pull_branch() {

  case $# in
    1)
      local -r remote="origin"
      local -r branch="${1:-master}"
      shift
      ;;
    0)
      local -r remote="origin"
      local -r branch="master"
      ;;
    *)
      local -r remote="${1:-origin}"
      local -r branch="${2:-master}"
      shift 2
      ;;
  esac

  git::git "$@" reset --hard "${remote}/${branch}" 1>&2
  git::clone_track_branch "$remote" "$branch" "$@" 1>&2 # I know it is not necessary but I want to make it explicit
  git::git "$@" checkout --force 
  git::git "$@" pull --all -s recursive -X theirs 1>&2
}

#;
# git::repository_pull_all()
# Make a pull in all branches of a repository. It also track all branches.
# @param string remote
# @param string branch Default branch. If not will try to get from remote
# @param any args Additional arguments to pass to git command
#"
git::repository_pull_all() {
  local -r remote="${1:-origin}"
  [[ -n "${1:-}" ]] && shift

  for remote_branch in $(git::git "$@" branch -a | sed -n "/\/HEAD /d; /\/master$/d; /remotes/p;" | xargs -I _ echo _ | grep "^remotes/${remote}"); do
    branch="${remote_branch//remotes\/${remote}\//}"
    git::clone_track_branch "$remote" "$branch" "$@" 1>&2
    git::git "$@" reset --hard "${remote}/${branch}" 1>&2
    git::git "$@" pull --all -s recursive -X theirs 1>&2
  done
}
