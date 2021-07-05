#!/usr/bin/env bash
export PACKAGE_MANAGERS_SRC=(
  "${SLOTH_PATH:-$DOTLY_PATH}/scripts/package/src/package_managers"
  "${DOTFILES_PATH}/package_managers"
  "${PACKAGE_MANAGERS_SRC[@]}"
)

if [[ -z "${SLOTH_PACKAGE_MANAGERS_PRECEDENCE:-}" ]]; then
  if platform::is_macos; then
    export SLOTH_PACKAGE_MANAGERS_PRECEDENCE=(
      brew cargo mas pip volta npm
    )
  else
    export SLOTH_PACKAGE_MANAGERS_PRECEDENCE=(
      apt snap brew dnf pacman yum cargo pip gem volta npm
    )
  fi
fi

package::load_manager() {
  local package_manager_file_path
  local -r package_manager="${1:-}"

  package_manager_file_path="$(package::manager_exists "$package_manager")"

  if [[ -n "$package_manager_file_path" ]]; then
    dot::load_library "$package_manager_file_path"
  else
    output::error "🚨 Package Manager \`$package_manager\` does not exists"
    exit 4
  fi
}

package::manager_exists() {
  local package_manager_src
  local -r package_manager="${1:-}"
  for package_manager_src in "${PACKAGE_MANAGERS_SRC[@]}"; do
    [[ -f "${package_manager_src}/${package_manager}.sh" ]] &&
      head -n 1 "${package_manager_src}/${package_manager}.sh" | grep -q "^#\!/" &&
      echo "${package_manager_src}/${package_manager}.sh" &&
      return
  done
}

package::get_available_package_managers() {
  local package_manager_src package_manager
  find "${PACKAGE_MANAGERS_SRC[@]}" -maxdepth 1 -mindepth 1 -print0 2>/dev/null | xargs -0 -I _ echo _ | while read -r package_manager_src; do
    # Get package manager name
    package_manager="$(basename "$package_manager_src")"
    package_manager="${package_manager%%.sh}"

    # Check if it is a valid package manager
    [[ -z "$(package::manager_exists "$package_manager")" ]] && continue

    # Load package manager
    package::load_manager "$package_manager"

    # Check if package manager is available
    if command -v "${package_manager}::is_available" &>/dev/null && "${package_manager}::is_available"; then
      echo "$package_manager"
    fi
  done
}

package::command() {
  local -r package_manager="${1:-}"
  local -r command="${2:-}"
  local -r args=("${@:3}")

  if [[ "$package_manager" == "none" ]] ||
    [[ -z "$(package::manager_exists "$package_manager")" ]]; then
    return 1
  fi

  package::load_manager "$package_manager"

  # If function does not exists for the package manager it will return 0 (true) always
  if [[ "$command" == "install" ]]; then
    declare -F "${package_manager}::${command}" &>/dev/null && "${package_manager}::${command}" "${args[@]}" | log::file "Trying to install ${args[*]} using $package_manager" || return
  else
    declare -F "${package_manager}::${command}" &>/dev/null && "${package_manager}::${command}" "${args[@]}"
  fi
}

package::is_installed() {
  local package_manager
  [[ -z "${1:-}" ]] && return 1

  for package_manager in $(package::get_available_package_managers); do
    package::command "$package_manager" is_installed "$1" && return 
  done
  
  registry::is_installed "$1" || return 1
}

# Try to install with any package manager
package::install() {
  local package_manager package
  [[ -z "${1:-}" ]] && return 1
  package="$1"
  
  # Try to install from package managers precedence
  for package_manager in "${SLOTH_PACKAGE_MANAGERS_PRECEDENCE[@]}"; do
    if [[ $package_manager == "pip" ]] && package::command "pip" "install"  "$package"; then
      if package::command "pip" "is_installed" "$package"; then
        return
      fi
    elif package::manager_exists "$package_manager" &&
       package::command "$package_manager" "is_available" &&
       package::command "$package_manager" "package_exists" "$package"
    then
      package::command "$package_manager" "install" "$package"
      return
    fi
  done
  unset package_manager

  # Install from any other available package manager
  for package_manager in $(package::get_available_package_managers); do
    if package::command "$package_manager" "package_exists" "$package"; then
      package::command "$package_manager" "install" "$package"
      return
    fi
  done

  return 1
}

package::clarification() {
  output::write "${1:-} could not be updated. Use \`dot self debug\` to view more details."
}

package::exists_dump_current_machine_file() {
  local FILES_PATH file_name
  FILES_PATH="$(realpath -sm "${1:-}")"

  file_name="$(find "$FILES_PATH" -name "*" -not -iname "*lock*" -not -iname ".*" -print0 2>/dev/null | xargs -0 -I _ basename _ | grep -Ei "^$(hostname -s)(.txt|.json)?$" | head -n 1)"
  [[ -n "$file_name" && -f "$FILES_PATH/$file_name" ]] && echo "$FILES_PATH/$file_name"
}

package::preview() {
  local filename="$1"
  local FILES_PATH
  FILES_PATH="$(realpath -sm $2)"

  if [ "$filename" == "No import" ]; then
    echo "No import any file for this package manager"
    return
  fi

  { [[ -f "$FILES_PATH/$filename" ]] && cat "$FILES_PATH/$filename"; } || "Could not find the file '$FILES_PATH/$filename'"
}

package::which_file() {
  local FILES_PATH header var_name answer files
  FILES_PATH="$(realpath -sm "$1")"
  header="$2"
  var_name="$3"

  #shellcheck disable=SC2207
  files=($(find "$FILES_PATH" -not -iname ".*" -maxdepth 1 -type f,l -print0 2>/dev/null | xargs -0 basename | sort -u))

  if [[ -d "$FILES_PATH" && ${#files[@]} -gt 0 ]]; then
    answer="$(printf "%s\n" "${files[@]}" | fzf -0 --filepath-word -d ',' --prompt "$(hostname -s) > " --header "$header" --preview "[[ -f $FILES_PATH/{} ]] && cat $FILES_PATH/{} || echo No import a file for this package manager")"
    [[ -f "$FILES_PATH/$answer" ]] && answer="$FILES_PATH/$answer" || answer=""
  fi
  eval "$var_name=${answer:-}"
}

package::common_dump_check() {
  local command_check file_path
  command_check="${1:-}"
  file_path="${2:-}"

  if [[ -n "${command_check:-}" ]] &&
    [[ -n "$file_path" ]] &&
    platform::command_exists "$command_check"; then
    mkdir -p "$(dirname "$file_path")"
  fi
}

package::common_import_check() {
  local command_check file_path
  command_check="${1:-}"
  file_path="${2:-}"

  [[ -n "${command_check:-}" ]] &&
    [[ -n "$file_path" ]] &&
    platform::command_exists "$command_check" &&
    [[ -f "$file_path" ]]
}
