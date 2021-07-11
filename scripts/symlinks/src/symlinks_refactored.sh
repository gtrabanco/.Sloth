#!/usr/bin/env bash

# Dependency
# dot::load_library "dotbot_yaml.sh"

#;
# symlinks::realpath()
# Get realpath but does not resolve the path if it is a link for any file. File is not necessary to exists
# @param file
# @return string|false path
#"
symlinks::realpath() {
  local file_path="${1:-}"
  [[ -z "$file_path" ]] && return
  file_path="${file_path//\.\//$(pwd)\/}" # ./ for $(pwd)/

  realpath -qzms "$file_path"
}

#;
# Get resolved realpath if it is a symlink
# @param file
# @return string|false path
#"
symlinks::resolvedpath() {
  local file_path="${1:-}"
  [[ -z "$file_path" ]] && return
  file_path="${file_path//\~/$HOME}"      # ~ for $HOME
  file_path="${file_path//\.\//$(pwd)\/}" # ./ for $(pwd)/

  if [[ -n "$(command -v greadlink)" ]]; then
    "$(command -v greadlink)" -qzfe "$file_path"
  elif
    { platform::is_macos && [[ "$(command -v readlink)" != "/usr/bin/readlink" ]]; } ||
      { ! platform::is_macos && [[ -n "$(command -v readlink)" ]]; }
  then
    readlink -qzfe "$file_path"
  elif [[ -n "$(command -v realpath)" ]]; then
    realpath -qzLe "$file_path"
  fi

  return 1
}

#;
# Check if link exist by given link or value of the link it will always return the link key or false
# @param link_or_link_value should be a realpath or valid path to be a link. it can be also a valid realpath or relative path to DOTBOT_BASE_PATH stored file that have a link
# @param yaml_file not used if you piped any yaml content to the fn. Piped always has precedence.
# @return string|false link path
#"
symlinks::link_exists() {
  local link_or_dotfile_path link_check_value yaml_file input
  link_or_dotfile_path="${1:-}"
  yaml_file="${2:-}"

  if [[ -z "$link_or_dotfile_path" ]]; then
    return 1
  fi

  if [[ -t 0 && -f "$yaml_file" ]]; then
    input="$(cat "$yaml_file")"
  elif [[ ! -t 0 ]]; then
    input="$(< /dev/stdin)"
  else
    # No file found and no stdin
    return 1
  fi

  # By link
  link_check_value="$(echo "$input" | dotbot::get_value_of_key_in "link" "$(dotbot::relativepath "$link_or_dotfile_path")" || echo "")"
  [[ -n "$link_check_value" ]] && dotbot::relativepath "$link_or_dotfile_path" && return 0

  # By link value
  link_check_value="$(echo "$input" | dotbot::get_key_by_value_in "link" "$(dotbot::relativepath "$link_or_dotfile_path")")"
  [[ -n "$link_check_value" ]] && echo "$link_check_value" && return 0

  return 1
}

#;
# Get an array of all links in a yaml file or piped yaml content
# @param path_to_yaml not necessary if you pass a piped yaml content. Piped value has precedence over a given file
# @return array|void
#"
symlinks::get_all_links() {
  local yaml_file
  yaml_file="${1:-}"

  if [[ -t 0 && -f "$yaml_file" ]]; then
    dotbot::get_all_keys_in "link" "$yaml_file" || true
  elif [[ ! -t 0 ]]; then
    dotbot::get_all_keys_in "link" < /dev/stdin || true
  fi
}

#;
# Get an array of all link values in a yaml file or piped yaml content
# @param yaml_file Optional path to yaml file, not necessary if you pass a piped yaml content. Piped value has precedence over a given file
# @return array|void
#"
symlinks::get_all_link_values() {
  local yaml_file
  yaml_file="${1:-}"

  if [[ -t 0 && -f "$yaml_file" ]]; then
    dotbot::get_all_values_in "link" "$yaml_file" || true
  elif [[ ! -t 0 ]]; then
    dotbot::get_all_values_in "link" < /dev/stdin || true
  fi
}

#;
# symlinks::get_linked_path_by_link()
# Get the value of the given link (were the file is stored relative to DOTBOT_BASE_PATH)
# @param link Get link value realpath to the real file
# @param yaml_file Optional path to yaml file, not necessary if you pass a piped yaml content. Piped value has precedence over a given file
# @return string|void realpath to real linked file stored in DOTBOT_BASE_PATH
#"
symlinks::get_linked_path_by_link() {
  local yaml_file link value
  link="${1:-}"
  yaml_file="${2:-}"

  if [[ -t 0 && -n "$link" && -f "$yaml_file" ]]; then
    value="$(dotbot::get_value_of_key_in "link" "$(dotbot::relativepath "$link")" "$yaml_file" || echo -n)"
  elif [[ ! -t 0 && -n "$link" ]]; then
    value="$(dotbot::get_value_of_key_in "link" "$(dotbot::relativepath "$link")" < /dev/stdin || echo -n)"
  fi

  [[ -n "$value" ]] && dotbot::realpath "$value"
}

#;
# symlinks::get_link_by_linked_path()
# Get the link by providen stored file in DOTBOT_BASE_PATH
# @param link_value Get were is symbolic link created by stored file in DOTBOT_BASE_PATH
# @param yaml_file Optional path to yaml file, not necessary if you pass a piped yaml content. Piped value has precedence over a given file
# @return string|void realpath to the symbolic link (not resolved path)
#"
symlinks::get_link_by_linked_path() {
  local yaml_file linked_path link
  linked_path="${1:-}"
  yaml_file="${2:-}"

  if [[ -t 0 && -n "$linked_path" && -f "$yaml_file" ]]; then
    link="$(dotbot::get_key_by_value_in "link" "$(dotbot::relativepath "$linked_path")" "$yaml_file" || echo -n)"
  elif [[ ! -t 0 && -n "$linked_path" ]]; then
    link="$(dotbot::get_key_by_value_in "link" "$(dotbot::relativepath "$linked_path")" < /dev/stdin || echo -n)"
  fi

  [[ -n "$link" ]] && dotbot::realpath "$link"
}

#;
# symlinks::add_link()
# Append a link to dotbot <yaml_file> or stdin dotbot yaml
# @param link_path Where to place the link (very recommended to use realpath that accept ~ at the beggining)
# @param file_path The path to be linked (very recommended to use realpath that accept ~ at the beggining, this path must exists)
# @param yaml_file Optional argument to read the file and save the link in the given file. If stdin the link will be added to stdin and not saved.
# @return string|boolean Return string yaml file content (always) if success, 1 if failed
#"
symlinks::add_link() {
  local yaml_file link_path file_path link link_value

  # Check no. arguments
  [[ $# -lt 2 ]] && return 1

  # Variables
  link_path="$(symlinks::realpath "$1")"
  file_path="$(dotbot::realpath "$2")"
  yaml_file="${3:-}"
  link="$(dotbot::relativepath "$link_path")"
  link_value="$(dotbot::relativepath "$file_path")"

  if [[ -t 0 && -f "$yaml_file" && -e "$file_path" ]]; then
    dotbot::add_or_edit_json_value_to_directive "link" "$link" "$link_value" "$yaml_file"
  elif [[ ! -t 0 && -e "$file_path" ]]; then
    dotbot::add_or_edit_json_value_to_directive "link" "$link" "$link_value" < /dev/stdin
  else
    return 1
  fi
}

#;
# symlinks::update_link()
# Update a <link> or <link_value> to dotbot <yaml_file> or stdin dotbot yaml. <link> or <link_value> must exists
# @param link Where to place the link (very recommended to use realpath that accept ~ at the beggining)
# @param link_value The path to be linked (very recommended to use realpath that accept ~ at the beggining, this path must exists)
# @param yaml_file Optional argument to read the file and save the link in the given file. If stdin the link will be added to stdin and not saved.
# @return string|boolean Return string yaml file content (always) if success, 1 if failed
#"
symlinks::update_link() {
  local yaml_file link link_value is_link old_link input

  # Check no. arguments
  [[ $# -lt 2 ]] && return 1

  # Variables
  link="$(symlinks::realpath "$1")"
  link_value="$(dotbot::realpath "$2")"
  yaml_file="${3:-}"
  link="$(dotbot::relativepath "$link_path")"
  link_value="$(dotbot::relativepath "$file_path")"
  is_link="$(symlinks::link_exists "$link_path")"

  if [[ -t 0 && -f "$yaml_file" && -n "$is_link" ]]; then
    symlinks::add_link "$link" "$link_value" "$yaml_file"
  elif [[ -t 0 && -f "$yaml_file" && -z "$is_link" ]]; then
    # Delete the symlink by link
    old_link="$(symlinks::link_exists "$link_value")"
    [[ -z "$old_link" ]] && return 1

    dotbot::delete_by_key_in "link" "$old_link" "$yaml_file"
    # Add new symlink
    symlinks::add_link "$link" "$link_value" "$yaml_file"
  elif [[ ! -t 0 && -n "$is_link" ]]; then
    symlinks::add_link "$link" "$link_value" < /dev/stdin
  elif [[ ! -t 0 && -z "$is_link" ]]; then
    input="$(< /dev/stdin)"
    # Delete the symlink by link
    old_link="$(echo "$input" | symlinks::link_exists "$link_value")"
    [[ -z "$old_link" ]] && return 1

    echo "$input" | dotbot::delete_by_key_in "link" "$old_link" | symlinks::add_link "$link" "$link_value"
  else
    return 1
  fi
}

#;
# symlinks::find()
# See in code doc
#"
# Custom find for these scripts context
# It has positional arguments, valid example of usage is:
# symlinks::find --exclude "$DOTBOT_BASE_PATH" -maxdepth 1 -name "*"
# Not valid usage is:
# symlinks::find -name "*" -maxdepth 1 "$DOTBOT_BASE_PATH"
#
# --exclude must be the first
# "/some/path/to/find" the second
# Any other find commands (first global options and later "particular" options)
#
symlinks::find() {
  local find_relative_path exclude_itself arguments
  arguments=()
  exclude_itself=false

  case "${1:-}" in
    --exclude)
      exclude_itself=true
      shift
      ;;
  esac

  find_relative_path="$(dotbot::realpath "${1:-}")"

  arguments+=("$@")

  if $exclude_itself; then
    arguments+=(-not -path "$find_relative_path")
  fi

  find "$find_relative_path" "${arguments[@]:-}" -not -iname ".*" -print0 | xargs -0 -I _ realpath -qsm --relative-to="$find_relative_path" _
}
