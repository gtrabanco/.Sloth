#!/usr/bin/env bash

cargo-update::install() {
  script::depends_on cargo

  if platform::command_exists cargo; then
    cargo install cargo-update
  else
    return 1
  fi

  cargo-update::is_installed || return 1
}

cargo-update::is_installed() {
  platform::command_exists cargo &&
    cargo install --list | grep -E '^[a-z0-9_-]+ v[0-9.]+:$' | cut -f1 -d ' ' | grep -q '^cargo-update$'
}
