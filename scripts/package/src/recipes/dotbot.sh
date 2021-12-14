#!/usr/bin/env bash
#? Author:
#?   Gabriel Trabanco Llano <gtrabanco@users.noreply.github.com>
#? v1.0.0

DOTBOT_GIT_REPOSITORY_URL="https://github.com/anishathalye/dotbot"
DOTBOT_GIT_REPOSITORY="anishathalye/dotbot"
DOTBOT_GIT_DEFAULT_REMOTE="origin"
DOTBOT_GIT_DEFAULT_BRANCH="${DOTBOT_GIT_DEFAULT_BRANCH:-}"
DOTBOT_GIT_SUBMODULE="modules/dotbot"

dotbot::get_dotbot_path() {
  if [[ -n "${DOTFILES_PATH}" && -d "$DOTFILES_PATH" ]]; then
    printf "%s" "${DOTFILES_PATH}/${DOTBOT_GIT_SUBMODULE}"
  else
    printf "%s" "${HOME}/.dotbot"
  fi
}

dotbot::get_repository_tag_version() {
  git::remote_latest_tag_version "${DOTBOT_GIT_REPOSITORY_URL:-https://github.com/anishathalye/dotbot}" "v*.*.*"
}

dotbot::get_remote_default_branch() {
  if [[ -n "$DOTBOT_GIT_DEFAULT_BRANCH" ]]; then
    printf "%s" "$DOTBOT_GIT_DEFAULT_BRANCH"
  else
    github::get_api_url "${DOTBOT_GIT_REPOSITORY:-anishathalye/dotbot}" | github::curl | jq -r '.default_branch' || true
  fi
}

dotbot::get_remote_latest_commit_sha() {
  local -r default_branch="$(dotbot::get_remote_default_branch)"
  {
    [[ -n "$default_branch" ]] && github::get_api_url "${DOTBOT_GIT_REPOSITORY:-anishathalye/dotbot}" "commits/${default_branch}" | jq -r '.sha' 2> /dev/null
  } || true
}

dotbot::get_local_lastest_commit_sha() {
  git::git -C "$(dotbot::get_dotbot_path)" rev-parse "$(dotbot::get_remote_default_branch)"
}

dotbot::update_local_repository() {
  local -r dotbot_path="$(dotbot::get_dotbot_path)"
  local -r default_branch="$(dotbot::get_remote_default_branch)"

  git::init_repository_if_necessary "${DOTBOT_GIT_REPOSITORY_URL:-https://github.com/anishathalye/dotbot}" "${DOTBOT_GIT_DEFAULT_REMOTE:-origin}" "$default_branch" -C "$dotbot_path"
  git::pull_branch "${DOTBOT_GIT_DEFAULT_REMOTE:-origin}" "$default_branch" -C "$dotbot_path"
}

dotbot::is_installed() {
  command -v dotbot &>/dev/null || [[ -d "$(dotbot::get_dotbot_path)" && -x "${HOME}/bin/dotbot" ]] || package::which_package_manager "dotbot" &> /dev/null
}

dotbot::install_from_git() {
  local submodule
  if [[ $* == *"--force"* ]]; then
    # output::answer "\`--force\` option is ignored with this recipe"
    dotbot::force_install "$@" && return
  else
    submodule="$(dotbot::get_dotbot_path)"

    if [[ "$submodule" == "${HOME}/.dotbot" ]]; then
      git::git clone "$DOTBOT_GIT_REPOSITORY_URL" "${HOME}/.dotbot" || true
      dotbot::update_local_repository || true
      mkdir -p "${HOME}/bin"
      ln -s "$(dotbot::get_dotbot_path)/bin/dotbot" "${HOME}/bin/dotbot"
    else
      submodule="${submodule//${DOTFILES_PATH}\//}"
      submodule="${submodule//${HOME}\//}"
      git::git -C "$(dotbot::get_dotbot_path)" submodule update --init --recursive >&2 || true
      git::git -C "$(dotbot::get_dotbot_path)" config -f .gitmodules submodule."$submodule".ignore dirty >&2 || true
      ln -s "$(dotbot::get_dotbot_path)/bin/dotbot" "${HOME}/bin/dotbot"
    fi
  fi

  dotbot::is_installed && return

  return 1
}

dotbot::install_as_package() {
  if [[ $* == *"--force"* ]]; then
    # output::answer "\`--force\` option is ignored with this recipe"
    dotbot::force_install "$@" && return
  else
    # Install using a package manager, in this case auto but you can choose brew, pip...
    package::install dotbot "pip" "${1:-}"

    ! package::is_installed dotbot &&
      package::install dotbot auto

    dotbot::is_installed && return
  fi

  output::error "dotbot could not be installed"
  return 1
}

dotbot::install() {
  if [[ -d "$(dotbot::get_dotbot_path)" ]]; then
    dotbot::install_from_git "$@"
  else
    dotbot::install_as_package "$@"
  fi
}

# OPTIONAL
dotbot::uninstall() {
  [[ -d "$(dotbot::get_dotbot_path)" ]] && rm -rf "$(dotbot::get_dotbot_path)"

  ! dotbot::is_installed && return

  local -r package_manager="$(package::which_package_manager dotbot)"

  if [[ "$package_manager" != "registry" ]]; then
    package::uninstall dotbot "$package_manager"
  fi

  ! dotbot::is_installed && return

  return 1
}

# OPTIONAL
dotbot::force_install() {
  local _args
  mapfile -t _args < <(array::substract "--force" "$@")

  dotbot::uninstall "${_args[@]}"
  dotbot::install "${_args[@]}"
  dotbot::is_installed "${_args[@]}"
}

# ONLY REQUIRED IF YOU WANT TO IMPLEMENT AUTO UPDATE WHEN USING `up` or `up registry`
# Description, url and versions only be showed if defined
dotbot::is_outdated() {
  [[ "$(package::which_package_manager "dotbot")" != registry ]] && return # Use the package manager used to install

  [[ $(dotbot::get_local_lastest_commit_sha) != $(dotbot::get_remote_latest_commit_sha) ]]
}

dotbot::upgrade() {
  if [[ "$(package::which_package_manager "dotbot")" == registry ]]; then
    dotbot::update_local_repository
  fi
}

dotbot::description() {
  printf "%s" "Dotbot is a tool that bootstraps your dotfiles (it's a [Dot]files [bo]o[t]strapper, get it?). It does less than you think, because version control systems do more than you think."
}

dotbot::url() {
  printf "%s" "${DOTBOT_GIT_REPOSITORY_URL:-https://github.com/anishathalye/dotbot}"
}

dotbot::version() {
  # Get the current installed version
  local dotbot_bin
  dotbot_bin="$(command -v dotbot)"

  [[ -z "$dotbot_bin" ]] &&
    dotbot::is_installed &&
    dotbot_bin="$(dotbot::get_dotbot_path)/bin/dotbot"

  [[ -x "$dotbot_bin" ]] &&
    "$dotbot_bin" --version &&
    return

  return 1
}

dotbot::latest() {
  if dotbot::is_outdated; then
    local -r dotbot_remote_tag="$(dotbot::get_repository_tag_version)"
    local -r local_dotbot_version="$(dotbot::version)"

    if [[ $local_dotbot_version != "$dotbot_remote_tag" ]]; then
      echo -n "$dotbot_remote_tag"
    else
      echo -n "$(dotbot::get_remote_latest_commit_sha)"
    fi
  else
    dotbot::version
  fi
}

dotbot::title() {
  echo -n "🤖 dotbot"
}