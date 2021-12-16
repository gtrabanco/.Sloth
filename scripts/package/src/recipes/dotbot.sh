#!/usr/bin/env bash
#? Author:
#?   Gabriel Trabanco Llano <gtrabanco@users.noreply.github.com>
#? v1.0.0

DOTBOT_GIT_REPOSITORY_URL="https://github.com/anishathalye/dotbot"
DOTBOT_GIT_REPOSITORY="anishathalye/dotbot"
DOTBOT_GIT_DEFAULT_REMOTE="origin"
DOTBOT_GIT_DEFAULT_BRANCH="${DOTBOT_GIT_DEFAULT_BRANCH:-}"

DOTBOT_BASEDIR="${DOTBOT_BASEDIR:-${DOTFILES_PATH:-${HOME}/.dotfiles}}"
DOTBOT_SUBMODULE_DIR="${DOTBOT_SUBMODULE_DIR:-modules/dotbot}"
DOTBOT_INSTALL_METHOD="${DOTBOT_INSTALL_METHOD:-module}"

dotbot::install_from() {
  if
    [[ 
      -n "${DOTBOT_BASEDIR:-}" &&
      -d "${DOTBOT_BASEDIR}" &&
      "${DOTBOT_INSTALL_METHOD:-module}" == "module" ]] &&
      git::is_in_repo -C "$DOTBOT_BASEDIR"
  then
    printf "module"
  else
    printf "package"
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

dotbot::get_dotbot_path_git_install() {
  if [[ -n "${DOTBOT_BASEDIR:-}" && -d "${DOTBOT_BASEDIR}" ]]; then
    printf "%s" "${DOTBOT_BASEDIR}/${DOTBOT_SUBMODULE_DIR}"
  else
    printf "%s" "${HOME}/.dotbot"
  fi
}

dotbot::get_local_lastest_commit_sha() {
  git::git -C "$(dotbot::get_dotbot_path_git_install)" rev-parse "$(dotbot::get_remote_default_branch)"
}

dotbot::update_local_repository() {
  local -r dotbot_path="$(dotbot::get_dotbot_path_git_install)"
  local -r default_branch="$(dotbot::get_remote_default_branch)"

  git::init_repository_if_necessary "${DOTBOT_GIT_REPOSITORY_URL:-https://github.com/anishathalye/dotbot}" "${DOTBOT_GIT_DEFAULT_REMOTE:-origin}" "$default_branch" -C "$dotbot_path" &>/dev/null 
  git::pull_branch "${DOTBOT_GIT_DEFAULT_REMOTE:-origin}" "$default_branch" -C "$dotbot_path" &>/dev/null 
}

dotbot::install_from_git() {
  local submodule default_branch
  if [[ $* == *"--force"* ]]; then
    # output::answer "\`--force\` option is ignored with this recipe"
    dotbot::force_install "$@" && return
  else
    local -r local_repository="${DOTBOT_BASEDIR:-${DOTFILES_PATH:-${HOME}/.dotfiles}}"
    local -r dotbot_dir="$(dotbot::get_dotbot_path_git_install)"

    if git::is_in_repo -C "$local_repository"; then
      submodule="${dotbot_dir//$local_repository\//}"
      default_branch="$(dotbot::get_remote_default_branch)"

      dot::load_library "${SLOTH_PATH}/scripts/symlinks/src/dotbot.sh"

      git::git -C "$local_repository" submodule add -b "${default_branch:-master}" --force "${DOTBOT_GIT_REPOSITORY_URL:-https://github.com/anishathalye/dotbot}" "${submodule:-modules/dotbot}" &>/dev/null 
      git::git -C "$local_repository" config -f .gitmodules submodule."${submodule:-modules/dotbot}".ignore dirty &>/dev/null || true
      dotbot::update_local_repository || true
      git::git -C "$local_repository" checkout "$default_branch" &>/dev/null

      DOTBOT_DEFAULT_YAML_FILE_NAME="${DOTBOT_DEFAULT_YAML_FILE_NAME:-conf.yaml}"
      DOTBOT_DEFAULT_YAML_FILES_BASE_PATH="${DOTBOT_DEFAULT_YAML_FILES_BASE_PATH:-${DOTBOT_BASE_PATH:-${DOTFILES_PATH:-${HOME}/.dotfiles}}/symlinks}"
      local -r dotbot_yaml_file="$(dotbot::yaml_file_path "$DOTBOT_DEFAULT_YAML_FILE_NAME" "$DOTBOT_DEFAULT_YAML_FILES_BASE_PATH")"
      touch "$dotbot_yaml_file"
      mkdir -p "${HOME}/bin"

      if [[ -f "$dotbot_yaml_file" ]]; then
        dotbot::add_or_edit_json_value_to_directive "link" "~/bin/dotbot" "$(dotbot::get_dotbot_path_git_install)/bin/dotbot" "$dotbot_yaml_file" &>/dev/null || true
      fi
      ln -fs "$(dotbot::get_dotbot_path_git_install)/bin/dotbot" "${HOME}/bin/dotbot" &> /dev/null
    else
      git::git clone "$DOTBOT_GIT_REPOSITORY_URL" "${HOME}/.dotbot" || true
      dotbot::update_local_repository || true

      mkdir -p "${HOME}/bin"
      ln -s "${HOME}/.dotbot/bin/dotbot" "${HOME}/bin/dotbot" &> /dev/null
    fi
  fi

  dotbot::is_installed && return

  return 1
}

dotbot::uninstall_submodule() {
  dot::load_library "${SLOTH_PATH}/scripts/symlinks/src/dotbot.sh"

  local -r local_repository="${DOTBOT_BASEDIR:-${DOTFILES_PATH:-${HOME}/.dotfiles}}"
  local -r dotbot_dir="$(dotbot::get_dotbot_path_git_install)"
  local -r submodule="${dotbot_dir//$local_repository\//}"

  DOTBOT_DEFAULT_YAML_FILE_NAME="${DOTBOT_DEFAULT_YAML_FILE_NAME:-conf.yaml}"
  DOTBOT_DEFAULT_YAML_FILES_BASE_PATH="${DOTBOT_DEFAULT_YAML_FILES_BASE_PATH:-${DOTBOT_BASE_PATH:-${DOTFILES_PATH:-${HOME}/.dotfiles}}/symlinks}"
  local -r dotbot_yaml_file="$(dotbot::yaml_file_path "$DOTBOT_DEFAULT_YAML_FILE_NAME" "$DOTBOT_DEFAULT_YAML_FILES_BASE_PATH")"
  touch "$dotbot_yaml_file"

  git::git -C "$local_repository" submodule deinit -f -- "$submodule" &>/dev/null
  git::git -C "$local_repository" rm -f "$submodule" &>/dev/null
  git::git -C "$local_repository" commit -m "Removed dotbot submodule" &>/dev/null
  rm -rf "${local_repository}/.git/modules/${submodule}" "${HOME}/bin/dotbot"
  dotbot::delete_by_key_in "link" "~/bin/dotbot" "$dotbot_yaml_file" &>/dev/null || true
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

dotbot::is_installed() {
  command -v dotbot &> /dev/null || [[ -d "$(dotbot::get_dotbot_path_git_install)" && -x "${HOME}/bin/dotbot" ]]
}

dotbot::install() {
  if [[ " $* " == *" --force "* ]]; then
    dotbot::force_install "$@"
  else
    dotbot::is_installed && return
  fi

  case "$(dotbot::install_from)" in
    "package")
      dotbot::install_as_package "$@"
      ;;
    "module")
      dotbot::install_from_git "$@"
      ;;
    *)
      output::error "dotbot could not be installed"
      return 1
      ;;
  esac
}

# OPTIONAL
dotbot::uninstall() {
  [[ -d "$(dotbot::get_dotbot_path_git_install)" ]] && rm -rf "$(dotbot::get_dotbot_path_git_install)"

  ! dotbot::is_installed && return

  local -r package_manager="$(package::which_package_manager dotbot)"

  if [[ "$package_manager" != "registry" ]]; then
    package::uninstall dotbot "$package_manager"
  fi

  if [[ -d "${HOME}/.dotbot" ]]; then
    rm -rf "${HOME}/.dotbot"
  fi

  if [[ -n "$(git::get_submodule_property "$(dotbot::get_dotbot_path_git_install)/.gitmodules" "url")" ]]; then
    dotbot::uninstall_submodule
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
  [[ "$(package::which_package_manager "dotbot")" != registry ]] && return 1 # Use the package manager used to install

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
    dotbot_bin="$(dotbot::get_dotbot_path_git_install)/bin/dotbot"

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