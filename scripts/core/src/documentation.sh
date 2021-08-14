#!/usr/bin/env bash

docs::parse() {
  docs::parse_script "$0" "$@"
}

docs::parse_script() {
  local -r script_path="${1:-}"
  shift
  if ! platform::command_exists docpars; then
    output::error "You need to have docpars installed in order to use dotly"
    output::solution "Run this command to install it:"
    output::solution "DOTLY_INSTALLER=true dot package add docpars"

    exit 1
  elif [[ ! -f "${script_path}" ]]; then
    output::error "The given script does not exists"
    exit 1
  fi

  eval "$(docpars -h "$(grep "^##?" "${script_path}" | cut -c 5-)" : "$@")"
}

docs::parse_script_version() {
  local -r SCRIPT_FULL_PATH="${1:-}"

  [[ ! -f "$SCRIPT_FULL_PATH" ]] && return 1
  awk '/SCRIPT_VERSION[=| ]"?(.[^";]*)"?;?$/ {gsub(/[=|"]/, " "); print $NF}' "$SCRIPT_FULL_PATH" | sort -Vr | head -n1
}
