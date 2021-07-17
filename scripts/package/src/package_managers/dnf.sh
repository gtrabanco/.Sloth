#!/usr/bin/env bash

#shellcheck disable=SC2034
dnf_title='▣ DNF'

dnf::is_available() {
  platform::command_exists dnf
}

dnf::install() {
  dnf::is_available && sudo dnf -y install "$@"
}

dnf::uninstall() {
  [[ $# -gt 0 ]] && dnf::is_available && dnf remove "$@"
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
