#!/usr/bin/env bash
#shellcheck disable=SC2034

brew::execute_from_url() {
  [[ -z "${1:-}" ]] && return 1
  if platform::command_exists curl; then
    bash < <(curl -fsSL "$1")
  elif platform::command_exists wget; then
    bash < <(wget -q0 - "$1")
  else
    script::depends_on curl

    if platform::command_exists curl; then
      brew::execute_from_url "$1"
      return $?
    else
      return 1
    fi
  fi
}

brew::install() {
  local -r brew_install_script="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

  if platform::command_exists yum; then
    if sudo -v; then
      yes | sudo yum install group 'Development tools'
      yes | sudo yum install procps-ng curl file git
      yes | sudo yum install libxcrypt-compat # needed by Fedora 30 and up
    fi
  elif platform::command_exists apt; then
    if sudo -v; then
      apt install -y build-essential procps curl file git
    fi
  elif [[ $(platform::get_arch) != "amd64" ]] && ! platform::is_macos_arm; then
    output::error "Brew is not supported"
    return 1
  fi
  brew::execute_from_url "$brew_install_script"

  if [[ -d "/home/linuxbrew/.linuxbrew" && -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
  elif [[ -d "${HOME}/.linuxbrew" && -x "${HOME}/.linuxbrew/bin/brew" ]]; then
    BREW_BIN="${HOME}/.linuxbrew/bin/brew"
  elif [[ -x "/opt/homebrew/bin/brew" ]]; then
    BREW_BIN="/opt/homebrew/bin/brew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    BREW_BIN="/usr/local/bin/brew"
  elif command -v brew &> /dev/null; then
    BREW_BIN="$(command -v brew)"
  fi

  HOMEBREW_PREFIX="$("$BREW_BIN" --prefix)"
  HOMEBREW_CELLAR="${HOMEBREW_PREFIX}/Cellar"
  HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}/Homebrew"

  PATH="${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:${PATH}"
  export PATH HOMEBREW_PREFIX HOMEBREW_CELLAR HOMEBREW_REPOSITORY
}

brew::uninstall() {
  local -r brew_uninstall_script="https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh"
  brew::execute_from_url "$brew_uninstall_script"
}

brew::is_installed() {
  if [[ -d "/home/linuxbrew/.linuxbrew" && -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
  elif [[ -d "${HOME}/.linuxbrew" && -x "${HOME}/.linuxbrew/bin/brew" ]]; then
    BREW_BIN="${HOME}/.linuxbrew/bin/brew"
  elif [[ -x "/opt/homebrew/bin/brew" ]]; then
    BREW_BIN="/opt/homebrew/bin/brew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    BREW_BIN="/usr/local/bin/brew"
  elif command -v brew &> /dev/null; then
    BREW_BIN="$(command -v brew)"
  fi

  [[ -n "$BREW_BIN" ]]
}

# Brew update is done as package manager
