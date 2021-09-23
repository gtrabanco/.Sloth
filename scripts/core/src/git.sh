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
      -n "${GIT_EXECUTABLE:-}" &&
      ! -x "$GIT_EXECUTABLE" ]] &&
    command -v git &> /dev/null
then
  GIT_EXECUTABLE="$(command -v git)"

elif
  [[ -z "${GIT_EXECUTABLE:-}" ]] &&
    command -v git &> /dev/null
then
  GIT_EXECUTABLE="$(command -v git)"

elif
  [[ -z "${GIT_EXECUTABLE:-}" ]] &&
    command -vp git &> /dev/null
then
  GIT_EXECUTABLE="$(command -vp git)"

elif
  [[ -z "${GIT_EXECUTABLE:-}" ]] ||
    [[ 
      -n "${GIT_EXECUTABLE:-}" &&
      ! -x "$GIT_EXECUTABLE" ]]
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

  if [[ -n "${ALWAYS_USE_GIT_ARGS[*]:-}" && ${#ALWAYS_USE_GIT_ARGS[@]} -gt 0 && $# -gt 0 ]]; then
    if [[ -n "${DEBUG:-}" ]]; then
      echo " $ $GIT_EXECUTABLE" "${ALWAYS_USE_GIT_ARGS[@]}" "$@" | log::file "git execution of command"
      "$GIT_EXECUTABLE" "${ALWAYS_USE_GIT_ARGS[@]}" "$@" | command -p tee -a "${DOTLY_LOG_FILE:-$HOME/dotly.log}"
      log::append "End execution of git command"
    else
      "$GIT_EXECUTABLE" "${ALWAYS_USE_GIT_ARGS[@]}" "$@"
    fi
  elif [[ $# -gt 0 ]]; then
    if [[ -n "${DEBUG:-}" ]]; then
      echo " $ $GIT_EXECUTABLE" "$@" | log::file "git execution of command"
      "$GIT_EXECUTABLE" "$@" | command -p tee -a "${DOTLY_LOG_FILE:-$HOME/dotly.log}"
      log::append "End execution of git command"
    else
      "$GIT_EXECUTABLE" "$@"
    fi
  fi
}

#;
# git::is_in_repo()
# check if a directory is a repository
#"
git::is_in_repo() {
  git::git "$@" rev-parse --is-inside-work-tree &> /dev/null
}

#;
# git::current_branch()
# Get the current active branch
#"
git::current_branch() {
  git::git "$@" branch --show-current --no-color 2> /dev/null || return
}

#!/usr/bin/env bash
#shellcheck disable=SC2034

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

  gitmodules_path="${gitmodules_path:-${DOTFILES_PATH:-/dev/null}/.gitmodules}"
  submodule_directory="${submodule_directory:-modules/${1:-}}"
  property="${2:-}"

  [[ -f "$gitmodules_path" ]] &&
    [[ -n "$submodule_directory" ]] &&
    [[ -n "$property" ]] &&
    git config -f "$gitmodules_path" submodule."$submodule_directory"."$property" || return
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
# @param any args Arguments for git command
# @return boolean
#"
git::check_unpushed_commits() {
  [[ -n "$(git::git "$@" log --branches --not --remotes --pretty="format:%H")" ]]
}

#;
# git::is_clean()
# Checks if the repository has local changes even if they were commited
# @param any args Additional git command args. Mandatory to pass previous two arguments (remote & branch) to give arguments to git command.
# @return boolean
#"
git::is_clean() {
  # Changes that are indexed: git add
  # "${GIT_EXECUTABLE}" diff-index --no-ext-diff --quiet --exit-code --cached --ignore-submodules="all" HEAD -- || return 1

  # Changed tracked files that are not indexed: previous to git add
  "${GIT_EXECUTABLE}" diff-index --no-ext-diff --quiet --exit-code --ignore-submodules="all" HEAD -- || return 1
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
  local remote branch

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

  ! git::check_remote_exists "$remote" "$@" && return 1

  [[ -n "$(git::git "$@" branch --remotes --list "${remote}/${branch}" 2> /dev/null)" ]]
}

#;
# git::local_branch_exists()
# Check if branch exists in local repository
# @param string branch
# @param any args Additional arguments that will be passed to git
# @return boolean
#"
git::local_branch_exists() {
  local -r branch="${1:-}"
  [[ -n "$branch" ]] && shift

  git::git "$@" show-ref --verify --quiet "refs/heads/${branch}"
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

  git::git "${@:2}" describe --tags "$(git::git "${@:2}" rev-list --tags --max-count=1)" 2> /dev/null | sed 's/^v//'
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
  local -r version_pattern="${2:-v*.*.*}"
  [[ -z "$remote_url" ]] && return

  git::git "${@:3}" ls-remote --tags --refs "$remote_url" "${version_pattern}" 2> /dev/null | command awk '{gsub(/\\^\\{\\}/,"", $NF);gsub("refs/tags/v",""); print $NF}' | command sort -Vur | command head -n1
}

#;
# git::check_branch_is_behind()
# Check if the branch is behind the remote branch. Needs an upstream branch.
# @param string local_branch current branch by default
#"
git::check_branch_is_behind() {
  local -r branch="${1:-$(git::current_branch "$@")}"
  [[ -z "$branch" ]] && return 1
  [[ -n "${1:-}" ]] && shift

  local -r upstream_branch="$(git::git "$@" config --get "branch.${branch}.merge" || echo -n)"
  if [[ -n "$upstream_branch" ]]; then
    # @{u} or @{upstream} can be used but to keep compatibility with older git versions I use this way
    [[ $(git::git "$@" rev-list --count "${branch}..${upstream_branch}") -gt 0 ]]
  else
    # Does not have a tracked branch
    return 1
  fi
}

#;
# git::check_branch_is_ahead()
# Check if the branch is ahead of the remote branch (has commits to be pushed). Needs an upstream branch.
# @param string local_branch current branch by default
#"
git::check_branch_is_ahead() {
  local -r branch="${1:-$(git::current_branch "$@")}"
  [[ -z "$branch" ]] && return 1
  [[ -n "${1:-}" ]] && shift

  local -r upstream_branch="$(git::git "$@" config --get "branch.${branch}.merge" || echo -n)"

  if [[ -n "$upstream_branch" ]]; then
    # @{u} or @{upstream} can be used but to keep compatibility with older git versions I use this way
    [[ $(git::git "$@" rev-list --count "${upstream_branch}...${branch}") -gt 0 ]]
  else
    # Does not have a tracked branch
    return 1
  fi
}

#;
# git::get_remote_head_upstream_branch()
# Get which is the branch or the remote head if any
# @param string remote Optional, by default is "origin"
# @param any args Additional arguments that will be passed to git command
# @return string|void
#"
git::get_remote_head_upstream_branch() {
  local -r remote="${1:-origin}"
  [[ -n "${1:-}" ]] && shift

  ! git::check_remote_exists "$remote" "$@" && return
  git::git "$@" symbolic-ref --short "refs/remotes/${remote}/HEAD" || return
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

  git::git "$@" remote set-head "$remote" "$branch"
}

#;
# git::check_file_exists_in_previous_commit()
#"
git::check_file_exists_in_previous_commit() {
  [[ -n "${1:-}" ]] && ! git::git "${@:2}" rev-parse @~:"${1:-}" &> /dev/null
}

#;
# git::get_file_last_commit_timestamp()
# The timestamp of were a file was modified/included/deleted in a commit
# @param string file
#"
git::get_file_last_commit_timestamp() {
  [[ -n "${1:-}" ]] && git "${@:2}" rev-list --all --date-order --timestamp -1 "${1:-}" 2> /dev/null | awk '{print $1}'
}

#;
# git::get_commit_timestamp()
# @param string commit
#"
git::get_commit_timestamp() {
  [[ -n "${1:-}" ]] && git::git "${@:2}" rev-list --all --date-order --timestamp 2> /dev/null | grep "${1:-}" | awk '{print $1}'
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
  shift 2

  file_commit_date="$(git::get_file_last_commit_timestamp "${file_path:-}" "$@" 2> /dev/null)"

  [[ -z "$file_commit_date" ]] && return 0 # File path did not exists previously then
  # it is more recent than any commit 😅

  commit_to_check_date="$(git::get_commit_timestamp "$commit_to_check" "$@")"
  [[ "$file_commit_date" -gt "$commit_to_check_date" ]]
}

#;
# git::clone_track_branch()
# Clone and track a remote branch. Makes a forced checkout to that branch.
# @param string remote If no second parameter is give, this will be the branch
# @param string branch
# @param any args Additional arguments that will be passed to git command
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
  [[ -z "$(git::git "$@" branch --list "$branch")" ]] && { git::git "$@" checkout -t "remotes/${remote}/${branch}" 1>&2 || true; }
  [[ -n "$(git::git "$@" branch --list "$branch")" ]] && { git::git "$@" branch --set-upstream-to="${remote}/${branch}" "$branch" 1>&2 || true; }
  git::git "$@" checkout --force "${branch}" 1>&2 || true
}

#;
# git::clone_branches()
# Bulk clone of remote branches
# @param string remote Should exists
# @param any args Additional arguments that will be passed to git clone
# @return boolean
#"
git::clone_branches() {
  local remote_branch branch
  local -r remote="${1:-origin}"
  [[ -n "${1:-}" ]] && shift

  ! git::git "$@" remote get-url "$remote" &> /dev/null && return 1

  for remote_branch in $(git::git "$@" branch -a | sed -n "/\/HEAD /d; /\/master$/d; /remotes/p;" | xargs -I _ echo _ | grep "^remotes/${remote}"); do
    branch="${remote_branch//remotes\/${remote}\//}"
    git::clone_track_branch "$remote" "$branch" "$@" 1>&2 || true
  done
}

#;
# git::current_branch_is_tracked()
#"
git::current_branch_is_tracked() {
  git::git "$@" rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2> /dev/null
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

  # Check if remote branch exists
  git::remote_branch_exists "$remote" "$branch" "$@" || return 1

  # Check if current branch is the same we want to pull and discard any change in the current branch if there are any
  if [[ $(git::current_branch "$@") != "${branch}" ]]; then
    git::git "$@" clean -f -q 1>&2
    git::git "$@" reset --hard HEAD 1>&2
    git::git "$@" checkout --force "${branch}" 1>&2
  fi

  # Clone and track the remote branch to make sure we have the branch
  git::clone_track_branch "$remote" "$branch" "$@" 1>&2
  git::git "$@" checkout --force "$branch" 1>&2
  git::git "$@" reset --hard "${remote}/${branch}" 1>&2
  git::git "$@" fetch --all --tags --force 1>&2
  git::git "$@" pull --all -s recursive -X theirs 1>&2
  git::git "$@" reset --hard HEAD 1>&2
}

#;
# git::repository_pull_all()
# Make a pull in all branches of a repository. It also track all branches.
# @param string remote
# @param any args Additional arguments to pass to git command
#"
git::repository_pull_all() {
  local -r remote="${1:-origin}"

  ! git::check_remote_exists "$remote" "$@" && return 1

  git::git "$@" clean -f -q 1>&2
  git::git "$@" reset --hard HEAD 1>&2

  for remote_branch in $(git::git "$@" branch -a | sed -n "/\/HEAD /d; /\/master$/d; /remotes/p;" | xargs -I _ echo _ | grep "^remotes/${remote}"); do
    branch="${remote_branch//remotes\/${remote}\//}"
    git::clone_track_branch "$remote" "$branch" "$@" 1>&2
    git::git "$@" checkout --force "$branch" 1>&2
    git::git "$@" reset --hard "${remote}/${branch}" 1>&2
    git::git "$@" pull --all -s recursive -X theirs 1>&2
    git::git "$@" reset --hard HEAD 1>&2
  done
}

#;
# git::init_repository_if_necessary()
# Initialize a git repository only if necessary only
# @param string url Mandatory if git::is_in_repo fails
# @param string remote origin by default
# @param string branch master by default. Only used if not any branch
# @param any args Additional arguments to pass to git command. Url, remote and branch arguments are mandatory if you want to pass arguments to git.
#"
git::init_repository_if_necessary() {
  local head_branch
  local -r url="${1:-}"
  local -r remote="${2:-origin}"
  local -r branch="${3:-master}"
  [[ -n "${url}" ]] && shift
  [[ -n "${1:-}" ]] && shift # remote
  [[ -n "${1:-}" ]] && shift # branch
  git::is_in_repo "$@" &> /dev/null && return

  if [[ -n "$url" ]]; then
    git::git "$@" init 1>&2
    git::git "$@" remote add "$remote" "$url" 1>&2
    git::git "$@" config "remote.${remote}.url" "$url" 1>&2
    git::git "$@" config "remote.${remote}.fetch" "+refs/heads/*:refs/remotes/${remote}/*" 1>&2
    git::git "$@" fetch --all --tags --force 1>&2
    git::git "$@" branch --set-upstream-to="${remote}/${branch}" "$branch" 1>&2
    git::git "$@" remote set-head "$remote" --auto &> /dev/null 1>&2
    head_branch="$(git::get_remote_head_upstream_branch "$remote" "$@")"

    if [[ -z "$head_branch" ]]; then
      head_branch="${remote}/${branch}"
      git::set_remote_head_upstream_branch "$remote" "$head_branch" "$@" 1>&2
    fi

    git::git "$@" clean -f -d 1>&2
    git::pull_branch "$remote" "${head_branch//remotes\/origin\//}" "$@" 1>&2
    git::git "$@" reset --hard "${head_branch}" 1>&2
  else
    return 1
  fi
}
