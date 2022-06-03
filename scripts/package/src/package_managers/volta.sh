#!/usr/bin/env bash

volta_title='⚡︎⚔️ volta'
VOLTA_DUMP_FILE_PATH="${VOLTA_DUMP_FILE_PATH:-${DOTFILES_PATH}/langs/js/volta/$(hostname -s).txt}"

volta::title() {
  echo -n "⚡︎⚔️ volta"
}

volta::is_available() {
  platform::command_exists volta
}

volta::dump() {
  VOLTA_DUMP_FILE_PATH="${1:-$VOLTA_DUMP_FILE_PATH}"

  if package::common_dump_check volta "$VOLTA_DUMP_FILE_PATH"; then
    volta list all --format plain | awk '{print $2}' | tee "$VOLTA_DUMP_FILE_PATH" | log::file "Exporting ${volta_title} packages"

    return 0
  fi

  return 1
}

volta::import() {
  VOLTA_DUMP_FILE_PATH="${1:-$VOLTA_DUMP_FILE_PATH}"
  local -r filename="${VOLTA_DUMP_FILE_PATH##*/}"
  local -r global_packages="${VOLTA_DUMP_FILE_PATH%%/"${filename}"}/volta_dependencies.txt"

  if package::common_import_check volta "$VOLTA_DUMP_FILE_PATH"; then
    if [[ $filename != "volta_dependencies.txt" ]] && [[ -r "$global_packages" ]]; then
      output::write "🚀 Importing global ${volta_title} packages from '${global_packages}'"
      xargs -I_ volta install "_" < "$global_packages" | log::file "Importing ${volta_title} packages"
    fi

    output::write "🚀 Importing ${volta_title} packages from '$VOLTA_DUMP_FILE_PATH'"
    xargs -I_ volta install "_" < "$VOLTA_DUMP_FILE_PATH" | log::file "Importing ${volta_title} packages"

    return 0
  fi

  return 1
}
