#!/usr/bin/env bash
#shellcheck disable=SC2016

green='\033[0;32m'
normal='\033[0m'

docs::parse_docopt() {
  local doc
  doc="$(command -p awk '/^##\?/ {sub(/^##\? ?/,"", $0); print $0}' < "${1:-/dev/stdin}")"
  doc="${doc//\\\$/\$}"
  doc="${doc//\\\`/\`}"

  doc="$(echo "$doc" |
    command -p awk "{ORS=(NR+1)%2==0?\"${green}\":RS}1" RS="\`" |
    command -p awk "{ORS=NR%1==0?\"${normal}\":RS}1" RS="\`")"

  echo -e "$doc"
}

docs::parse_script_version() {
  local version
  local -r SCRIPT_FULL_PATH="${1:-}"

  [[ ! -r "$SCRIPT_FULL_PATH" ]] && return 1
  version="$(command -p awk '/SCRIPT_VERSION[=| ]"?(.[^";]*)"?;?$/ {gsub(/[=|"]/, " "); print $NF}' "$SCRIPT_FULL_PATH" | command -p sort -Vr | command -p head -n1)"

  if [[ -z "${SCRIPT_NAME:-}" && "$SCRIPT_FULL_PATH" == *scripts/*/* ]]; then
    SCRIPT_NAME="${SLOTH_SCRIPT_BASE_NAME} $(command -p basename "$(dirname "$SCRIPT_FULL_PATH")") $(command -p basename "$SCRIPT_FULL_PATH")"
  elif [[ -z "${SCRIPT_NAME:-}" ]]; then
    SCRIPT_NAME="$(command -p basename "$SCRIPT_FULL_PATH")"
  fi

  if [[ -z "$version" ]]; then
    #command -p grep "^#?" "$SCRIPT_FULL_PATH" | command -p cut -c 4-
    version="$(command -p awk '/^#\?/ {sub(/^#\? ?/,"", $0); print $0}' "$SCRIPT_FULL_PATH")"
  fi
  
  [[ -n "${SCRIPT_NAME:-}" ]] && builtin echo -n "${SCRIPT_NAME} "
  builtin echo "${version:-0.0.0}"
}

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

  elif [[ $1 == "--help" || $1 == "-h" ]]; then
    docs::parse_docopt "$script_path"
    exit 0
  elif [[ $1 == "--version" || $1 == "-v" ]]; then
    docs::parse_script_version "$script_path"
    exit 0
  fi

  eval "$(docpars -h "$(command -p awk '/^##\?/ {sub(/^##\? ?/,"", $0); print $0}' < "$script_path")" : "$@")"
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
    command -p awk '/^##\?/ {sub(/^##\? ?/,"", $0); print $0}' < "$SCRIPT_FULL_PATH" | command -p sed -n "/${section}:/I,/^$/ p" | command -p sed -e '1d' -e '$d'
  fi
}
