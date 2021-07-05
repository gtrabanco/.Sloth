#!/usr/bin/env bash

#shellcheck disable=2034
yum_title='YUM'

yum::is_available() {
  platform::command_exists yum
}

yum::install() {
  platform::command_exists yum && yes | sudo yum install "$@"
}

yum::is_installed() {
  local package
  if [[ $# -gt 1 ]]; then
    for package in "$@"; do
      if platform::command_exists yum &&
        ! sudo yum list --installed | grep -q "$package"; then
        return 1
      fi
    done

    return 0
  else
    [[ -n "${1:-}" ]] && platform::command_exists yum && sudo yum list --installed | grep -q "$2"
  fi
}
