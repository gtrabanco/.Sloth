#!/usr/bin/env bash

wrapped::sed() {
  if command -v gsed &> /dev/null; then
    "$(command -v gsed)" "$@"
  elif [[ -f "/usr/local/opt/gnu-sed/libexec/gnubin/sed" ]]; then
    /usr/local/opt/gnu-sed/libexec/gnubin/sed "$@"
  elif platform::is_bsd || platform::is_macos && command -v sed &> /dev/null; then
    # Any other BSD should be added to this check
    "$(command -v sed)" '' "$@"
  elif command -v sed &> /dev/null; then
    "$(command -v sed)" "$@"
  else
    return 1
  fi
}
