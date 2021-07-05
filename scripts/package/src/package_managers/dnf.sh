#!/usr/bin/env bash

dnf::is_available() {
  platform::command_exists dnf
}

dnf::install() {
  platform::command_exists dnf && sudo dnf -y install "$@"
}

dnf::is_installed() {
  local package
  if [[ $# -gt 1 ]]; then
    for package in "$@"; do
      if platform::command_exists rpm &&
        ! rpm -qa | grep -qw "$package"; then
        return 1
      fi
    done

    return 0
  else
    [[ -n "${1:-}" ]] && platform::command_exists rpm && rpm -qa | grep -qw "${1:-}"
  fi
}
