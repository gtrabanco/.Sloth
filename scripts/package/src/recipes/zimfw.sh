#!/usr/bin/env bash

zimfw::is_installed() {
  [[ -d "${SLOTH_PATH:-$DOTLY_PATH}/modules/zimfw/" ]] && command -v git &> /dev/null
}

zimfw::is_outdated() {
  [[ $(platform::semver_compare "$(zimfw::latest)" "$(zimfw::version)") -gt 0 ]]
}

zimfw::upgrade() {
  zsh -c ". \"${HOME}/.zshrc\"; zimfw clean; zimfw update; zimfw upgrade; zimfw compile"
}

zimfw::description() {
  echo "Zim is a Zsh configuration framework with blazing speed and modular extensions"
}

zimfw::url() {
  echo "https://zimfw.sh"
}

zimfw::version() {
  zsh -c ". \"${HOME}/.zshrc\"; zimfw version"
}

zimfw::latest() {
  command git -C "${SLOTH_PATH:-$DOTLY_PATH}/modules/zimfw/" ls-remote --tags --refs origin 'v*' 2> /dev/null | awk '{print $NF}' | sed 's#refs/tags/v##g' | sort -r | head -n1
}

zimfw::title() {
  echo -n "ZIM:FW"
}
