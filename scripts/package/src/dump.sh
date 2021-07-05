#!/usr/bin/env bash

dump::file_path() {
  local package_manager dump_file_name
  package_manager="${1:-}"
  dump_file_name="${2:-}"

  [[ -z "$package_manager" || -z "$dump_file_name" ]] && return

  case "$package_manager" in
    cargo)
      echo "$DOTFILES_PATH/langs/rust/cargo/${dump_file_name}.txt"
      ;;
    npm)
      echo "$DOTFILES_PATH/langs/js/npm/${dump_file_name}.txt"
      ;;
    volta)
      echo "$DOTFILES_PATH/langs/js/volta/${dump_file_name}.txt"
      ;;
    python)
      echo "$DOTFILES_PATH/langs/js/python/${dump_file_name}.txt"
      ;;
    # Please if you are adding a new package manager keep this last name the others
    # are just to keep compatibility with Dotly and previous dumps
    *)
      echo "$DOTFILES_PATH/os/$(platform::os)/$package_manager/${dump_file_name}.txt"
      ;;
  esac
}
