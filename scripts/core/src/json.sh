#!/usr/bin/env bash

json::to_yaml() {
  if [[ -t 0 ]]; then
    [[ -f "${1:-}" ]] && yq --yaml-output < "$1"
  else
    yq --yaml-output < /dev/stdin
  fi
}

json::is_valid() {
  if [[ -t 0 ]]; then
    [[ -n "${1:-}" && -f "$1" ]] && yq -p=json -e '.' < "$1" > /dev/null 2>&1
  else
    yq -p=json -e '.' < /dev/stdin > /dev/null 2>&1
  fi
}
