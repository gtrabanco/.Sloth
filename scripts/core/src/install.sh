#!/bin/user/env bash

custom::install() {
  if [[ $# -eq 0 ]]; then
    return
  fi

  package::is_installed "$1" || package::install_recipe_first "$1" | log::file "Installing package $1" || output::error "Package $1 could not be installed"
  shift

  if [[ $# -gt 0 ]]; then
    custom::install "$@"
  fi
}

install_macos_custom() {
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
  if platform::command_exists brew; then
    brew cleanup -s | log::file "Brew executing cleanup"
    brew cleanup --prune-prefix | log::file "Brew removing dead symlinks"
  fi

  # To make CI Cheks faster avoid brew update & upgrade
  if [[ "${DOTLY_ENV:-PROD}" != "CI" ]]; then
    if platform::command_exists brew; then
      brew update --force | log::file "Brew update"
      brew upgrade --force | log::file "Brew upgrade current packages"
    else
      package::manager_self_update
    fi
  fi

  custom::install coreutils findutils gnu-sed python3

  # Python setup tools
  command -v python3 &> /dev/null && "$(command -v python3)" -m pip install --upgrade setuptools

  # To make CI Checks faster this packages are only installed if not CI
  if [[ "${DOTLY_ENV:-PROD}" != "CI" ]]; then
    custom::install bash zsh gnutls gnu-tar gnu-which gawk grep make hyperfine docpars zsh fzf python-yq jq tee realpath

    # Adds brew zsh and bash to /etc/shells
    HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
    if [[ -d "$HOMEBREW_PREFIX" && -x "${HOMEBREW_PREFIX}/bin/zsh" ]] && ! grep -q "^${HOMEBREW_PREFIX}/bin/zsh$" "/etc/shells" && sudo -v; then
      echo "${HOMEBREW_PREFIX}/bin/zsh" | sudo tee "/etc/shells"
    fi

    if [[ -d "$HOMEBREW_PREFIX" && -x "${HOMEBREW_PREFIX}/bin/bash" ]] && ! grep -q "^${HOMEBREW_PREFIX}/bin/bash$" "/etc/shells" && sudo -v; then
      echo "${HOMEBREW_PREFIX}/bin/bash" | sudo tee "/etc/shells"
    fi

    output::answer "Installing mas"
    custom::install mas
  fi
}

install_linux_custom() {
  custom::install() {
    if [[ $# -eq 0 ]]; then
      return
    fi

    package::is_installed "$1" || package::install_recipe_first "$1" | log::file "Installing package $1"
    shift

    if [[ $# -gt 0 ]]; then
      custom::install "$@"
    fi
  }

  # To make CI Cheks faster avoid package manager update & upgrade
  if [[ "${DOTLY_ENV:-PROD}" != "CI" ]]; then
    package::manager_self_update | log::file "Update package managers list of packages" || true
  fi

  output::answer "Installing needed packages"
  custom::install build-essential coreutils findutils python3-pip

  # Python setup tools
  command -v python3 &> /dev/null && "$(command -v python3)" -m pip install --upgrade setuptools

  # To make CI Checks faster this packages are only installed if not CI
  if [[ "${DOTLY_ENV:-PROD}" != "CI" ]]; then
    custom::install bash zsh hyperfine docpars zsh fzf python-yq jq tee realpath
  fi
}
