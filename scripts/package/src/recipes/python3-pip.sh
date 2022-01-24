#!/usr/bin/env bash

python3-pip::is_installed() {
  platform::command_exists python3 && python3 -c "import pip; print(pip.__version__)" > /dev/null 2>&1
}

python3-pip::install() {
  if platform::is_macos && platform::command_exists brew; then
    brew install python@3.9
  else
    package::install python3 python3-testresources python3-pip
  fi

  if platform::command_exists python3; then
    output::empty_line
    output::answer "Executing get-pip.py with python3"
    python3 < <(curl -fsSL "https://bootstrap.pypa.io/get-pip.py") - --upgrade --user
    output::empty_line

    output::answer "Ensurepip"
    python3 -m ensurepip --default-pip
    output::empty_line

    output::answer "Upgrading setuptools & wheel"
    "$(command -v python3)" -m pip install --upgrade --user setuptools wheel
    output::empty_line

    output::answer "Python3 & pip3 are installed"
    return
  fi

  ourput::error "Python3-pip not installed"
  return 1
}

python3-pip::uninstall() {
  if platform::is_macos && platform::command_exists brew; then
    brew uninstall python@3.9
  else
    package::uninstall python3-testresources
    package::uninstall python3-pip
    package::uninstall python3
  fi

  ! python3-pip::is_installed && output::answer "Python3-pip uninstalled"
}
