#!/usr/bin/env bash
#? Author:
#?   Gabriel Trabanco Llano <gtrabanco@users.noreply.github.com>
#? This file contains instrucctions to install the package pipx-dev
#? v1.0.0

# REQUIRED FUNCTION
pipx-dev::is_installed() {
  platform::command_exists pipx
}

# REQUIRED FUNCTION
pipx-dev::install() {
  # Install dependency
  ! registry::is_installed python3-pip &&
    registry::install python3-pip

  ! registry::is_installed python3-pip &&
    return 1

  if [[ $* == *"--force"* ]]; then
    # output::answer "\`--force\` option is ignored with this recipe"
    pipx-dev::force_install "$@" && return
  else
    pip install --user pipx --upgrade --dev

    if pipx-dev::is_installed; then
      python3 -m pipx ensurepath
      output::solution "pipx installed" &&
        return
    fi
  fi

  output::error "pipx could not be installed"
  return 1
}
