#!/usr/bin/env bash

tldr::is_installed() {
  platform::command_exists tldr
}

tldr::install() {
  package::install tldr auto "${1:-}"
}

tldr::is_outdated() {
  local -r tldr_path="${HOME}/.tldrc"
  if [[ ! -d "$tldr_path" ]] || [[ -d "$tldr_path" ]] && files::check_if_path_is_older "$tldr_path" 7 days; then
    return 0
  fi

  return 1
}

tldr::upgrade() {
  command tldr --update
  output::answer "TLDR updated"
}

tldr::description() {
  echo "Simplified and community-driven man pages"
}

tldr::url() {
  echo "https://tldr.sh"
}

tldr::title() {
  echo -n "📜 TLDR"
}