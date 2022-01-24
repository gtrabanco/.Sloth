#!/usr/bin/env bash
#? Author:
#?   Gabriel Trabanco Llano <gtrabanco@users.noreply.github.com>
#? This file contains instrucctions to install the package pipx
#? v1.0.0

# REQUIRED FUNCTION
pipx::is_installed() {
  platform::command_exists pipx
}

# REQUIRED FUNCTION
pipx::install() {
  # Install dependency
  ! registry::is_installed python3-pip &&
    registry::install python3-pip

  ! registry::is_installed python3-pip &&
    return 1

  if [[ " $* " == *" --force "* ]]; then
    # output::answer "\`--force\` option is ignored with this recipe"
    pipx::force_install "$@" && return
  else
    # Install using a package manager, in this case auto but you can choose brew, pip...
    package::install pipx auto "$@"

    if pipx::is_installed pipx; then
      case $(package::which_package_manager "pipx") in
        pip | pip3)
          python3 -m pipx ensurepath
          ;;
        *)
          pipx ensurepath
          ;;
      esac
      package::install ensurepath
      output::solution "pipx installed" &&
        return
    fi
  fi

  output::error "pipx could not be installed"
  return 1
}

# OPTIONAL
pipx::uninstall() {
  package::uninstall pipx pip3
}

# OPTIONAL
pipx::force_install() {
  local _args
  mapfile -t _args < <(array::substract "--force" "$@")

  pipx::uninstall "${_args[@]}"
  pipx::install "${_args[@]}"

  pipx::is_installed "${_args[@]}"
}
