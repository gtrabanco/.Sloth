#!/usr/bin/env bash

if [[ -n "${PACKAGE_MANAGERS_SRC[*]:-}" ]]; then
  if
    ! array::exists_value "${SLOTH_PATH:-${DOTLY_PATH:-}}/scripts/package/src/package_managers" "${PACKAGE_MANAGERS_SRC[@]}" ||
      ! array::exists_value "${DOTFILES_PATH:-}/package/managers" "${PACKAGE_MANAGERS_SRC[@]}"
  then
    export PACKAGE_MANAGERS_SRC=(
      "${SLOTH_PATH:-${DOTLY_PATH:-}}/scripts/package/src/package_managers"
      "${DOTFILES_PATH:-}/package/managers"
      "${PACKAGE_MANAGERS_SRC[@]}"
    )
  fi
else
  export PACKAGE_MANAGERS_SRC=(
    "${SLOTH_PATH:-${DOTLY_PATH:-}}/scripts/package/src/package_managers"
    "${DOTFILES_PATH:-}/package/managers"
  )
fi

if [[ -z "${SLOTH_PACKAGE_MANAGERS_PRECEDENCE:-}" ]]; then
  if platform::is_macos; then
    export SLOTH_PACKAGE_MANAGERS_PRECEDENCE=(
      brew cargo pip volta npm mas
    )
  else
    export SLOTH_PACKAGE_MANAGERS_PRECEDENCE=(
      apt snap brew dnf pacman yum cargo pip gem volta npm
    )
  fi
fi

#;
# package::manager_exists()
# Check if a given package manager exists in PACKAGE_MANAGERS_SRC
# @param string package_manager
# @return string|void Full path to package manager or nothing
#"
package::manager_exists() {
  local package_manager_src
  local -r package_manager="${1:-}"
  for package_manager_src in "${PACKAGE_MANAGERS_SRC[@]}"; do
    [[ -f "${package_manager_src}/${package_manager}.sh" ]] &&
      echo "${package_manager_src}/${package_manager}.sh" &&
      return
  done
}

#;
# package::load_manager()
# Load a package manager library if exists, if not, exit the script with a critical warning. Recommended to use first package::manager_exists() if is not critical
# @param string package_manager
# @return void
#"
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

#;
# package::get_all_package_managers()
# Output a full list of all package managers. If any param provided will list only package managers with subcommand(s) (functions)
# @param any commands command or command that must have the package managers to list them as available
#"
package::get_all_package_managers() {
  local package_manager_src package_manager command has_all

  for package_manager_src in $(find "${PACKAGE_MANAGERS_SRC[@]}" -maxdepth 1 -mindepth 1 -name "*.sh" -print0 2> /dev/null | xargs -0 -I _ echo _); do
    # Get package manager name
    #shellcheck disable=SC2030
    package_manager="$(basename "$package_manager_src")"
    package_manager="${package_manager%%.sh}"
    has_all=true

    # Check if it is a valid package manager
    [[ -z "$(package::manager_exists "$package_manager")" ]] && continue

    if [[ -n "$*" ]]; then
      for command in "$@"; do
        if ! script::function_exists "$package_manager_src" "${package_manager}::${command}"; then
          has_all=false
        fi
      done
    fi

    $has_all && echo "$package_manager"
  done
}

#;
# package::get_available_package_managers()
# Output a full list of available package managers (those with ::is_available and return success)
#"
package::get_available_package_managers() {
  local package_manager_src package_manager_filename package_manager

  for package_manager_src in $(package::get_all_package_managers "is_available"); do
    package_manager_filename="$(basename "$package_manager_src")"
    package_manager="${package_manager_filename%%.sh}"

    if package::command "$package_manager" "is_available"; then
      echo "$package_manager"
    fi
  done
}

#;
# package::manager_preferred()
# Get the first avaible of the preferred package managers
# @return string package manager
#"
package::manager_preferred() {
  local all_available_pkgmgrs

  readarray -t all_available_pkgmgrs < <(package::get_available_package_managers)
  eval "$(array::uniq_unordered "${SLOTH_PACKAGE_MANAGERS_PRECEDENCE[@]}" "${all_available_pkgmgrs[@]}")"

  if [[ ${#uniq_values[@]} -gt 0 ]]; then
    echo "${uniq_values[0]}"
  fi
}

#;
# package::command_exists()
# Execute if a command (function) is defined for a given package manager
# @param string package_manager
# @param string command The function to be check
# @param string package_mananager_src Optional param to provide the package manager library (useful to avoid check if exists again)
# @return boolean
#"
package::command_exists() {
  local -r package_manager="${1:-}"
  local -r command="${2:-}"
  local -r package_command="${package_manager}::${command}"
  local -r package_manager_src="${3:-$(package::manager_exists "$package_manager")}"

  if
    [[ 
      "$package_manager" == "none" ||
      -z "$package_manager" ||
      -z "$command" ||
      ! -f "$package_manager_src" ]] ||
      ! script::function_exists "$package_manager_src" "$package_command"
  then
    return 1
  fi

  return 0
}

#;
# package::command()
# Execute if exists a function for package_manager (example: execute install command for a package manager if that function is defined for the given package manager). If execute install, the output is send also to the log.
# @param string package_manager
# @param string command The function to be executed
# @param any args Arguments for command
# @return void
#"
package::command() {
  local -r package_manager="${1:-}"
  local -r command="${2:-}"
  local -r args=("${@:3}")

  # If function does not exists for the package manager it will return 0 (true) always
  if package::command_exists "$package_manager" "${command}"; then
    package::load_manager "$package_manager"
    if [[ "$command" == "install" ]]; then
      "${package_manager}::${command}" "${args[@]:-}" 2>&1 | log::file "Installing ${args[*]} using $package_manager" || return
    elif [[ "$command" == "uninstall" ]]; then
      "${package_manager}::${command}" "${args[@]:-}" 2>&1 | log::file "Uninstalling ${args[*]} using $package_manager" || return
    else
      "${package_manager}::${command}" "${args[@]:-}"
    fi
    return $?
  fi

  return 1
}

#;
# package::managers_self_update()
# Update packages manager list of packages (no packages). Should not be a upgrade of all apps
# @param string package_manager If this value is empty update all available package managers
# @return void
#"
package::manager_self_update() {
  local package_manager="${1:-}"

  if [[ -n "$package_manager" ]]; then
    package::command_exists "$package_manager" self_update && package::command "$package_manager" self_update
  else
    for package_manager_src in $(package::get_available_package_managers); do
      [[ -n "$package_manager" ]] && package::manager_self_update "$package_manager"
    done
  fi
}

#;
# package::which_package_manager()
# Output which package manager was used to install a package
# @param string package
# @param boolean avoid_registry_check If true avoid check if package is installed with the registry
# @return boolean If package is not installed
#"
package::which_package_manager() {
  local package_manager
  local -r package_name="${1:-}"
  local -r avoid_registry_check=${2:-false}
  [[ -z "$package_name" ]] && return 1

  # Check every package manager first because maybe registry has used a package manager
  for package_manager in $(package::get_all_package_managers "is_available" "is_installed"); do
    package::command "$package_manager" "is_available" &&
      package::command "$package_manager" is_installed "$package_name" && echo "$package_manager" && return
  done

  # Because registry::is_installed is defined in core. This is a expected behavior and we do it at
  # the end because probably a package was installed with a package manager spite of being a reicpe
  if
    ! $avoid_registry_check &&
      [[ -n "$(registry::recipe_exists "$package_name")" ]] &&
      registry::command_exists "$package_name" "is_installed"
  then
    registry::is_installed "$package_name" && echo "registry" && return
    return 1
  fi

  return 1
}

#;
# package::is_installed()
# Check if a package is installed with a recipe or any of the available package managers. It does not check if a binary package_name is available
# @param string package_name
# @param string package_manager Can be "any" to use any package manager or registry (same as empty). "auto" to use any one except registry. "recipe" or "registry" are aliases. Can be any other valid package manager in 'scripts/package/src/package_managers'.
# @return boolean
#"
package::is_installed() {
  local package_manager
  local -r package_name="${1:-}"
  package_manager="${2:-}"
  [[ -z "$package_name" ]] && return 1

  # Allow to use recipe(s) instead of registry
  [[ -n "$package_manager" && $package_manager == "recipe"[s] ]] && package_manager="registry"

  # Any package manager is the same as empty package_manager
  [[ $package_manager == "any" ]] && package_manager=""

  if
    [[ -z "$package_manager" || $package_manager == "registry" ]] &&
      [[ -n "$(registry::recipe_exists "$package_name")" ]] &&
      registry::command_exists "$package_name" "is_installed"
  then
    registry::is_installed "$package_name" && return
    return 1
  elif [[ $package_manager == "auto" || -z "$package_manager" ]]; then
    package::which_package_manager "$package_name" true &> /dev/null && return 0
  elif [[ -n "$package_manager" ]]; then
    package::command_exists "$package_manager" "is_installed" && package::command "$package_manager" "is_installed" "$package_name" && return
  fi

  return 1
}

#;
# package::_install()
# "Private" function for package::install that do the repetive task of installing a package
# @param string package_manager
# @param string package
# @return boolean
#"
package::_install() {
  local package_manager package
  package_manager="${1:-}"
  package="${2:-}"

  [[ -z "$package_manager" || -z "$package" ]] && return 1
  shift 2

  if
    package::command_exists "$package_manager" "is_available" &&
      package::command_exists "$package_manager" "package_exists" &&
      package::command_exists "$package_manager" "is_installed" &&
      package::command_exists "$package_manager" "install" &&
      package::command "$package_manager" "is_available"
  then

    if
      package::command "$package_manager" "package_exists" "$package" &&
        package::command "$package_manager" "install" "$package" "$@"
    then
      package::command "$package_manager" "is_installed" "$package" && return
    fi

  elif
    package::command_exists "$package_manager" "is_available" &&
      package::command_exists "$package_manager" "install" &&
      package::command_exists "$package_manager" "is_installed" &&
      package::command "$package_manager" "is_available"
  then

    package::command "$package_manager" "install" "$package" "$@" &&
      package::command "$package_manager" "is_installed" &&
      return

  fi

  # Not exists or not installed
  return 1
}

#;
# package::install()
# Try to install with any available package manager, but if you provided a package manager (second param) it will only try to use that package manager. This avoids to install from registry recipe (use package::install_recipe_first).
# @param string package Package to install
# @param string package_manager Can be "any" to use any package manager or registry. "auto" to use any one except registry. "recipe" or "registry" are aliases. Can be any other valid package manager in 'scripts/package/src/package_managers'.
# @param any args Arguments for package manager wrapper
# @return boolen
#"
package::install() {
  local all_available_pkgmgrs uniq_values package_manager package
  [[ -z "${1:-}" ]] && return 1
  package="$1"
  shift
  package_manager="${1:-}"
  if [[ -n "$package_manager" ]]; then
    shift
    # Allow to use recipe(s) instead of registry
    [[ $package_manager == "recipe"[s] ]] && package_manager="registry"
    [[ $package_manager == "any" ]] && package_manager=""
  fi

  if
    [[ 
      -n "$package_manager" &&
      $package_manager != "auto" &&
      $package_manager != "registry" ]]
  then

    if [[ -n "$(package::manager_exists "$package_manager")" ]]; then
      package::_install "$package_manager" "$package" "$@" &&
        return 0
    else
      output::error "Package manager not found"
      return 1
    fi
  elif
    [[ 
      -z "$package_manager" ||
      $package_manager == "registry" ]] &&
      [[ -n "$(registry::recipe_exists "$package")" ]]
  then

    registry::install "$package" "$@" && registry::is_installed "$package" "$@" && return 0
  else
    if platform::command_exists readarray; then
      readarray -t all_available_pkgmgrs < <(package::get_available_package_managers)
    else
      #shellcheck disable=SC2207
      all_available_pkgmgrs=($(package::get_available_package_managers))
    fi
    eval "$(array::uniq_unordered "${SLOTH_PACKAGE_MANAGERS_PRECEDENCE[@]}" "${all_available_pkgmgrs[@]}")"

    # Try to install respecting package managers precedence
    for package_manager in "${uniq_values[@]}"; do
      if
        [[ -n "$(package::manager_exists "$package_manager")" ]] &&
          package::_install "$package_manager" "$package" "$@"
      then
        return 0
      fi
    done

    return 1
  fi

  return 1
}

#;
# package::uninstall()
# Uninstall the given package, if second parameter is given it will try do it with package manager
# @param string package_name
# @param string package_manager Can be "any" to use any package manager or registry. "auto" to use any one except registry. "recipe" or "registry" are aliases. Can be any other valid package manager in 'scripts/package/src/package_managers'.
# @param any args Additional arguments to be passed to uninstall function (package_manager is required then)
# @return boolean True if uninstalled and false if still installed
#"
package::uninstall() {
  local package_manager
  [[ $# -lt 1 ]] && return 1
  local -r package_name="$1"
  shift
  package_manager="${1:-}"
  if [[ -n "$package_manager" ]]; then
    shift
    # Allow to use recipe(s) instead of registry
    [[ $package_manager == "recipe"[s] ]] && package_manager="registry"
    [[ $package_manager == "any" ]] && package_manager=""
  fi

  if [[ -z "$package_manager" || $package_manager == "registry" ]]; then
    local -r recipe_path="$(registry::recipe_exists "$package_name")"
    if
      [[ -n "$recipe_path" ]] &&
        registry::command_exists "$package_name" "uninstall"
    then
      registry::uninstall "$package_name" "$@" && ! registry::is_installed "$package_name" && return 0
    fi
  else
    [[ $package_manager == "auto" || -z "$package_manager" ]] && package_manager="$(package::which_package_manager "$package_name" || echo -n)"
    if
      [[ 
        -z "$package_manager" ||
        -z "$(package::manager_exists "$package_manager")" ]]
    then

      echo "Package manager $package_manager"
      # Could not determine which package manager to be used or package manager not exists
      return 1
    fi

    if package::command_exists "$package_manager" "uninstall"; then
      package::command "$package_manager" "uninstall" "$package_name" "$@" && ! package::is_installed "$package_name" && return 0
    fi
  fi

  # Recipe or package not uninstalled or does not have uninstall wrapper (function) (can happen with both package managers and registry)
  return 1
}

#;
# package::which_file()
# Askt to user for a file in given files_path and output it. Used to get the file to import packages
# @param string files_path
# @param string header For fzf
# @return string|void
#"
package::which_file() {
  local files_path header answer files
  [[ $# -lt 3 ]] && return
  files_path="$(realpath -sm "$1")"
  header="$2"

  #shellcheck disable=SC2207
  files=($(find "$files_path" -not -iname ".*" -maxdepth 1 -type f,l -print0 2> /dev/null | xargs -0 -I _ basename _ | sort -u))

  if [[ -d "$files_path" && ${#files[@]} -gt 0 ]]; then
    answer="$(printf "%s\n" "${files[@]}" | fzf -0 --filepath-word -d ',' --prompt "$(hostname -s) > " --header "$header" --preview "[[ -f $files_path/{} ]] && cat $files_path/{} || echo No import a file for this package manager")"
    [[ -f "$files_path/$answer" ]] && answer="$files_path/$answer" || answer=""
  fi
  echo "$answer"
}

#;
# package::command_dump_check()
# Used to check if package manager exists and create the subdir where the dump file will be placed
# @param string package_manager
# @param string file_path The directory where the dump file will be created
# @return void
#"
package::common_dump_check() {
  local -r package_manager="${1:-}"
  local -r file_path="${2:-}"

  if
    [[ -n "$package_manager" ]] &&
      [[ -n "$file_path" ]] &&
      [[ -n "$(package::manager_exists "$package_manager")" ]]
  then
    mkdir -p "$(dirname "$file_path")"
  fi
}

#;
# package::common_import_check()
# Check if the file exists for the given package manager
# @param string package_manager
# @param string file_path File to check if exists
# @return boolean
#"
package::common_import_check() {
  local package_manager file_path
  local -r package_manager="${1:-}"
  local -r file_path="${2:-}"

  [[ -n "$package_manager" ]] &&
    [[ -n "$file_path" ]] &&
    [[ -n "$(package::manager_exists "$package_manager")" ]] &&
    [[ -f "$file_path" ]]
}