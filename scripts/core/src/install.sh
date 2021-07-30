#!/bin/user/env bash

SLOTH_GITHUB_REPOSITORY_NEW_ISSUE_URL="https://github.com/gtrabanco/sloth/issues/new/choose"

custom::install() {
  if [[ $# -eq 0 ]]; then
    return
  fi

  package::is_installed "$1" || package::install "$1" | log::file "Installing package $1" || output::error "Package $1 could not be installed"
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

    registry::install "clt"
    registry::install "brew"
  fi

  mkdir -p "$HOME/bin"

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

  output::answer "Installing needed gnu packages"
  custom::install clt curl git coreutils findutils gnu-sed

  # To make CI Checks faster this packages are only installed if not CI
  if [[ "${DOTLY_ENV:-PROD}" != "CI" ]]; then
    custom::install gnutls gnu-tar gnu-which gawk grep

    output::answer "Installing other needed packages"
    custom::install make bash zsh bash-completion@2 zsh-completions python3-pip

    # Adds brew zsh and bash to /etc/shells
    HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
    if ${SETUP_ZSH_AND_BASH_IN_SHELLS:-false} && [[ -d "$HOMEBREW_PREFIX" && -x "${HOMEBREW_PREFIX}/bin/zsh" ]] && ! grep -q "^${HOMEBREW_PREFIX}/bin/zsh$" "/etc/shells" && sudo -v -B; then
      sudo bash -c "echo '${HOMEBREW_PREFIX}/bin/zsh' | tee -a /etc/shells &> /dev/null"
    fi

    if ${SETUP_ZSH_AND_BASH_IN_SHELLS:-false} && [[ -d "$HOMEBREW_PREFIX" && -x "${HOMEBREW_PREFIX}/bin/bash" ]] && ! grep -q "^${HOMEBREW_PREFIX}/bin/bash$" "/etc/shells" && sudo -v -B; then
      sudo bash -c "echo '${HOMEBREW_PREFIX}/bin/bash' | tee -a /etc/shells &> /dev/null"
    fi

    output::answer "Installing mas"
    custom::install mas

    # Required packages output an error
    if ! package::is_installed "docpars" || ! package::is_installed "python3-pip" || ! package::is_installed "python-yq"; then
      output::error "🚨 Any of the following packages \`docpars\`, \`python3\`, \`python-yq\` could not be installed, and are required"
    fi
  fi
}

install_linux_custom() {
  local any_pkgmgr=false package_manager
  local -r LINUX_PACKAGE_MANAGERS=(apt dnf pacman yum brew)

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
    platform::command_exists brew && any_pkgmgr=true
  fi

  if ! $any_pkgmgr; then
    output::error "🚨 No package manager detected, and brew not installed, maybe your package manager is not in .Sloth."
    output::empty_line
    output::write "Possible solutions are"
    output::write "  1. Install manually first the following linux packages:"
    output::answer "\`build-essential coreutils findutils python3 python3-testresources python3-pip bash zsh fzf\`"
    output::answer "After intall those packages and have available python3 and pip3, execute:"
    output::answer "\`python3 -m pip install --upgrade setuptools\` and \`dot package add python-yq\`"
    output::write "  2. Make an issue telling your os and which package manager are you using."
    output::answer "${SLOTH_GITHUB_REPOSITORY_NEW_ISSUE_URL}"
    output::empty_line

    if [[ "${DOTLY_ENV:-PROD}" != "CI" ]]; then
      output::anser "Continue with cargo"
      custom::install cargo cargo-update docpars hyperfine
    fi

    return
  fi

  output::answer "Installing Linux Packages"
  custom::install curl git build-essential coreutils findutils

  # To make CI Checks faster this packages are only installed if not CI
  if [[ "${DOTLY_ENV:-PROD}" != "CI" ]]; then
    custom::install bash zsh python3-pip python-yq jq

    # Required packages output an error
    if ! package::is_installed "docpars" || ! package::is_installed "python3-pip" || ! package::is_installed "python-yq"; then
      output::error "🚨 Any of the following packages \`docpars\`, \`python3-pip\`, \`python-yq\` could not be installed, and are required"
    fi
  fi
}
