#!/usr/bin/env bash

snap_title='🦜 Snap'
SNAP_DUMP_FILE_PATH="$DOTFILES_PATH/os/linux/snap/$(hostname -s).txt"

snap::is_available() {
  platform::command_exists snap
}

snap::package_exists() {
  [[ -n "${1:-}" ]] && snap::is_available && snap info "$1" &> /dev/null
}

snap::is_installed() {
  [[ -n "${1:-}" ]] && snap::is_available && ! snap list "$1" 2>&1 | grep -q ^'error'
}

snap::install() {
  [[ -n "${1:-}" ]] && snap::is_available && snap install -y "${1:-}"
}

snap::uninstall() {
  [[ -n "${1:-}" ]] && snap::is_available && sudo snap remove "$@"
}

snap::cleanup() {
  output::write "If snap cleanup fails, try to close first all snaps"
  # Credits: https://www.debugpoint.com/2021/03/clean-up-snap/
  snap list --all | awk '/disabled/{print $1, $3}' | while read -r snapname revision; do
    snap remove "$snapname" --revision="$revision"
  done
}

snap::dump() {
  SNAP_DUMP_FILE_PATH="${1:-$SNAP_DUMP_FILE_PATH}"

  if package::common_dump_check snap "$SNAP_DUMP_FILE_PATH"; then
    snap list | tail -n +2 | awk '{ print $1 }' | tee "$SNAP_DUMP_FILE_PATH" | log::file "Exporting ${snap_title} containers"

    return 0
  fi

  return 1
}

snap::import() {
  SNAP_DUMP_FILE_PATH="${1:-$SNAP_DUMP_FILE_PATH}"

  if package::common_import_check snap "$SNAP_DUMP_FILE_PATH"; then
    output::write "🚀 Importing SNAP from '$HOMEBREW_DUMP_FILE_PATH'"
    xargs -I_ sudo snap install "_" < "$SNAP_DUMP_FILE_PATH" | log::file "Importing ${snap_title} containers"
  fi
}
