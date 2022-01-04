#!/usr/bin/env bash
#shellcheck disable=SC2296

command_or_package_exists() {
  platform::command_exists "$1" || package::is_installed "$1"
}

script::depends_on() {
  utils::curry command_not_exists utils::not command_or_package_exists
  non_existing_commands=$(coll::filter command_not_exists "$@")

  for non_existing_command in $non_existing_commands; do
    has_to_install=$(output::question "\`$non_existing_command\` is a dependency of this script. Should this be installed? [Y/n]")

    if output::answer_is_yes "$has_to_install"; then
      "${SLOTH_PATH:-${DOTLY_PATH:-}}/bin/dot" package add "$non_existing_command"
    else
      output::write "🙅‍ The script can't be ran without \`$non_existing_command\` being installed before."
      exit 1
    fi
  done
}

script::list_functions() {
  local -r file="${1:-}"
  if [[ ! -r "$file" ]]; then
    return
  fi

  if head -n1 "$file" | grep -q 'bash'; then
    bash -c ". \"$file\"; typeset -F" | awk '{print $3}'
  elif head -n1 "$file" | grep -q 'zsh'; then
    #shellcheck disable=SC2296
    zsh -c ". \"$file\"; print -l ${(ok)functions}"
  fi
}

script::function_exists() {
  local fns
  local -r script_path="${1:-}"
  local -r function_name="${2:-}"
  [[ -z "$script_path" || -z "$function_name" || ! -f "$script_path" ]] && return 1
  declare -a fns
  readarray -t fns < <(script::list_functions "$script_path")
  array::exists_value "$function_name" "${fns[@]}"
}
