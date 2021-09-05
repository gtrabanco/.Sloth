#!/usr/bin/env bash

zimfw::is_installed() {
  [[ -d "${SLOTH_PATH:-${DOTLY_PATH:-}}/modules/zimfw/" ]] && command -v git &> /dev/null
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
  git::remote_latest_tag_version 'git@github.com:zimfw/zimfw.git' 'v*.*.*'
}

zimfw::title() {
  echo -n "ZIM:FW"
}
