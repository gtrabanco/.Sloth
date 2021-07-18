#!/usr/bin/env bash

curl::install() {
  if [[ ${SLOTH_OS:-$(uname -s)} == "Linux" ]]; then
    script::depends_on build-essential
  fi

  if command -v package::install &> /dev/null; then
    package::install "curl"
  elif [[ -x "${SLOTH_PATH:-${DOTLY_PATH:-}}/bin/dot" ]]; then
    "${SLOTH_PATH:-${DOTLY_PATH:-}}/bin/dot" package add curl
  fi

  cur::is_installed
}

curl::is_installed() {
  platform::command_exists curl
}