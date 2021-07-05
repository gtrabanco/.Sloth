#!/usr/bin/env bash

cargo_title='📦 Cargo'
#shellcheck disable=SC2034
rustup_title='☢️ Rust compiler'

cargo::is_available() {
  platform::command_exists cargo
}

cargo::is_installed() {
  [[ -n "${1:-}" ]] && cargo::is_available && cargo install --list | grep -E '^[a-z0-9_-]+ v[0-9.]+:$' | cut -f1 -d ' ' | grep -q "^${1}$"
}

cargo::package_exists() {
  [[ -n "${1:-}" ]] && cargo::is_available && cargo search "$1" | awk '{print $1}' | grep -v '\.\.\.' | xargs -0 | grep -q "^${1}$"
}

cargo::install() {
  platform::command_exists cargo && cargo install "$@"
}

cargo::update_all() {
  platform::command_exists rustup && rustup update
  cargo::is_available && cargo install --list | grep -E '^[a-z0-9_-]+ v[0-9.]+:$' | cut -f1 -d' ' | xargs -n1 cargo install
}

cargo::is_installed() {
  local package
  if [[ $# -gt 1 ]]; then
    for package in "$@"; do
      if ! platform::command_exists cargo &&
        cargo install --list | grep -q "$package"; then
        return 1
      fi
    done

    return 0
  else
    [[ -n "${1:-}" ]] && platform::command_exists cargo && cargo install --list | grep -q "${1:-}"
  fi
}

cargo::dump() {
  CARGO_DUMP_FILE_PATH="${1:-$CARGO_DUMP_FILE_PATH}"

  if package::common_dump_check cargo "$CARGO_DUMP_FILE_PATH"; then
    cargo install --list | grep -E '^[a-z0-9_-]+ v[0-9.]+:$' | cut -f1 -d' ' | tee "$CARGO_DUMP_FILE_PATH" | log::file "Exporting $cargo_title packages"

    return 0
  fi

  return 1
}

cargo::import() {
  CARGO_DUMP_FILE_PATH="${1:-$VOLTA_DUMP_FILE_PATH}"

  if package::common_import_check cargo "$CARGO_DUMP_FILE_PATH"; then
    xargs -I_ cargo install <"$CARGO_DUMP_FILE_PATH" | log::file "Importing $cargo_title packages"

    return 0
  fi

  return 1
}
