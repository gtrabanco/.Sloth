#!/usr/bin/env bash

apt::install() {
  platform::command_exists apt-get && sudo apt-get -y install "$@"
}

apt::is_installed() {
  #apt list -a "$@" | grep -q 'installed'
  [[ -n "${1:-}" ]] && platform::command_exists dpkg && dpkg -l | awk '{print $2}' | grep -q ^"${1:-}"$
}
