#!/bin/user/env bash

install_macos_custom() {
  brew::install() {
    if [[ $# -eq 0 ]]; then
      return
    elif [[ $# -gt 1 ]]; then
      "$0" "${@:2}"
    fi

    brew list "$1" 2>/dev/null || brew install "$1" | log::file "Installing brew $1"
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
    brew::install gnutls gnu-tar gnu-which gawk grep make bat hyperfine
  fi

  output::answer "Installing mas"
  brew::install mas
}

install_linux_custom() {
  echo
}
