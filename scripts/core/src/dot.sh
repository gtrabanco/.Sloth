#!/usr/bin/env bash
#shellcheck disable=SC2128

[[ -z "${SCRIPT_LOADED_LIBS[*]:-}" ]] && SCRIPT_LOADED_LIBS=()

dot::list_contexts() {
  dotly_contexts=$(find "${SLOTH_PATH:-${DOTLY_PATH:-}}/scripts" -maxdepth 1 -type d,l -print0 2> /dev/null | xargs -0 -I _ basename _)
  dotfiles_contexts=$(find "${DOTFILES_PATH}/scripts" -maxdepth 1 -type d,l -print0 2> /dev/null | xargs -0 -I _ basename _)

  echo "$dotly_contexts" "$dotfiles_contexts" | grep -v "^_" | sort -u
}

dot::list_context_scripts() {
  context="$1"

  dotly_scripts=$(find "${SLOTH_PATH:-${DOTLY_PATH:-}}/scripts/$context" -maxdepth 1 -not -iname "_*" -not -iname ".*" -perm /u=x -type f,l -print0 2> /dev/null | xargs -0 -I _ basename _)
  dotfiles_scripts=$(find "${DOTFILES_PATH}/scripts/$context" -maxdepth 1 -not -iname "_*" -not -iname ".*" -perm /u=x -type f,l -print0 2> /dev/null | xargs -0 -I _ basename _)

  echo "$dotly_scripts" "$dotfiles_scripts" | grep -v "^_" | sort -u
}

dot::list_scripts() {
  _list_scripts() {
    scripts=$(dot::list_context_scripts "$1" | xargs -I_ echo "dot $1 _")

    echo "$scripts"
  }

  dot::list_contexts | coll::map _list_scripts
}

dot::list_scripts_path() {
  dotly_contexts=$(find "${SLOTH_PATH:-${DOTLY_PATH:-}}/scripts" -maxdepth 2 -perm /+111 -type f | grep -v "${SLOTH_PATH:-${DOTLY_PATH:-}}/scripts/core")
  dotfiles_contexts=$(find "$DOTFILES_PATH/scripts" -maxdepth 2 -perm /+111 -type f)

  printf "%s\n%s" "$dotly_contexts" "$dotfiles_contexts" | sort -u
}

dot::get_script_path() {
  [[ -n "${script_full_path:-}" ]] && dirname "$script_full_path" && return
  #shellcheck disable=SC2164
  echo "$(
    cd -- "$(dirname "$0")" > /dev/null 2>&1
    pwd -P
  )"
}

dot::get_full_script_path() {
  [[ -n "${script_full_path:-}" ]] && echo "$script_full_path" && return

  #shellcheck disable=SC2164
  echo "$(
    cd -- "$(dirname "$0")" > /dev/null 2>&1
    pwd -P
  )/$(basename "$0")"
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
        "$DOTFILES_PATH/scripts/$2/src"
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

dot::parse_script_version() {
  local SCRIPT_FULL_PATH SCRIPT_VERSION versions v
  SCRIPT_FULL_PATH="${1:-}"

  [[ ! -f "$SCRIPT_FULL_PATH" ]] && return 1
  readarray -t versions < <(sed -n 's/.*SCRIPT_VERSION[=| ]"\?\(.[^";]*\)"\?;\?.*/\1/p' "$SCRIPT_FULL_PATH")

  if [[ "${#versions[@]}" -gt 1 ]]; then
    for v in "${versions[@]}"; do
      v="$(echo "$v" | xargs)"
      if [[ -z "${SCRIPT_VERSION:-}" || "$(platform::semver_compare "$SCRIPT_VERSION" "$v" 2> /dev/null)" -lt 0 ]]; then
        SCRIPT_VERSION="$v"
      fi
    done
  elif [[ "${#versions[@]}" -gt 0 ]]; then
    SCRIPT_VERSION="${versions[0]}"
  fi

  echo "$SCRIPT_VERSION" | xargs
}
