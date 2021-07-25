#!/usr/bin/env bash

zsh::is_installed() {
  if platform::is_macos; then
    package::is_installed zsh auto && return 0
  else
    platform::command_exists zsh && return 0
  fi

  return 1
}

zsh::install() {
  if [[ $* == *"--force"* ]] && platform::command_exists brew && ! zsh::is_installed; then
    brew reinstall bash
  else
    package::install zsh auto
  fi

  zsh::is_installed || output::error "Could not be installed" && return 1
  output::solution "Bash installed"
}

zsh::uninstall() {
  if platform::command_exists brew; then
    brew uninstall --ignore-dependencies bash || true
  else
    package::uninstall bash auto
  fi

  zsh::is_installed && output::error "Bash could not be installed" && return 1
  output::solution "Bash uninstalled"
}
