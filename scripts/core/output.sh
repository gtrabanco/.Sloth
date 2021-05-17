#!/usr/bin/env bash

red='\033[0;31m'
green='\033[0;32m'
bold_blue='\033[1m\033[34m'
normal='\033[0m'

platform::is_macos() {
  [[ $(uname -s) == "Darwin" ]]
}

output::write() {
  local -r text="${*:-}"
  echo -e "$text"
}
output::answer() { output::write " > ${*:-}"; }
output::error() { output::answer "${red}${*:-}${normal}"; }
output::solution() { output::answer "${green}${*:-}${normal}"; }
output::question() {
  [[ $# -ne 2 ]] && return 1

  if [ platform::is_macos ]; then
    echo -n " > 🤔 $1: ";
    read -r "$2";
  else
    read -rp "🤔 $1: " "$2"
  fi
}
output::question_default() {
  local question default_value var_name

  [[ $# -ne 3 ]] && return 1

  question="${1:-}"
  default_value="${2:-}"
  var_name="${3:-}"

  output::question "$question? [$default_value]" "$var_name"
  eval "$var_name=\"\${$var_name:-$default_value}\""
}
output::yesno() {
  local question default PROMPT_REPLY values

  [[ $# -eq 0 ]] && return 1

  question="$1"
  default="${2:-Y}"

  if [[ "$default" =~ ^[Yy] ]]; then
    values="Y/n"
  else
    values="y/N"
  fi

  output::question "$question? [$values]" "PROMPT_REPLY"
  [[ "${PROMPT_REPLY:-$default}" =~ ^[Yy] ]]
}
output::empty_line() { echo ''; }
output::header() { output::empty_line; output::write "${bold_blue}---- ${1:-} ----${normal}"; }
