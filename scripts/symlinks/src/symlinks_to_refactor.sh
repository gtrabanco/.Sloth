#!/usr/bin/env bash

# Move file_path to inside relative DOTBOT_BASE_PATH
# Know limitation, not possible to create a symlink to a symlink because
# its stupid to store it. Instead resolve to real file and store the real
# file and create a symlink in its original path.
# TODO Production work
symlinks::move_from_pwd_to_dotbot() {
  local yaml_file from path_to
  [[ $# -lt 3 || ! -e "${2:-}" ]] && return 1

  yaml_file="${1:-}"
  from="$(symlinks::realpath_existing_file "${2:-}")"
  path_to="$(dotbot::realpath "${3:-}")"

  if [[ -f "$yaml_file" ]]; then
    # 1. Create internal dotbot path
    # TODO Uncoment on production
    # mkdir -p "$path_to"

    # 2. Move the file to internal dotbot path
    dotbot::mv -i "$from" "$path_to"
  fi
}

# From can be the current path, to should be the path inside your dotfiles
symlinks::add_yaml_and_move_files() {
  # 1. Move to internal dotbot
  if symlinks::move_from_pwd_to_dotbot "${1:-}" "${2:-}" "${3:-}"; then
    # 2. Symbolic link and add it to yaml_file
    symlink::new_link "${1:-}" "${2:-}" "${3:-}"
  fi
}

# TODO Production work
symlinks::restore_by_link() {
  local yaml_file link dotfiles_file_path
  yaml_file="${1:-}"

  [[ ! -f "$yaml_file" ]] && return 1

  link="$(dotbot::relativepath "${2:-}")"
  dotfiles_file_path="$(dotbot::get_value_of_key_in "link" "$link" "$yaml_file")"

  [[ -z "$link" || -z "$dotfiles_file_path" ]] && return 1

  # TODO Uncoment on production
  # dotbot::delete_by_key_in "link" "$link" "$yaml_file" || true
  #shellcheck disable=SC2016
  if dotbot::rm -f "$link"; then
    #shellcheck disable=SC2016
    dotbot::mv -i "$dotfiles_file_path" "$link"
    #shellcheck disable=SC2016
    rmdir -p "$(dirname "$dotfiles_file_path")" > /dev/null 2>&1
  fi
}

# Not used but it worked
# TODO Production work
symlinks::restore_by_dotfile_file_path() {
  local yaml_file link dotfiles_file_path
  yaml_file="${1:-}"

  [[ ! -f "$yaml_file" ]] && return 1

  dotfiles_file_path="$(dotbot::relativepath "${2:-}")"
  link="$(dotbot::get_key_by_value_in "link" "$dotfiles_file_path" "$yaml_file")"

  # if [ -n "$link" ]; then
  #   symlinks::restore_by_link "$yaml_file" "$link"
  # fi
}

# TODO Production work
symlinks::edit_link_by_link_path() {
  local yaml_file old_link_realpath old_link new_link link_value link_value_realpath
  yaml_file="${1:-}"
  old_link_realpath="$(realpath -qs "${2:-}" 2> /dev/null || true)"
  old_link="$(dotbot::relativepath "$old_link_realpath")"
  new_link="$(dotbot::relativepath "${3:-}")"

  [[ ! -f "$yaml_file" ]] && return 1

  link_value="$(dotbot::get_value_of_key_in "link" "$old_link" "$yaml_file")"

  if [ -n "$link_value" ]; then
    link_value_realpath="$(dotbot::realpath "$link_value")"

    # 1. Remove the old link
    #shellcheck disable=SC2016
    dotobot::rm -f "$old_link"

    # 2. Create the new link
    # TODO Unecho in production
    echo ln -s "$link_value_realpath" "$(dotbot::realpath "$new_link")"

    # 3. Delete the old link
    # TODO Uncoment in production
    # dotbot::delete_by_key_in "link" "$old_link" "$yaml_file" || true

    # 4. Add it the new one
    # TODO Uncomment in production
    # dotbot::add_or_edit_json_value_to_directive "link" "$new_link" "$link_value" "$yaml_file"
    [[ ! -f "$old_link" ]] && ! symlinks::link_exists "$old_link"
  fi

  return 1
}

# TODO Production work
symlinks::edit_link_by_dotfile_file_path() {
  local yaml_file dotfiles_file_path new_link old_link
  yaml_file="${1:-}"
  dotfiles_file_path="$(dotbot::relativepath "${2:-}")"
  new_link="${3:-}"

  [[ ! -f "$yaml_file" ]] && return 1

  old_link="$(dotbot::get_key_by_value_in "link" "$dotfiles_file_path" "$yaml_file")"

  # [ -n "$old_link" ] && symlinks::edit_link_by_link_path "$yaml_file" "$old_link" "$new_link"
  echo ""
}

# Delete dotobot link if exists in yaml file
# TODO Production work
symlinks::delete_link() {
  local yaml_file link dotbot_file_path
  yaml_file="${1:-}"
  link="${2:-}"

  [[ -z "$link" || ! -f "$yaml_file" ]] && return 1

  link="$(dotbot::relativepath "$link")"

  if [[ -n "$(symlinks::link_exists "$link")" ]]; then
    # 1. Delete the link
    dotbot::rm -f "$link" &> /dev/null

    # 2. Delete the value in yaml file
    # dotbot::delete_by_key_in "link" "$link" "$yaml_file"
  else
    return 1
  fi
}

# Delete by the provided link
# Executes "rm -i -rf" to the file in DOTBOT_BASE_PATH unless you pass more
# arguments which would be the argument to delete the file being the
# last param the link. Example
#   symlinks::link_and_files "$yaml_file" "~/mylink" rm -i
# This will delete using "rm -i"
# TODO Production work
symlinks::delete_link_and_files() {
  local yaml_file link delete_cmd dotbot_file_path
  yaml_file="${1:-}"
  link="${2:-}"
  shift 2

  { [[ -z "$yaml_file" ]] || [[ -z "$link" ]] || [[ ! -f "$yaml_file" ]]; } && return 1

  if [[ -z "${*:-}" ]]; then
    delete_cmd=(rm -i -rf)
  else
    delete_cmd=("$@")
  fi

  link="$(dotbot::relativepath "$link")"

  if [[ -n "$(symlinks::link_exists "$yaml_file" "$link")" ]]; then
    dotbot_file_path="$(dotbot::get_value_of_key_in "link" "$link" "$yaml_file")"

    if [[ -n "$dotbot_file_path" ]] && symlinks::delete_link "$yaml_file" "$link"; then
      dotbot::rm --rm-cmd "${delete_cmd[*]}" "$dotbot_file_path" || true
    else
      return 1
    fi
  else
    return 1
  fi
}

# Same as symlinks::delete_link but by the value of the link
symlinks::delete_link_by_link_value() {
  local yaml_file link_value link delete_cmd
  yaml_file="${1:-}"
  link_value="$(dotbot::relativepath "${2:-}")"

  [[ ! -f "$yaml_file" || -z "${link_value:-}" ]] && return 1

  link="$(dotbot::get_key_by_value_in "link" "$link_value" "$yaml_file")"

  if ! { [ -n "$link" ] && symlinks::delete_link "$yaml_file" "$link" "${@:-}"; }; then
    return 1
  fi

# Same as symlinks::delete_link_and_files but by the value of the link
symlinks::delete_link_and_files_by_link_value() {
  local yaml_file link_value link delete_cmd
  yaml_file="${1:-}"
  link_value="$(dotbot::relativepath "${2:-}")"
  shift 2

  [[ ! -f "$yaml_file" || -z "${link_value:-}" ]] && return 1

  link="$(dotbot::get_key_by_value_in "link" "$link_value" "$yaml_file")"

  if ! { [ -n "$link" ] && symlinks::delete_link_and_files "$yaml_file" "$link" "${@:-}"; }; then
    return 1
  fi
}