#!/usr/bin/env bash
#shellcheck disable=SC2016

green='\033[0;32m'
normal='\033[0m'

docs::parse_version() {
  local version
  local -r SCRIPT_FULL_PATH="${1:-}"

  [[ ! -r "$SCRIPT_FULL_PATH" ]] && return 1
  version="$(command -p awk '/SCRIPT_VERSION[=| ]"?(.[^";]*)"?;?$/ {gsub(/[=|"]/, " "); print $NF}' "$SCRIPT_FULL_PATH" | command -p sort -Vr | command -p head -n1)"
  if [[ -z "$version" ]]; then
    version="$(command -p awk '/^#\?/ {sub(/^#\? ?/,"", $0); print $0}' "$SCRIPT_FULL_PATH")"
    [[ -n "$version" ]] && echo "$version" && return
  fi

  if [[ -z "${SCRIPT_NAME:-}" && "$SCRIPT_FULL_PATH" == *scripts/*/* ]]; then
    SCRIPT_NAME="${SLOTH_SCRIPT_BASE_NAME} $(command -p basename "$(dirname "$SCRIPT_FULL_PATH")") $(command -p basename "$SCRIPT_FULL_PATH")"
  elif [[ -z "${SCRIPT_NAME:-}" ]]; then
    SCRIPT_NAME="$(command -p basename "$SCRIPT_FULL_PATH")"
  fi

  [[ -n "${SCRIPT_NAME:-}" ]] && builtin echo -n "${SCRIPT_NAME} "
  builtin echo "${version:-v0.0.0}"
}

docs::parse_full_docopt() {
  command -p awk '/^##\?/ {sub(/^##\? ?/,"", $0); print $0}' < "${1:-/dev/stdin}"
}

docs::parse_docopt() {
  local doc
  doc="$(docs::parse_full_docopt < "${1:-/dev/stdin}")"
  doc="${doc//\\\$/\$}"
  doc="${doc//\\\`/\`}"

  doc="$(echo "$doc" |
    command -p awk "{ORS=(NR+1)%2==0?\"${green}\":RS}1" RS="\`" |
    command -p awk "{ORS=NR%1==0?\"${normal}\":RS}1" RS="\`")"

  echo -e "${doc//\$0/${SCRIPT_NAME:-${BASH_SOURCE[0]:-}}}"
}

docs::parse_docopt_section() {
  local -r SCRIPT_FULL_PATH="${1:-}"
  local -r SECTION_NAME="${2:-Usage}"
  [[ -n "${SCRIPT_FULL_PATH:-}" && ! -r "${SCRIPT_FULL_PATH:-}" ]] && return 1

  if [[ $SECTION_NAME == "Version" ]]; then
    docs::parse_version "$SCRIPT_FULL_PATH"
  else
    docs::parse_full_docopt "$SCRIPT_FULL_PATH" | command -p sed -n "/${SECTION_NAME}:/,/^$/ p" | command -p sed -e '1d' -e '$d'
  fi
}

docs::parse_docopt_argument() {
  local script_args show_args _arg grep_args=()
  local -r SCRIPT_FULL_PATH="${1:-}"
  [[ -n "${SCRIPT_FULL_PATH:-}" && ! -r "${SCRIPT_FULL_PATH:-}" ]] && return 1
  shift

  if [[ $# -gt 0 ]]; then
    for _arg in "$@"; do
      [[ -z "$_arg" ]] && continue
      grep_args+=(-e " ${_arg//\-/\\-}")
    done
  fi

  if [[ ${#grep_args[@]} -gt 0 ]]; then
    readarray -t script_args < <(docs::parse_docopt_section "$SCRIPT_FULL_PATH" | command -p awk '{$1="";gsub(/[\[|\]|\|]/,"",$0); gsub(/[\[]?<[^>]+>[\.]{0,3}[\]]?/,"", $0);} !/^ *$/ {print " "$0" "}' | grep "${grep_args[@]}")
  else
    readarray -t script_args < <(docs::parse_docopt_section "$SCRIPT_FULL_PATH" | command -p awk '{$1="";gsub(/[\[|\]|\|]/,"",$0); gsub(/[\[]?<[^>]+>[\.]{0,3}[\]]?/,"", $0);} !/^ *$/ {print " "$0" "}')
  fi
  show_args="${script_args[*]:-}"

  echo "$show_args"
}

# TODO
docs::parse() {
  local script_path
  script_path="${1:-}"
  local -r argc="${#BASH_SOURCE[*]}"
  [[ -f "$script_path" ]] && shift || script_path="${BASH_SOURCE[$((argc - 1))]:-}"

  if ! platform::command_exists docopts; then
    output::error "You need to have docopts installed to use \`.Sloth\`"
    output::solution "Run this command to install it:"
    output::solution "DOTLY_INSTALLER=true dot package add docopts"

    exit 1
  elif [[ ! -f "${script_path}" ]]; then
    output::error "The given script does not exists"
    exit 1

  elif [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    docs::parse_docopt "$script_path"
    exit 0
  elif [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
    docs::parse_version "$script_path"
    exit 0
  fi

  script::depends_on docopts

  eval "$(docopts -h "$(docs::parse_full_docopt "$script_path")" : "$@")"
}
