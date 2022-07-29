#!/usr/bin/env bash
#shellcheck disable=SC2128

[[ -z "${SCRIPT_LOADED_LIBS[*]:-}" ]] && SCRIPT_LOADED_LIBS=()

dot::list_contexts() {
  dotly_contexts=$(command -p find "${SLOTH_PATH:-${DOTLY_PATH:-}}/scripts" -maxdepth 1 -type d,l -print0 2> /dev/null | command -p xargs -0 -I _ command -p basename _)

  [[ -n "${DOTFILES_PATH:-}" ]] &&
    dotfiles_contexts=$(command -p find "${DOTFILES_PATH:-}/scripts" -maxdepth 1 -type d,l -print0 2> /dev/null | command -p xargs -0 -I _ command -p basename _)

  echo "$dotly_contexts" "${dotfiles_contexts:-}" | grep -v "^_" | sort -u
}

dot::list_context_scripts() {
  local core_contexts dotfiles_contexts
  local -r context="${1:-}"

  if [[ -n "$context" ]]; then
    readarray -t core_contexts < <(command -p find "${SLOTH_PATH:-${DOTLY_PATH:-}}/scripts/$context" -mindepth 1 -maxdepth 1 -not -iname "_*" -not -iname ".*" -type f -print0 2> /dev/null | command -p xargs -0 -I _ echo _)
    [[ -n "${DOTFILES_PATH:-}" ]] &&
      readarray -t dotfiles_contexts < <(command -p find "${DOTFILES_PATH:-}/scripts/$context" -mindepth 1 -maxdepth 1 -not -iname "_*" -not -iname ".*" -type f -print0 2> /dev/null | command -p xargs -0 -I _ echo _)

    printf "%s\n%s\n" "${core_contexts[@]}" "${dotfiles_contexts[@]}" | command -p sort -u
  fi
}

dot::list_scripts() {
  _list_scripts() {
    local -r scripts=$(dot::list_context_scripts "${1:-}" | command -p xargs -I_ echo "dot ${1:-} _")

    echo "$scripts"
  }

  dot::list_contexts | coll::map _list_scripts
}

dot::list_scripts_path() {
  local core_contexts dotfiles_contexts

  readarray -t core_contexts < <(command -p find "${SLOTH_PATH:-${DOTLY_PATH:-}}/scripts" -mindepth 2 -maxdepth 2 -not -iname "_*" -not -iname ".*" -type f -print0 2> /dev/null | command -p xargs -0 -I _ echo _)
  [[ -n "${DOTFILES_PATH:-}" ]] &&
    readarray -t dotfiles_contexts < <(command -p find "${DOTFILES_PATH:-}/scripts" -mindepth 2 -maxdepth 2 -not -iname "_*" -not -iname ".*" -type f -print0 2> /dev/null | command -p xargs -0 -I _ echo _)

  printf "%s\n%s\n" "${core_contexts[@]}" "${dotfiles_contexts[@]}" | command -p sort -u
}

dot::fzf_view_doc() {
  case $# in
    2)
      local -r context="${1:-}"
      local -r script="${2:-}"
      ;;
    1)
      if [[ -x "$1" ]]; then
        local -r context="$(basename "$(dirname "${1:-}")")"
        local -r script="$(basename "$1")"
      else
        local -r context="$(echo "$1" | awk '{print $1}')"
        local -r script="$(echo "$1" | awk '{print $2}')"
      fi
      ;;
    *)
      return
      ;;
  esac

  if
    [[ 
      -x "${SLOTH_PATH:-${DOTLY_PATH:-/dev/null}}/scripts/${context}/${script}" ||
      -x "${DOTFILES_PATH:-/dev/null}/scripts/${context}/${script}" ]]
  then

    "${SLOTH_PATH:-${DOTLY_PATH:-}}/bin/dot" "$context" "$script" --help
  fi
}

dot::get_script_path() {
  [[ -n "${script_full_path:-}" ]] && command -p dirname "$script_full_path" && return
  #shellcheck disable=SC2164
  echo "$(
    cd -- "$(command -p dirname "$0")" > /dev/null 2>&1
    pwd -P
  )"
}

dot::get_full_script_path() {
  [[ -n "${script_full_path:-}" ]] && echo "$script_full_path" && return

  #shellcheck disable=SC2164
  echo "$(
    cd -- "$(command -p dirname "$0")" > /dev/null 2>&1
    pwd -P
  )/$(command -p basename "$0")"
}

# Old name: dot::get_script_src_path
# If you find any old name replace by
# new one:
dot::load_library() {
  local lib lib_path lib_paths lib_full_path
  lib="${1:-}"
  lib_full_path=""

  if [[ -n "${lib:-}" ]]; then
    lib_paths=()

    # If defined a context to find for a library or any valid path
    # else current context
    if [[ -n "${2:-}" ]]; then
      # Context
      lib_paths+=(
        "${DOTFILES_PATH:-/dev/null}/scripts/$2/src"
        "${SLOTH_PATH:-${DOTLY_PATH:-}}/scripts/$2/src"
      )

      # Valid path
      [[ -d "$2" ]] && lib_paths+=("$2")
    else
      # Current context src
      lib_paths+=(
        "$(dot::get_script_path)/src"
      )
    fi

    # Finally core library
    lib_paths+=(
      "${SLOTH_PATH:-${DOTLY_PATH:-}}/scripts/core/src"
    )

    # Full path library is preferred
    if [[ "${lib:0:1}" == "/" && -f "$lib" ]]; then
      lib_full_path="$lib"
    else
      for lib_path in "${lib_paths[@]}"; do
        [[ -f "$lib_path/$lib" ]] &&
          lib_full_path="$lib_path/$lib" &&
          break

        [[ -f "$lib_path/$lib.sh" ]] &&
          lib_full_path="$lib_path/$lib.sh" &&
          break
      done
    fi

    # Library loading
    if [[ -n "${lib_full_path:-}" ]] && [[ -r "${lib_full_path:-}" ]]; then
      if ! array::exists_value "${lib_full_path:-}" "${SCRIPT_LOADED_LIBS[@]:-}"; then
        #shellcheck disable=SC1090
        . "$lib_full_path"
        SCRIPT_LOADED_LIBS+=(
          "$lib_full_path"
        )
      fi

      return 0
    else
      output::error "🚨 Library loading error with: \"${lib_full_path:-No lib path found}\""
      exit 4
    fi
  fi

  # No arguments
  return 1
}

dot::_escape_dotfiles_paths() {
  local escaped_path
  local -r to_escape_path="${1:-$(< /dev/stdin)}"
  escaped_path="${to_escape_path//${SLOTH_PATH:-${DOTLY_PATH:-}}/\${SLOTH_PATH:-\${DOTLY_PATH\}\}}"
  escaped_path="${escaped_path//${DOTFILES_PATH:-}/\${DOTFILES_PATH\}}"
  printf $'%s\0' "${escaped_path//$HOME/\${HOME\}}"

  if [ $# -gt 1 ]; then
    dot::_escape_dotfiles_paths "${@:2}"
  fi
}

dot::check_is_same_path() {
  local -r path1="${1:-}"
  local -r path2="${2:-}"

  [[ -n "${path1:-}" && -n "${path2:-}" ]] && [[ "$(command -p readlink -f "$path1")" == "$(command -p readlink -f "$path2")" ]]

  if [ $# -gt 2 ]; then
    dot::check_is_same_path "$path1" "${@:3}"
  fi
}

#;
#; dot::create_path_file <...path>
#;
#; Add a path to the PATH environment variable to the bottom.
#;
dot::create_path_file() {
  if [ $# -gt 0 ]; then
    printf $'export path=(\n'
    printf $'  "%s"\n' "$@" | uniq | dot::_escape_dotfiles_paths | xargs -0 -I _ printf $'%s\n' _
    printf $')\n'
  else
    printf $'export path=()\n'
  fi
}

#;
# dot::add_to_path_file()
# Add a path to paths file
# @param string $1 Position to add the path is optional for add in bottom
# @param array $@ Paths to add.
# @return boolean
#"
dot::add_to_path_file() {
  #shellcheck disable=SC1091
  . "${DOTFILES_PATH}/shell/exports.sh"
  case "$1" in
    "top" | "--top" | "-t")
      echo "top"
      #shellcheck disable=SC2154
      dot::create_path_file "${@:2}" "${path[@]}" | tee "${DOTFILES_PATH}/shell/paths.sh" > /dev/null 2>&1
      return
      ;;
    "bottom" | "--bottom" | "-b")
      if [[ $1 == "bottom" ]]; then
        shift
      fi
      ;;
  esac
  dot::create_path_file "${path[@]}" "${@}" | tee "${DOTFILES_PATH}/shell/paths.sh" > /dev/null 2>&1
}

#;
#; dot::remove_from_path_file <...path>
#;
#; Remove a path from the PATH environment variable.
#;
dot::remove_from_path_file() {
  #shellcheck disable=SC1091
  . "${DOTFILES_PATH}/shell/paths.sh"
  local -a new_path=()

  for path in "${path[@]}"; do
    # check if the path is not the one we want to remove
    # Will check also for some values with env vars like $HOME
    if dot::check_is_same_path "$path" "$@"; then
      new_path+=("$path")
    fi
  done
  dot::create_path_file "${new_path[@]}" | tee "${DOTFILES_PATH}/shell/exports.sh" > /dev/null 2>&1
}
