#!/usr/bin/env bash

python-yq::install() {
  if
    platform::command_exists brew &&
      brew install python-yq &&
      python-yq::is_installed
  then
    return 0
  fi

  if
    platform::command_exists pip3 &&
      pip3 install yq &&
      python-yq::is_installed
  then
    output::solution "yq installed!"
    return 0
  fi

  output::error "yq could not be installed"
  return 1
}

python-yq::is_installed() {
  {
    platform::command_exists brew && {
      brew list --formula "python-yq" &> /dev/null || brew list --cask "python-yq" &> /dev/null
    }
  } || {
    platform::command_exists pip3 && pip3 show "yq" &> /dev/null
  }
}
