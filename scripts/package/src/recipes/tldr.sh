#!/usr/bin/env bash

tldr::is_installed() {
  platform::command_exists tldr
}

tldr::install() {
  ! tldr::is_installed && package::install tldr
}

tldr::is_outdated() {
  return 0
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