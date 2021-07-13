#!/usr/bin/env bash

# Usage: array::* "${arr1[@]}" "${arr2[@]}"
array::union() { echo "${@}" | tr ' ' '\n' | sort | uniq; }
array::disjunction() { echo "${@}" | tr ' ' '\n' | sort | uniq -u; }
array::difference() { echo "${@}" | tr ' ' '\n' | sort | uniq -d; }
array::exists_value() {
  local value array_value
  value="${1:-}"
  shift

  for array_value in "$@"; do
    [[ "$array_value" == "$value" ]] && return 0
  done

  return 1
}

# Always define a variable called uniq_values
# eval $(array::uniq_ordered "${myarr[@]}")
# printf "%s\n" "${uniq_values[@]}"
array::uniq_unordered() {
  local uniq_values item

  # Variable declarations
  declare -a uniq_values=()

  if [[ $# -gt 0 ]]; then
    for item in "$@"; do
      ! array::exists_value "$item" "${uniq_values[@]}" && uniq_values+=("$item")
    done
  fi

  declare -p uniq_values
}

if ! type readarray &> /dev/null; then
  # Very minimal readarray implementation using read. Does NOT work with lines that contain double-quotes due to eval()
  # https://stackoverflow.com/a/64793921
  readarray() {
    local cmd opt t v=readarray
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -h | --help)
          echo "minimal substitute readarray for older bash"
          exit
          ;;
        -r)
          shift
          opt="$opt -r"
          ;;
        -t)
          shift
          #shellcheck disable=SC2034
          t=1
          ;;
        -u)
          shift
          if [ -n "$1" ]; then
            opt="$opt -u $1"
            shift
          fi
          ;;
        *)
          if [[ "$1" =~ ^[A-Za-z_]+$ ]]; then
            v="$1"
            shift
          else
            echo -en "${C_BOLD}${C_RED}Error: ${C_RESET}Unknown option: '$1'\n" 1>&2
            exit
          fi
          ;;
      esac
    done
    cmd="read $opt"
    eval "$v=()"
    while IFS= eval "$cmd line"; do
      #shellcheck disable=SC2001
      line=$(echo "$line" | sed -e "s#\([\"\`]\)#\\\\\1#g")
      eval "${v}+=(\"$line\")"
    done
  }
fi
