#!/usr/bin/env bash

snap_title='🦜 Snap'

snap::is_available() {
  platform::command_exists snap
}

snap::package_exists() {
  [[ -n "${1:-}" ]] && snap::is_available && snap info "$1" &>/dev/null
}

snap::is_installed() {
  [[ -n "${1:-}" ]] && snap::is_available && ! snap list "$1" 2>&1 | grep -q ^'error'
}

snap::install() {
  [[ -n "${1:-}" ]] && snap::is_available && snap install -y "${1:-}"
}

snap::dump() {
  SNAP_DUMP_FILE_PATH="${1:-$SNAP_DUMP_FILE_PATH}"

  if package::common_dump_check snap "$SNAP_DUMP_FILE_PATH"; then
    output::write "🚀 Starting SNAP dump to '$SNAP_DUMP_FILE_PATH'"
    snap list | tail -n +2 | awk '{ print $1 }' | tee "$SNAP_DUMP_FILE_PATH" | log::file "Exporting $snap_title containers"

    return 0
  fi

  return 1
}

snap::import() {
  SNAP_DUMP_FILE_PATH="${1:-$SNAP_DUMP_FILE_PATH}"

  if package::common_import_check snap "$SNAP_DUMP_FILE_PATH"; then
    output::write "🚀 Importing SNAP from '$HOMEBREW_DUMP_FILE_PATH'"
    xargs -I_ sudo snap install "_" <"$SNAP_DUMP_FILE_PATH" | log::file "Importing $snap_title containers"
  fi
}
