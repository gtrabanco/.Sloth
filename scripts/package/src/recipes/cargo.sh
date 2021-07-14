#!/usr/bin/env bash

cargo::install() {
  {
    platform::command_exists brew && brew install rust 2>&1 | log::file "Installing build-essential" && return 0
  } || true

  if platform::command_exists apt; then
    sudo apt install -y build-essential 2>&1 | log::file "Installing apt build-essential"
  fi

  curl https://sh.rustup.rs -sSf | sh -s -- -y 2>&1 | log::file "Installing rust from sources"

  #shellcheck disable=SC1091
  [[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

  # Sometimes it fails to set the toolchain, this avoid that error
  if platform::command_exists rustup; then
    rustup install stable
    rustup default stable
  fi
}

cargo::is_installed() {
  platform::command_exists cargo
}

cargo::version() {
  local -r cargo="$(cargo --version | awk '{$2}')"
  local -r rustup="$(rustup --version 2>/dev/null | head -n1 | awk '{print $2}')"
  local -r rustc="$(rustc --version | awk '{print $2}')"
  echo -n "${cargo} (rustup ${rustup} - rustc ${rustc})"
}

cargo::latest() {
  rustup update --no-self-update 2>/dev/null | xargs | awk '{print $5}'
}

cargo::is_outdated() {
  [[ "$(rustup update --no-self-update 2>/dev/null | xargs | awk '{print $2}')" == "updated" ]]
}

cargo::update() {
  rustup update
}

cargo::description() {
  echo -n "Cargo is the Rust package manager. Cargo downloads your Rust package's dependencies, compiles your packages, makes distributable packages, and uploads them to crates.io, the Rust community’s package registry."
}

cargo::url() {
  echo -n "https://doc.rust-lang.org/cargo/ - https://crates.io"
}
