#!/usr/bin/env bash

volta_title='⚡︎⚔️ volta'

volta::is_available() {
  platform::command_exists volta
}

volta::dump() {
  VOLTA_DUMP_FILE_PATH="${1:-$VOLTA_DUMP_FILE_PATH}"

  if package::common_dump_check volta "$VOLTA_DUMP_FILE_PATH"; then
    output::write "🚀 Starting VOLTA packages from '$VOLTA_DUMP_FILE_PATH'"
    volta list all --format plain | awk '{print $2}' | tee "$VOLTA_DUMP_FILE_PATH" | log::file "Exporting $volta_title packages"

    return 0
  fi

  return 1
}

volta::import() {
  VOLTA_DUMP_FILE_PATH="${1:-$VOLTA_DUMP_FILE_PATH}"

  if package::common_import_check volta "$VOLTA_DUMP_FILE_PATH"; then
    output::write "🚀 Importing VOLTA packages from '$VOLTA_DUMP_FILE_PATH'"
    xargs -I_ volta install "_" <"$VOLTA_DUMP_FILE_PATH" | log::file "Importing $volta_title packages"

    return 0
  fi

  return 1
}
