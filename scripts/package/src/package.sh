#!/usr/bin/env bash
export PACKAGE_MANAGERS_SRC=(
  "${SLOTH_PATH:-$DOTLY_PATH}/scripts/package/src/package_managers"
  "${DOTFILES_PATH}/package_managers"
  "${PACKAGE_MANAGERS_SRC[@]}"
)

package::load_manager() {
  local package_manager_file_path
  local -r package_manager="${1:-}"

  package_manager_file_path="$(package::manager_exists "$package_manager")"

  if [[ -n "$package_manager_file_path" ]]; then
    dot::load_library "$package_manager_file_path"
  else
    output::error "🚨 Package Manager \`$package_manager\` does not exists"
    exit 4
  fi
}

package::manager_exists() {
  local package_manager_src
  local -r package_manager="${1:-}"
  for package_manager_src in "${PACKAGE_MANAGERS_SRC[@]}"; do
    [[ -f "${package_manager_src}/${package_manager}.sh" ]] &&
      echo "${package_manager_src}/${package_manager}.sh" &&
      return
  done
}

package::choose_manager() {
  local package_manager="none"
  if [[ -n "${FORCED_PKGMGR:-}" ]]; then
    package_manager="$FORCED_PKGMGR"
  elif platform::is_macos; then
    for package_manager in brew mas ports cargo none; do
      if platform::command_exists "$package_manager"; then
        break
      fi
    done
  else
    if platform::command_exists apt-get && platform::command_exists dpkg; then
      package_manager="apt"
    else
      for package_manager in dnf yum brew pacman cargo none; do
        if platform::command_exists "$package_manager"; then
          break
        fi
      done
    fi
  fi

  echo "$package_manager"
}

package::command() {
  local package_manager
  local -r command="$1"
  local -r args=("${@:2}")

  # Package manager
  if [[ -n "${FORCED_PKGMGR:-}" && "$FORCED_PKGMGR" != "none" ]]; then
    package_manager="$FORCED_PKGMGR"
  else
    package_manager="$(package::choose_manager)"
  fi

  if [[ "$package_manager" == "none" ]] ||
    [[ -z "$(package::manager_exists "$package_manager")" ]]; then
    return 1
  fi

  package::load_manager "$package_manager"

  # If function does not exists for the package manager it will return 0 (true) always
  if [[ "$command" == "install" ]]; then
    declare -F "$package_manager::$command" &>/dev/null && "$package_manager::$command" "${args[@]}" | log::file "Trying to install ${args[*]} using $package_manager" || return
  else
    declare -F "$package_manager::$command" &>/dev/null && "$package_manager::$command" "${args[@]}" || return
  fi
}

package::is_installed() {
  [[ -z "${1:-}" ]] && return 1

  package::command is_installed "$1" ||
    registry::is_installed "$1"
}
