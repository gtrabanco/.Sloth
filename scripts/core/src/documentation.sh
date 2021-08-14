#!/usr/bin/env bash
#shellcheck disable=SC2016

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

  eval "$(docpars -h "$(command -p awk '/^##\?/ {sub(/^##\? ?/,"", $0); print $0}' < "$script_path")" : "$@")"
}

docs::parse_script_version() {
  local version
  local -r SCRIPT_FULL_PATH="${1:-}"

  [[ ! -r "$SCRIPT_FULL_PATH" ]] && return 1
  version="$(command -p awk '/SCRIPT_VERSION[=| ]"?(.[^";]*)"?;?$/ {gsub(/[=|"]/, " "); print $NF}' "$SCRIPT_FULL_PATH" | command -p sort -Vr | command -p head -n1)"

  if [[ -z "$version" ]]; then
    #command -p grep "^#?" "$SCRIPT_FULL_PATH" | command -p cut -c 4-
    command -p awk '/^#\?/ {sub(/^#\? ?/,"", $0); print $0}' "$SCRIPT_FULL_PATH"
  else
    builtin echo "$version"
  fi
}

docs::parse_docopt_section() {
  if [[ -t 0 ]]; then
    local -r SCRIPT_FULL_PATH="${1:-}"
    local -r SECTION_NAME="${2:-}"
    [[ -n "${SCRIPT_FULL_PATH:-}" && ! -r "${SCRIPT_FULL_PATH:-}" ]] && return 1
  else
    local -r SECTION_NAME="${1:-Usage}"
    local -r SCRIPT_FULL_PATH="/dev/stdin"
  fi

  if [[ $SECTION_NAME == "Version" ]]; then
    docs::parse_script_version "$SCRIPT_FULL_PATH"
  else
    #grep "^##?" "$SCRIPT_FULL_PATH" | cut -c 4- | command -p sed -n "/${section}:$/,/^$/ p" | command -p sed -e '1d' -e '$d'
    #command -p awk '/^##\?/ {sub(/^##\? ?/,"", $0); print $0}' "$SCRIPT_FULL_PATH" | command -p sed -n "/^${section}:$/,/^$/ p" | command -p sed -e '1d' -e '$d'
    command -p awk '/^##\?/ {sub(/^##\? ?/,"", $0); print $0}' <"$SCRIPT_FULL_PATH" | command -p sed -n "/${section}:/I,/^$/ p" | command -p sed -e '1d' -e '$d'
  fi
}
