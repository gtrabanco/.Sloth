#!/usr/bin/env bash
#shellcheck disable=SC2034,SC2119,SC2120

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
    else
      return 1
    fi
  fi
}

brew::custom_path_install() {
  if platform::is_linux; then
    local -r custom_path="${1:-${HOME}/.linuxbrew}"
  elif platform::is_macos; then
    local -r custom_path="${1:-${HOME}/.homebrew}"
  else
    local -r custom_path="${1:-${HOME}/.homebrew}"
  fi

  mkdir -p "$custom_path" &&
    curl -fL https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$custom_path"
}

brew::custom_shellenv() {
  if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
  elif [[ -x "${HOME}/.linuxbrew/bin/brew" ]]; then
    BREW_BIN="${HOME}/.linuxbrew/bin/brew"
  elif [[ -x "${HOME}/.homebrew/bin/brew" ]]; then
    BREW_BIN="${HOME}/.homebrew/bin/brew"
  elif [[ -x "${HOME}/homebrew/bin/brew" ]]; then
    BREW_BIN="${HOME}/homebrew/bin/brew"
  elif [[ -x "${HOME}/.brew/bin/brew" ]]; then
    BREW_BIN="${HOME}/.brew/bin/brew"
  elif [[ -x "/opt/homebrew/bin/brew" ]]; then
    BREW_BIN="/opt/homebrew/bin/brew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    BREW_BIN="/usr/local/bin/brew"
  elif command -v brew > /dev/null 2>&1; then
    BREW_BIN="$(command -v brew)"
  elif command -vp brew > /dev/null 2>&1; then
    BREW_BIN="$(command -vp brew)"
  fi

  if [[ -n "${BREW_BIN:-}" ]]; then
    HOMEBREW_PREFIX="$("$BREW_BIN" --prefix)"
    HOMEBREW_CELLAR="${HOMEBREW_PREFIX}/Cellar"
    HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}/Homebrew"

    PATH="${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:${PATH}"
    export PATH HOMEBREW_PREFIX HOMEBREW_CELLAR HOMEBREW_REPOSITORY
  else
    unset PATH HOMEBREW_PREFIX HOMEBREW_CELLAR HOMEBREW_REPOSITORY
  fi
}

brew::install() {
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

  # On macOS we need clt
  if platform::is_macos; then
    script::depends_on clt
  fi

  # We need curl and tar always
  script::depends_on tar curl

  # Install Homebrew
  brew::custom_path_install
  # End of install

  brew::custom_shellenv
}

brew::uninstall() {
  brew::custom_shellenv

  local -r brew_uninstall_script="https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh"
  brew::execute_from_url "$brew_uninstall_script"
}

brew::is_installed() {
  brew::custom_shellenv

  [[ -n "$HOMEBREW_PREFIX" ]]
}

# Brew update is done as package manager
