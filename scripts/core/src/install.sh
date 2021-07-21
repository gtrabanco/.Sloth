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

    registry::install "brew"
  fi

  mkdir -p "$HOME/bin"

  output::answer "Installing needed gnu packages"
  if platform::command_exists brew; then
    brew cleanup -s | log::file "Brew executing cleanup"
    brew cleanup --prune-prefix | log::file "Brew removing dead symlinks"
  else
    output::answer "Brew not found"
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
    custom::install bash zsh gnutls gnu-tar gnu-which gawk grep make hyperfine docpars zsh fzf python-yq jq

    # Adds brew zsh and bash to /etc/shells
    HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
    if [[ -d "$HOMEBREW_PREFIX" && -x "${HOMEBREW_PREFIX}/bin/zsh" ]] && ! grep -q "^${HOMEBREW_PREFIX}/bin/zsh$" "/etc/shells" && sudo -v; then
      echo "${HOMEBREW_PREFIX}/bin/zsh" | sudo tee "/etc/shells" &> /dev/null
    fi

    if [[ -d "$HOMEBREW_PREFIX" && -x "${HOMEBREW_PREFIX}/bin/bash" ]] && ! grep -q "^${HOMEBREW_PREFIX}/bin/bash$" "/etc/shells" && sudo -v; then
      echo "${HOMEBREW_PREFIX}/bin/bash" | sudo tee "/etc/shells" &> /dev/null
    fi

    output::answer "Installing mas"
    custom::install mas

    # Required packages output an error
    if ! package::is_installed "docpars" || ! package::is_installed "python3" || ! package::is_installed "python-yq"; then
      output::error "🚨 Any of the following packages \`docpars\`, \`python3\`, \`python-yq\` could not be installed, and are required"
    fi

    # Solving a possibly bug updating system gems
    if platform::is_macos && platform::command_exists brew && sudo -v -B; then
      output::header "Solve failing update of gems due openssl"
      output::answer "Installing openssl again"
      brew reinstall --force openssl 1>&2 | log::file "Brew reinstall openssl"
      brew unlink openssl | log::file "Brew unlink openssl"
      brew link --link openssl | log::file "Brew link openssl"
      export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
    fi
  fi
  sudo gem update --symte | log::file "Update system gems"
}

install_linux_custom() {
  local any_pkgmgr=false package_manager
  local -r LINUX_PACKAGE_MANAGERS=(apt brew dnf pacman yum)
  custom::install() {
    if [[ $# -eq 0 ]]; then
      return
    fi

    package::is_installed "$1" || package::install_recipe_first "$1" | log::file "Installing package $1" || true
    shift

    if [[ $# -gt 0 ]]; then
      custom::install "$@"
    fi
  }

  # To make CI Cheks faster avoid package manager update & upgrade
  if [[ "${DOTLY_ENV:-PROD}" != "CI" ]]; then
    package::manager_self_update | log::file "Update package managers list of packages" || true
  fi

  # If no package manager detected try to install brew
  for package_manager in "${LINUX_PACKAGE_MANAGERS[@]}"; do
    platform::command_exists "$package_manager" && any_pkgmgr=true && break
  done

  if ! $any_pkgmgr; then
    registry::install "brew" | log::file "Trying to install brew"
  fi

  output::answer "Installing Linux Packages"
  custom::install build-essential coreutils findutils python3-pip

  # Python setup tools
  command -v python3 &> /dev/null && "$(command -v python3)" -m pip install --upgrade setuptools

  # To make CI Checks faster this packages are only installed if not CI
  if [[ "${DOTLY_ENV:-PROD}" != "CI" ]]; then
    custom::install bash zsh hyperfine docpars zsh fzf python-yq jq

    # Required packages output an error
    if ! package::is_installed "docpars" || ! package::is_installed "python3-pip" || ! package::is_installed "python-yq"; then
      output::error "🚨 Any of the following packages \`docpars\`, \`python3-pip\`, \`python-yq\` could not be installed, and are required"
    fi
  fi
}
