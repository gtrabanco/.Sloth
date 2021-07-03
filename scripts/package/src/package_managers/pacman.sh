#!/usr/bin/env bash

pacman::install() {
  if platform::command_exists yay; then
    sudo yay -S --noconfirm "$@"
  else
    platform::command_exists pacman && sudo pacman -S --noconfirm "$@"
  fi
}

pacman::is_installed() {
  platform::command_exists pacman && pacman -Qs "$@" | grep -q 'local'
}
