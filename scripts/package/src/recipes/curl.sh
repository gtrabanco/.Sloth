#!/usr/bin/env bash

curl::install() {
  if [[ ${SLOTH_OS:-$(uname -s)} == "Linux" ]]; then
    script::depends_on build-essential
  fi

  package::install "curl" "auto" "${1:-}"

  curl::is_installed
}

curl::is_installed() {
  platform::command_exists curl
}