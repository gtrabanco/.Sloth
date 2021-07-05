#!/usr/bin/env bash

mas::is_available() {
  platform::command_exists mas
}

mas::update_all() {
  outdated=$(mas outdated)

  if [ -z "$outdated" ]; then
    output::answer "Already up-to-date"
  else
    mas upgrade
  fi
}
