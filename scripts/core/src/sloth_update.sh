#!/usr/bin/env bash
#shellcheck disable=SC2034

############## Needed variables ##############
#
# .Sloth update strategy Configuration
#
export SLOTH_AUTO_UPDATE_PERIOD_IN_DAYS=${SLOTH_AUTO_UPDATE_PERIOD_IN_DAYS:-7}
export SLOTH_AUTO_UPDATE_MODE=${SLOTH_AUTO_UPDATE_MODE:-auto}
export SLOTH_UPDATE_VERSION="${SLOTH_UPDATE_VERSION:-latest}" # stable, latest, or any specified version if you want to pin to that version
export SLOTH_ENV="${SLOTH_ENV:-production}"                   # production or development. If you define development
# all updates must be manually or when you have a clean working directory and
# pushed your commits.
# This is done to avoid conflicts and lost changes.
# For development all other configuration will be ignored and every time it
# can be updated you will get the latest version.

# Files
SLOTH_UPDATED_FILE="${SLOTH_UPDATED_FILE:-$DOTFILES_PATH/.sloth_updated}"
SLOTH_UPDATE_AVAILABE_FILE="${SLOTH_UPDATE_AVAILABE_FILE:-"$DOTFILES_PATH/.sloth_update_available"}"
SLOTH_FORCE_CURRENT_VERSION_FILE="${SLOTH_FORCE_CURRENT_VERSION_FILE:-$DOTFILES_PATH/.sloth_force_current_version}"

# Urls, branches and remotes
if [[ -z "${SLOTH_SUBMODULES_DIRECTORY:-}" ]]; then
  SLOTH_SUBMODULES_DIRECTORY="${SLOTH_SUBMODULES_DIRECTORY:-modules/sloth}"
fi

if [[ -z "${SLOTH_GITMODULES_URL:-}" ]]; then
  SLOTH_GITMODULES_URL="$(git::get_submodule_property "${DOTFILES_PATH:-}/.gitmodules" "$SLOTH_SUBMODULES_DIRECTORY" "url")"
  SLOTH_GITMODULES_URL="${SLOTH_GITMODULES_URL:-$SLOTH_DEFAULT_GIT_HTTP_URL}"
fi

if [[ -z "${SLOTH_GITMODULES_BRANCH:-}" ]]; then
  SLOTH_GITMODULES_BRANCH="$(git::get_submodule_property "${DOTFILES_PATH:-}/.gitmodules" "$SLOTH_SUBMODULES_DIRECTORY" "branch")"
  SLOTH_GITMODULES_BRANCH="${SLOTH_GITMODULES_BRANCH:-}"
fi

# Defaults values if no values are provided
[[ -z "${SLOTH_DEFAULT_GIT_HTTP_URL:-}" ]] && readonly SLOTH_DEFAULT_GIT_HTTP_URL="https://github.com/gtrabanco/sloth"
[[ -z "${SLOTH_DEFAULT_GIT_SSH_URL:-}" ]] && readonly SLOTH_DEFAULT_GIT_SSH_URL="git+ssh://git@github.com:gtrabanco/sloth.git"
[[ -z "${SLOTH_DEFAULT_REMOTE:-}" ]] && readonly SLOTH_DEFAULT_REMOTE="origin"
# SLOTH_DEFAULT_BRANCH is not the same as SLOTH_GITMODULES_BRANCH
# SLOTH_GITMODULES_BRANCH is the branch we want to use if we are using always latest version
# SLOTH_GITMODULES_BRANCH is the HEAD branch of remote repository were Pull Request are merged
[[ -z "${SLOTH_DEFAULT_BRANCH:-}" ]] && readonly SLOTH_DEFAULT_BRANCH="master"

SLOTH_DEFAULT_URL=${SLOTH_GITMODULES_URL:-$SLOTH_DEFAULT_GIT_SSH_URL}

# Git arguments
if [[ -z "${SLOTH_UPDATE_GIT_ARGS[*]:-}" ]]; then
  readonly SLOTH_UPDATE_GIT_ARGS=(
    -C "${SLOTH_PATH:-${DOTLY_PATH:-}}"
  )
fi
export SLOTH_DEFAULT_GIT_HTTP_URL SLOTH_DEFAULT_GIT_SSH_URL SLOTH_DEFAULT_REMOTE SLOTH_DEFAULT_BRANCH SLOTH_DEFAULT_URL SLOTH_UPDATE_GIT_ARGS
############## End of needed variables ##############

#;
# sloth_update::sloth_repository_set_ready()
# Default repository initilisation and first fetch if is not ready to have updates
# @return void
#"
# TODO Cleanup in production
sloth_update::sloth_repository_set_ready() {
  # if [[ -z "${SLOTH_UPDATE_GIT_ARGS[*]:-}" || ${#SLOTH_UPDATE_GIT_ARGS[@]} -eq 0 ]]; then
  #   SLOTH_UPDATE_GIT_ARGS=(
  #     -C "${SLOTH_PATH:-${DOTLY_PATH:-}}"
  #   )
  # fi
  log::note "Setting .Sloth as repository with args: \`${SLOTH_UPDATE_GIT_ARGS[*]:-no arguments provided}\`"

  log::note "Checking if current .Sloth directory is a repository and have a remote called \`${SLOTH_DEFAULT_REMOTE:-origin}\`"
  if ! git::is_in_repo "${SLOTH_UPDATE_GIT_ARGS[@]}" || ! git::check_remote_exists "${SLOTH_DEFAULT_REMOTE:-origin}" "${SLOTH_UPDATE_GIT_ARGS[@]}"; then
    log::note "Initilizing .Sloth as repository"
    git::init_repository_if_necessary "${SLOTH_DEFAULT_URL:-${SLOTH_DEFAULT_GIT_SSH_URL:-git+ssh://git@github.com:gtrabanco/sloth.git}}" "${SLOTH_DEFAULT_REMOTE:-origin}" "${SLOTH_DEFAULT_BRANCH:-master}" "${SLOTH_UPDATE_GIT_ARGS[@]}"
  fi

  # Set head branch
  log::note "Setting head branch as \`${SLOTH_DEFAULT_REMOTE:-origin}\`" 1>&2
  git::git "${SLOTH_UPDATE_GIT_ARGS[@]}" remote set-head "${SLOTH_DEFAULT_REMOTE:-origin}" --auto 1>&2 || true

  # Automatic convert windows git crlf to lf
  log::note "Automatic CRLF to LF"
  git::git "${SLOTH_UPDATE_GIT_ARGS[@]}" config --bool core.autcrl false 1>&2 || true

  # Track default branch
  log::note "Tracking default branch \`${SLOTH_DEFAULT_BRANCH:-master}\`"
  git::clone_track_branch "${SLOTH_DEFAULT_REMOTE:-origin}" "${SLOTH_DEFAULT_BRANCH:-master}" "${SLOTH_UPDATE_GIT_ARGS[@]:-}" 1>&2 || true

  # Unshallow by the way
  log::note "Unshallow repository (by the way)"
  git::git "${SLOTH_UPDATE_GIT_ARGS[@]}" fetch --unshallow 1>&2 || true
}

#;
# sloth_update::get_current_version()
# Get which one is your current version or latest downloaded version
# @return string|void
#"
sloth_update::get_current_version() {
  git::git "${SLOTH_UPDATE_GIT_ARGS[@]:-}" describe --tags --abbrev=0 2> /dev/null
}

#;
# sloth_update::get_latest_version()
# Get the latest stable version available
# @return string
#"
sloth_update::get_latest_stable_version() {
  local latest_version
  git::remote_latest_tag_version "${SLOTH_DEFAULT_URL:-${SLOTH_DEFAULT_GIT_SSH_URL:-git+ssh://git@github.com:gtrabanco/sloth.git}}" "v*.*.*" "${SLOTH_UPDATE_GIT_ARGS[@]:-}"
}

#;
# sloth_update::local_sloth_repository_can_be_updated()
# Check if we should update based on the configured SLOTH_UPDATE_VERSION and SLOTH_ENV. This takes care in production about pending commits and clean working directory as described in the comments for SLOTH_DEV
# @return boolean
#"
sloth_update::local_sloth_repository_can_be_updated() {
  local IS_WORKING_DIRECTORY_CLEAN=false HAS_UNPUSHED_COMMITS=false

  if [[ -f "${SLOTH_FORCE_CURRENT_VERSION_FILE:-$DOTFILES_PATH/.sloth_force_current_version}" ]]; then
    return 1
  fi

  git::is_clean "${SLOTH_UPDATE_GIT_ARGS[@]:-}" && IS_WORKING_DIRECTORY_CLEAN=true

  # If remote exists locally
  if git::check_remote_exists "${SLOTH_DEFAULT_REMOTE:-origin}" "${SLOTH_UPDATE_GIT_ARGS[@]:-}"; then
    git::git "${SLOTH_UPDATE_GIT_ARGS[@]:-}" branch --set-upstream-to="${SLOTH_DEFAULT_REMOTE:-origin}/${SLOTH_DEFAULT_BRANCH:-master}" "${SLOTH_DEFAULT_BRANCH:-master}" &> /dev/null
    git::check_branch_is_ahead "${SLOTH_DEFAULT_BRANCH:-master}" "${SLOTH_UPDATE_GIT_ARGS[@]:-}" && HAS_UNPUSHED_COMMITS=true
  fi

  if $IS_WORKING_DIRECTORY_CLEAN && ! $HAS_UNPUSHED_COMMITS; then
    # Can safely update, clean working directory and not unpushed commits
    return 0
  fi

  return 1
}

#;
# sloth_update::should_be_updated()
# Check if we should update sloth based on the selected and current version
# @return boolean
#"
sloth_update::should_be_updated() {
  local -r latest_version=$(sloth_update::get_latest_stable_version)
  local -r current_version=$(sloth_update::get_current_version)
  local -r latest_available_local_version=$(git::git "${SLOTH_UPDATE_GIT_ARGS[@]:-}" tag | sort -Vr | head -n1)

  if [[ -f "${SLOTH_UPDATE_AVAILABE_FILE:-"$DOTFILES_PATH/.sloth_update_available"}" ]]; then
    return 0
  fi

  # Check if currently we want to pin to a fixed version but is more recent that current version
  if platform::semver get major "$SLOTH_UPDATE_VERSION" &> /dev/null; then
    # Different than current version & is not available in local & remote latest version is greater or equal that SLOTH_UPDATE_VERSION (pinned version)
    if
      [[ 
        $current_version != "$SLOTH_UPDATE_VERSION" &&
        $(platform::semver compare "$latest_available_local_version" "$SLOTH_UPDATE_VERSION") -lt 0 &&
        $(platform::semver compare "$latest_version" "$SLOTH_UPDATE_VERSION") -gt -1 ]]
    then
      touch "$DOTFILES_PATH/.sloth_update_available"
      return 0
    elif [[ $(platform::semver compare "$latest_version" "$SLOTH_UPDATE_VERSION") -eq -1 ]]; then
      output::error "Pinned version \`SLOTH_UPDATE_VERSION=$SLOTH_UPDATE_VERSION\` is not a valid version"
      return 1
    else
      return 1
    fi
  fi

  # Stable channel must check with remote latest version
  if [[ $SLOTH_UPDATE_VERSION == "stable" && $(platform::semver compare "$latest_version" "$current_version") -eq 1 ]]; then
    "$DOTFILES_PATH/.sloth_update_available"
    return 0
  fi

  # Latest channel
  if [[ $SLOTH_UPDATE_VERSION == "latest" ]] && git::check_branch_is_behind "${SLOTH_DEFAULT_BRANCH:-master}" "${SLOTH_UPDATE_GIT_ARGS[@]:-}"; then
    return 0
  fi

  return 1
}

#;
# sloth_update::exists_migration_script()
# Check if the migration script exists for current latest or selected version
# @return boolean
#"
sloth_update::exists_migration_script() {
  local -r updated_version="$(sloth_update::get_current_version)"

  [[ -x "${SLOTH_PATH:-${DOTLY_PATH:-}}/migration/${updated_version}" || -f "${SLOTH_PATH:-${DOTLY_PATH:-}}/symlinks/${updated_version}.yaml" || -f "${SLOTH_PATH:-${DOTLY_PATH:-}}/symlinks/${updated_version}.yml" ]]
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
  local remote url default_branch head_branch force_update updated_version
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
  sloth_update::sloth_repository_set_ready || true

  # Remote exists?
  ! git::check_remote_exists "$remote" "${SLOTH_UPDATE_GIT_ARGS[@]:-}" 1>&2 && output::error "Remote \`${remote}\` does not exists" && return 20

  # Get remote HEAD branch
  head_branch="$(git::get_remote_head_upstream_branch "$remote" "${SLOTH_UPDATE_GIT_ARGS[@]:-}")"
  if [[ -z "$head_branch" ]]; then
    git::set_remote_head_upstream_branch "$remote" "$default_remote_branch" "${SLOTH_UPDATE_GIT_ARGS[@]:-}"
    head_branch="$(git::get_remote_head_upstream_branch "$remote" "${SLOTH_UPDATE_GIT_ARGS[@]:-}")"

    [[ -z "$head_branch" ]] && output::error "Remote \`${remote}\` does not have a default branch and \`${default_branch}\` could not be set" && return 30
  fi

  git::pull_branch "$remote" "$head_branch" "${SLOTH_UPDATE_GIT_ARGS[@]:-}" 1>&2 && output::solution "Repository has been updated" || return 40

  git::git "${SLOTH_UPDATE_GIT_ARGS[@]:-}" checkout --force "${SLOTH_GITMODULES_BRANCH:-${SLOTH_DEFAULT_BRANCH:-master}}"
  git::git "${SLOTH_UPDATE_GIT_ARGS[@]:-}" reset --hard HEAD "${SLOTH_GITMODULES_BRANCH:-${SLOTH_DEFAULT_BRANCH:-master}}"

  touch "${SLOTH_UPDATED_FILE:-$DOTFILES_PATH/.sloth_updated}"
  rm -f "${SLOTH_UPDATE_AVAILABE_FILE:-"$DOTFILES_PATH/.sloth_update_available"}"
}

#;
# sloth_update::gracefully()
# Full update sloth function that can be used to update in sync or async mode. Already up to date return non exit code but not create .sloth_updated file.
# @return 0 if all ok, error code otherwise 10, in no force means has pending commits or dirty directory, 20 remote does not exists or can't be set, no default branch, 40 git pull fails
#"
sloth_update::gracefully() {
  local exit_code=0
  # Check if is in development mode but is dirty or has unpushed commits
  if
    [[ -f "${SLOTH_FORCE_CURRENT_VERSION_FILE:-$DOTFILES_PATH/.sloth_force_current_version}" ]] ||
      [[ ${SLOTH_ENV:0:1} =~ ^[dD]$ ]] && ! sloth_update::local_sloth_repository_can_be_updated
  then
    return 1
  fi

  # Make some checks and put the repository ready to make an update
  sloth_update::sloth_repository_set_ready || true

  if ! sloth_update::should_be_updated; then
    # Already up to date
    return
  fi

  # Force update
  sloth_update::sloth_update_repository "${SLOTH_DEFAULT_REMOTE:-origin}" "${SLOTH_GITMODULES_URL:-${SLOTH_DEFAULT_GIT_SSH_URL:-git+ssh://git@github.com:gtrabanco/sloth.git}}" "${SLOTH_DEFAULT_BRANCH:-master}" true || exit_code=$?

  return $exit_code
}

#;
# sloth_update::async()
# Update .Sloth in async mode
# @return void
#"
sloth_update::async() {
  local status=1

  if [[ -f "${SLOTH_UPDATED_FILE:-$DOTFILES_PATH/.sloth_updated}" ]]; then
    # status=1 # Already updated

    # Latest version does not have a migration script
    if ! sloth_update::exists_migration_script; then
      rm -f "${SLOTH_UPDATED_FILE:-$DOTFILES_PATH/.sloth_updated}"
    fi

    output::empty_line
    output::write "     🥳 🎉 🍾      SLOTH UPDATED     🥳 🎉 🍾  "
    output::empty_line

  elif [[ -f "${SLOTH_UPDATE_AVAILABE_FILE:-"$DOTFILES_PATH/.sloth_update_available"}" ]]; then
    status=0

  elif
    ! [[ ${SLOTH_ENV:0:1} =~ ^[dD]$ ]] &&
      [[ -d "${SLOTH_PATH:-${DOTLY_PATH:-}}" ]] &&
      files::check_if_path_is_older "${SLOTH_PATH:-${DOTLY_PATH:-}}" "${SLOTH_AUTO_UPDATE_PERIOD_IN_DAYS:-7}" "days"
  then
    if
      sloth_update::local_sloth_repository_can_be_updated &&
        sloth_update::should_be_updated
    then
      status=0
      touch "${SLOTH_UPDATE_AVAILABE_FILE:-"$DOTFILES_PATH/.sloth_update_available"}"
      output::empty_line
      output::write " ---------------------------------------------"
      output::write "|  🥳🎉🍾 NEW SLOTH VERSION AVAILABLE 🥳🎉🍾  |"
      output::write " ---------------------------------------------"
      output::empty_line
    fi
  fi

  return $status
}

#;
# sloth_update::async_success()
# Async update success
# @return void
#"
sloth_update::async_success() {
  local status=0

  if [[ -f "${SLOTH_UPDATE_AVAILABE_FILE:-"$DOTFILES_PATH/.sloth_update_available"}" ]]; then
    case "$(str::to_lower "${SLOTH_AUTO_UPDATE_MODE:-auto}")" in
      "silent")
        rm -f "${SLOTH_UPDATE_AVAILABE_FILE:-"$DOTFILES_PATH/.sloth_update_available"}"
        sloth_update::gracefully 2>&1 | log::file "Updating .Sloth" || status=$?

        [[ $status -eq 0 ]] && sloth_update::exists_migration_script &&
          output::answer ".Sloth was updated but there are a migration script that must be executed" &&
          output::empty_line

        return $status
        ;;
      "info")
        output::empty_line
        output::write " ---------------------------------------------"
        output::write "|  🥳🎉🍾 NEW .Sloth VERSION AVAILABLE 🥳🎉🍾  |"
        output::write " ---------------------------------------------"
        output::empty_line
        ;;
      "prompt")
        # Nothing to do here
        ;;
      *) # auto
        output::answer "🚀 Updating .Sloth Automatically"
        rm -f "${SLOTH_UPDATE_AVAILABE_FILE:-"$DOTFILES_PATH/.sloth_update_available"}"
        sloth_update::gracefully 2>&1 | log::file "Updating .Sloth" || status=$?
        if [[ $status -eq 0 ]]; then

          if sloth_update::exists_migration_script; then
            output::answer ".Sloth was updated but there are a migration script that must be executed. Restart your terminal or execute \`dot core migration --updated\`"
          else
            output::solution ".Sloth was updated."
          fi
        else
          output::error ".Sloth was not updated, something was wrong. Check log using \`dot core debug\`"
        fi
        ;;
    esac
  fi
}
