#!/usr/bin/env bash

files::check_if_path_is_older() {
  local path_to_check number_of period
  path_to_check="$1"
  number_of="${2:-0}"
  period="${3:-days}"
  [[ -e "$path_to_check" ]] && [[ $(date -r "$path_to_check" +%s) -lt $(date -d "now - $number_of $period" +%s) ]]
}

files::backup_if_file_exists() {
  local file_path bk_suffix bk_file_path
  file_path="$(eval realpath -q -m "${1:-}")"
  bk_suffix="${2:-$(date +%s)}"
  bk_file_path="$file_path.${bk_suffix}"

  if [[ -n "$file_path" ]] &&
    { [[ -f "$file_path" ]] || [[ -d "$file_path" ]]; }; then
    eval mv "$file_path" "$bk_file_path" && echo "$bk_file_path" && return 1
  fi

  return 0
}

files::echo() {
  echo "WTF"
}

files::fzf() {
  local arguments preview multiple preview_args preview_path libraries_to_load dot_lib
  preview=false
  multiple=false
  preview_args=()
  preview_path="$DOTBOT_BASE_PATH/"
  arguments=()

  while [ ${#:-0} -gt 0 ]; do
    case "${1:-}" in
      --default-preview)
        preview=true
        shift
        ;;
      --preview)
        preview=true
        preview_args+=("$2;")
        shift 2
        ;;
      -p|--preview-path)
        [[ -d "${2:-}" ]] && preview_path="${2:-}/"
        shift 2
        ;;
      -m|--multi)
        multiple=true
        arguments+=(--multi); shift

        if [[ "${1:-}" =~ '^[0-9]+$' ]]; then
          arguments+=("${1:-}"); shift
        fi
        ;;
      -c|--dotly-core)
        preview=true
        preview_args=(
          ". \"$DOTLY_PATH/scripts/core/_main.sh\";"
          "${preview_args[@]};"
        )
        shift
        ;;
      --script-libs)
        preview=true
        libraries_to_load=()
        for dot_lib in "${SCRIPT_LOADED_LIBS[@]}"; do
          [[ ! -f "$dot_lib" ]] && continue
          libraries_to_load+=(
            ". \"$dot_lib\";"
          )
        done

        preview_args=(
          ". \"$DOTLY_PATH/scripts/core/_main.sh\";"
          "${libraries_to_load[@]}"
          "${preview_args[@]}"
        )
        shift
        ;;
      *)
        break 2
        ;;
    esac
  done

  # Default preview
  if $preview && [[ -z "${preview_args[*]}" ]]; then
    $multiple && preview_args+=(
      'echo "Press Tab+Shift to select multiple options.";'
    )
    #shellcheck disable=SC2016
    preview_args+=(
      'file={};'
      'file_path=\"${preview_path:-}$file\";'
      'echo "Press Ctrl+C to exit with no selection.\n";'
      'echo "File: $file_path";'
      'echo "\n----";'
      '[[ -f "$file_path" ]] && cat "$file_path";'
    )
  fi
  

  # Add the arguments
  if $preview && [[ -n "${preview_args[*]:-}" ]]; then
    arguments+=(
      --preview
      "${preview_args[*]}"
    )
  fi
  arguments+=("$@")

  fzf "${arguments[@]}"
}
