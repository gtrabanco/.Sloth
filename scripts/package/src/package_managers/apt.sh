#!/usr/bin/env bash

apt_title='@ APT'

apt::is_available() {
  platform::command_exists apt-get && platform::command_exists dpkg
}

apt::install() {
  platform::command_exists apt-get && sudo apt-get -y install "$@"
}

apt::is_installed() {
  #apt list -a "$@" | grep -q 'installed'
  [[ -n "${1:-}" ]] && platform::command_exists dpkg && dpkg -l | awk '{print $2}' | grep -q ^"${1:-}"$
}

apt::dump() {
  APT_DUMP_FILE_PATH="${1:-$APT_DUMP_FILE_PATH}"

  if package::common_dump_check apt "$APT_DUMP_FILE_PATH"; then
    output::write "🚀 Starting APT dump to '$APT_DUMP_FILE_PATH'"
    apt-mark showmanual | tee "$APT_DUMP_FILE_PATH" | log::file "Exporting $apt_title packages"

    return 0
  fi

  return 1
}

apt::import() {
  APT_DUMP_FILE_PATH="${1:-$APT_DUMP_FILE_PATH}"

  if package::common_import_check apt "$APT_DUMP_FILE_PATH"; then
    output::write "🚀 Importing APT from '$HOMEBREW_DUMP_FILE_PATH'"
    xargs sudo apt-get install -y <"$APT_DUMP_FILE_PATH" | log::file "Importing $apt_title packages"
  fi
}
