#!/usr/bin/env bash

python-yq::install() {
  script::depends_on python3-pip
  
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
  # Because there is another tool called yq as well
  platform::command_exists yq && yq --help | grep -q "https://github.com/kislyuk/yq"
}
