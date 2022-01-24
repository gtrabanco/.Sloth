#!/usr/bin/env bash

python-yq::install() {
  script::depends_on python3-pip

  if [[ -n "${1:-}" && $1 == "--force" ]] && python-yq::is_installed; then
    if platform::command_exists brew; then
      brew reinstall python-yq

    elif
      platform::command_exists python3 &&
        python3 -c "import pip; print(pip.__version__)" > /dev/null 2>&1
    then
      python3 -m pip install --ignore-installed --user --no-cache-dir yq
    else
      output::error "Unable to locate any valid package manager to force install python-yq"
      return 1
    fi

    python-yq::is_installed && return 0

  fi

  if
    ! python-yq::is_installed &&
      platform::command_exists brew &&
      brew install python-yq &&
      python-yq::is_installed
  then
    return 0
  fi

  if
    ! python-yq::is_installed &&
      platform::command_exists pip3 &&
      python3 -m pip install --user --no-cache-dir yq &&
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
