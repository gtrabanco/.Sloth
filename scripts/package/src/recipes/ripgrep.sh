#!/usr/bin/env bash

ripgrep::is_installed() {
  platform::command_exists ripgrep
}

ripgrep::install() {
  script::depends_on cargo

  package::install "ripgrep" "cargo"

  ripgrep::is_installed || return 1
}

ripgrep::uninstall() {
  package::uninstall "ripgrep" "cargo"
}
