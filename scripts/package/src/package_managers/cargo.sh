#!/usr/bin/env bash

cargo_title='📦 Cargo'

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
    cargo install --list | grep -E '^[a-z0-9_-]+ v[0-9.]+:$' | cut -f1 -d' ' | tee "$CARGO_DUMP_FILE_PATH" | log::file "Exporting ${cargo_title} packages"

    return 0
  fi

  return 1
}

cargo::import() {
  CARGO_DUMP_FILE_PATH="${1:-$VOLTA_DUMP_FILE_PATH}"

  if package::common_import_check cargo "$CARGO_DUMP_FILE_PATH"; then
    xargs -I_ cargo install _ < "$CARGO_DUMP_FILE_PATH" | log::file "Importing ${cargo_title} packages"

    return 0
  fi

  return 1
}

cargo::update_all() {
  cargo::update_apps
}

cargo::update_apps() {
  local outdated_app app_new_version app_old_version

  script::depends_on cargo-update

  cargo install-update --list --git | tail -n+4 | head -n-1 | awk '{print ($4 == "No"?$0:"");}' | while read -r row; do
    [[ -z "$row" || $row == "Package" ]] && continue
    outdated_app="$(echo "$row" | awk '{print $1}')"
    app_old_version="$(echo "$row" | awk '{print $2}')"
    app_new_version="$(echo "$row" | awk '{print $3}')"

    output::write "📦 $outdated_app"
    output::write " └ $app_old_version -> $app_new_version"
    output::empty_line

    cargo install-update "$outdated_app" 2>&1 | log::file "Updating ${cargo_title} app: $outdated_app"
  done
}
