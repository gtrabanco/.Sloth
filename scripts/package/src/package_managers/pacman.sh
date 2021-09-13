#!/usr/bin/env bash

#shellcheck disable=2034
pacman_title='PACMAN'

pacman::title() {
  echo -n "PACMAN"
}

pacman::is_available() {
  platform::command_exists pacman
}

pacman::install() {
  if platform::command_exists yay; then
    sudo yay -S --noconfirm "$@"
  else
    platform::command_exists pacman && sudo pacman -S --noconfirm "$@"
  fi
}

pacman::uninstall() {
  [[ $# -gt 0 ]] && pacman::is_available && yes | sudo pacman -Rcns "$@"
}

pacman::cleanup() {
  pacman::is_available && yes | sudo pacman -R "$(pacman -Qdtq)"
}

pacman::is_installed() {
  platform::command_exists pacman && pacman -Qs "$@" | grep -q 'local'
}
