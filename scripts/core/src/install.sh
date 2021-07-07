#!/bin/user/env bash

install_macos_custom() {
  brew::install() {
    if [[ $# -eq 0 ]]; then
      return
    fi

    brew list "$1" 2> /dev/null || brew install "$1" | log::file "Installing brew $1"
    shift

    if [[ $# -gt 0 ]]; then
      "$0" "$@"
    fi
  }

  if ! platform::command_exists brew; then
    output::error "brew not installed, installing"

    if [ "${DOTLY_ENV:-}" == "CI" ]; then
      export CI=1
    fi

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if platform::is_macos_arm; then
    export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
  else
    export PATH="$PATH:/usr/local/bin"
  fi

  mkdir -p "$HOME/bin"

  output::answer "Installing needed gnu packages"
  brew cleanup -s | log::file "Brew executing cleanup"
  brew cleanup --prune-prefix | log::file "Brew removeing dead symlinks"
  # To make CI Cheks faster avoid brew update & upgrade
  if [[ "${DOTLY_ENV:-PROD}" != "CI" ]]; then
    brew update --force | log::file "Brew update"
    brew upgrade --force | log::file "Brew upgrade current packages"
  fi

  brew::install bash zsh coreutils findutils gnu-sed

  # To make CI Checks faster this packages are only installed in production
  if [[ "${DOTLY_ENV:-PROD}" == "PROD" ]]; then
    brew::install gnutls gnu-tar gnu-which gawk grep make hyperfine
  fi

  output::answer "Installing mas"
  brew::install mas
}

install_linux_custom() {
  local -r package_manager="$(package::preferred_manager)"
  linux::install() {
    if [[ $# -eq 0 ]]; then
      return
    fi

    package::is_installed "$1" || package::install "$1" | log::file "Installing $1"
    shift

    if [[ $# -gt 0 ]]; then
      "$0" "$@"
    fi
  }

  # To make CI Cheks faster avoid package manager update & upgrade
  if [[ "${DOTLY_ENV:-PROD}" != "CI" ]]; then
    package::command_exists "$package_manager" self_update && package::command "$package_manager" self_update
  fi

  output::answer "Installing needed packages"
  linux::install bash zsh hyperfine
}
