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
