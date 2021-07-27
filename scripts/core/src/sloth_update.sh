#!/usr/bin/env bash
#shellcheck disable=SC2034

# TODO Add variables to export and document the variables below.

# Maybe this should be in a different file or provide them in exports.sh
# .Sloth will be always a submodule so we need that configuration for update
SLOTH_SUBMODULES_DIRECTORY="$(realpath -qms --relative-to="$DOTFILES_PATH" "${SLOTH_PATH:-${DOTLY_PATH:-}}")"
SLOTH_SUBMODULES_DIRECTORY="${SLOTH_SUBMODULES_DIRECTORY:-modules/sloth}"
SLOTH_GITMODULES_URL="$(git::get_submodule_property "${DOTFILES_PATH:-}/.gitmodules" "$SLOTH_SUBMODULES_DIRECTORY" "url")"
SLOTH_GITMODULES_URL="${SLOTH_GITMODULES_URL:-$SLOTH_DEFAULT_GIT_HTTP_URL}"
SLOTH_GITMODULES_BRANCH="$(git::get_submodule_property "${DOTFILES_PATH:-}/.gitmodules" "$SLOTH_SUBMODULES_DIRECTORY" "branch")"
SLOTH_GITMODULES_BRANCH="${SLOTH_GITMODULES_BRANCH:-master}"

# Defaults values if no values are provided
[[ -z "${SLOTH_DEFAULT_GIT_HTTP_URL:-}" ]] && readonly SLOTH_DEFAULT_GIT_HTTP_URL="https://github.com/gtrabanco/sloth"
[[ -z "${SLOTH_DEFAULT_GIT_SSH_URL:-}" ]] && readonly SLOTH_DEFAULT_GIT_SSH_URL="git+ssh://git@github.com:gtrabanco/sloth.git"
[[ -z "${SLOTH_DEFAULT_REMOTE:-}" ]] && readonly SLOTH_DEFAULT_REMOTE="origin"
# SLOTH_DEFAULT_BRANCH is not the same as SLOTH_GITMODULES_BRANCH
# SLOTH_GITMODULES_BRANCH is the branch we want to use if we are using always latest version
# SLOTH_GITMODULES_BRANCH is the HEAD branch of remote repository were Pull Request are merged
[[ -z "${SLOTH_DEFAULT_BRANCH:-}" ]] && readonly SLOTH_DEFAULT_BRANCH="master"

SLOTH_DEFAULT_URL=${SLOTH_GITMODULES_URL:-$SLOTH_DEFAULT_GIT_SSH_URL}

#
# .Sloth update strategy Configuration
#
export SLOTH_UPDATE_VERSION="${SLOTH_UPDATE_VERSION:-latest}" # stable, minor, latest, or any specified version
export SLOTH_ENV="${SLOTH_ENV:-production}"                   # production or development. If you define development
# all updates must be manually or when you have a clean working directory and
# pushed your commits.
# This is done to avoid conflicts and lost changes.
# For development all other configuration will be ignored and every time it
# can be updated you will get the latest version.

if [[ -z "${SLOTH_UPDATE_GIT_ARGS[*]:-}" ]]; then
  readonly SLOTH_UPDATE_GIT_ARGS=(
    -C "${SLOTH_PATH:-${DOTLY_PATH:-}}"
  )
fi

#;
# sloth_update::sloth_repository_set_ready()
# Default repository initilisation and first fetch if is not ready to have updates
# @return void
#"
sloth_update::sloth_repository_set_ready() {
  if ! git::check_remote_exists "${SLOTH_DEFAULT_REMOTE:-origin}" "${SLOTH_UPDATE_GIT_ARGS[@]}"; then
    git::init_repository_if_necessary "${SLOTH_DEFAULT_URL:-${SLOTH_DEFAULT_GIT_SSH_URL:-git+ssh://git@github.com:gtrabanco/sloth.git}}" "${SLOTH_DEFAULT_REMOTE:-origin}" "${SLOTH_DEFAULT_BRANCH:-master}" "${SLOTH_UPDATE_GIT_ARGS[@]}"
  fi

  # Set head branch
  git::git "${SLOTH_UPDATE_GIT_ARGS[@]}" remote set-head "$remote" --auto &> /dev/null 1>&2

  # Automatic convert windows git crlf to lf
  git::git "${SLOTH_UPDATE_GIT_ARGS[@]}" config --bool core.autcrl false 1>&2

  # Track default branch
  git::clone_track_branch "${SLOTH_DEFAULT_REMOTE:-origin}" "${SLOTH_DEFAULT_BRANCH:-master}" "${SLOTH_UPDATE_GIT_ARGS[@]}" &> /dev/null || true

  # Unshallow by the way
  git::git "${SLOTH_UPDATE_GIT_ARGS[@]}" fetch --unshallow &> /dev/null
}

#;
# sloth_update::get_current_version()
# Get which one is your current version or latest downloaded version
# @return string|void
#"
sloth_update::get_current_version() {
  git::git "${SLOTH_UPDATE_GIT_ARGS[@]}" describe --tags --abbrev=0 2> /dev/null
}

#;
# sloth_update::get_latest_version()
# Get the latest stable version available
# @return string
#"
sloth_update::get_latest_stable_version() {
  local latest_version
  git::remote_latest_tag_version "${SLOTH_DEFAULT_URL:-${SLOTH_DEFAULT_GIT_SSH_URL:-git+ssh://git@github.com:gtrabanco/sloth.git}}" "v*.*.*" "${SLOTH_UPDATE_GIT_ARGS[@]}"
}

#;
# sloth_update::local_sloth_repository_can_be_updated()
# Check if we should update based on the configured SLOTH_UPDATE_VERSION and SLOTH_ENV. This takes care in production about pending commits and clean working directory as described in the comments for SLOTH_DEV
# @return boolean
#"
sloth_update::local_sloth_repository_can_be_updated() {
  local IS_WORKING_DIRECTORY_CLEAN=false HAS_UNPUSHED_COMMITS=false
  git::is_clean "${SLOTH_UPDATE_GIT_ARGS[@]}" && IS_WORKING_DIRECTORY_CLEAN=true

  # If remote exists locally
  if git::check_remote_exists "${SLOTH_DEFAULT_REMOTE:-origin}" "${SLOTH_UPDATE_GIT_ARGS[@]}"; then
    git::git "${SLOTH_UPDATE_GIT_ARGS[@]}" branch --set-upstream-to="${SLOTH_DEFAULT_REMOTE:-origin}/${SLOTH_DEFAULT_BRANCH:-master}" "${SLOTH_DEFAULT_BRANCH:-master}" &> /dev/null
    git::check_branch_is_ahead "${SLOTH_DEFAULT_BRANCH:-master}" "${SLOTH_UPDATE_GIT_ARGS[@]}" && HAS_UNPUSHED_COMMITS=true
  fi

  if $IS_WORKING_DIRECTORY_CLEAN && ! $HAS_UNPUSHED_COMMITS; then
    # Can safely update, clean working directory and not unpushed commits
    return 0
  fi

  return 1
}

#;
# sloth_update::sloth_update_repositry()
# Gracefully update sloth repository to the latest version. Use defined vars in top as default values if no one is provided. It will use \${SLOTH_UPDATE_GIT_ARGS[@]} as default arguments for git. This update only the SLOTH_DEFAULT_BRANCH and tags.
# @param string remote
# @param string url Default url for the remote to be configured if not exists
# @param string default_branch Default branch for the remote to be configured if not exists
# @param bool force_update Default false. If true it will force update even if there are pending commits
# @return 0 if all ok, error code otherwise 10, in no force means has pending commits or dirty directory, 20 remote does not exists or can't be set, no default branch, 40 git pull fails
#"
sloth_update::sloth_update_repository() {
  local remote url default_branch head_branch force_update
  remote="${1:-${SLOTH_DEFAULT_REMOTE:-origin}}"
  url="${2:-${SLOTH_GITMODULES_URL:-${SLOTH_DEFAULT_GIT_SSH_URL:-git+ssh://git@github.com:gtrabanco/sloth.git}}}"
  branch="${3:-${SLOTH_DEFAULT_BRANCH:-master}}"
  default_remote_branch="${remote}/${branch}"
  force_update="${4:-false}"

  # Check if can be updated
  if ! $force_update && sloth_update::local_sloth_repository_can_be_updated; then
    # No force, dirty directory and maybe pending commits
    return 10
  fi

  # Set ready if necessary
  sloth_update::sloth_repository_set_ready

  # Remote exists?
  ! git::check_remote_exists "$remote" "${SLOTH_UPDATE_GIT_ARGS[@]}" && output::error "Remote \`${remote}\` does not exists" && return 20

  # Get remote HEAD branch
  head_branch="$(git::get_remote_head_upstream_branch "$remote" "${SLOTH_UPDATE_GIT_ARGS[@]}")"
  if [[ -z "$head_branch" ]]; then
    git::set_remote_head_upstream_branch "$remote" "$default_remote_branch" "${SLOTH_UPDATE_GIT_ARGS[@]}"
    head_branch="$(git::get_remote_head_upstream_branch "$remote" "${SLOTH_UPDATE_GIT_ARGS[@]}")"

    [[ -z "$head_branch" ]] && output::error "Remote \`${remote}\` does not have a default branch and \`${default_branch}\` could not be set" && return 30
  fi

  git::pull_branch "$remote" "$head_branch" "${SLOTH_UPDATE_GIT_ARGS[@]}" 1>&2 && output::solution "Repository has been updated" || return 40
}

#;
# sloth_update::sloth()
# Full update sloth function that can be used to update in sync or async mode
#"
sloth_update::sloth() {
  # Check if current version is a fixed version

  # Check if can be updated (is dev then should be clean and no unpushed commits "can be updated", not dev checkout force and clean to master)

  # Check if is behind remote

  # Update

  return
}
