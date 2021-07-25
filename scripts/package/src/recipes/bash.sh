#!/usr/bin/env bash

bash::is_installed() {
  if platform::is_macos; then
    package::is_installed bash auto && return 0
  else
    platform::command_exists bash && return 0
  fi

  return 1
}

bash::install() {
  if [[ $* == *"--force"* ]] && platform::command_exists brew && ! bash::is_installed; then
    brew reinstall bash
  else
    package::install bash auto
  fi

  bash::is_installed || output::error "Could not be installed" && return 1
  output::solution "Bash installed"
}

bash::uninstall() {
  if platform::command_exists brew; then
    brew uninstall --ignore-dependencies bash || true
  else
    package::uninstall bash auto
  fi

  bash::is_installed && output::error "Bash could not be installed" && return 1
  output::solution "Bash uninstalled"
}
