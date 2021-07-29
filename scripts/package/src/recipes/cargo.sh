#!/usr/bin/env bash

cargo::install() {
  if ! platform::is_macos; then
    package::install build-essential auto
  fi

  curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path 2>&1 | log::file "Installing rust from sources"

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
  local -r cargo="$(cargo --version 2> /dev/null | awk '{print $2}')"
  local -r rustup="$(rustup --version 2> /dev/null | head -n1 | awk '{print $2}')"
  local -r rustc="$(rustc --version 2> /dev/null | awk '{print $2}')"
  echo -n "${cargo} (rustup ${rustup} - rustc ${rustc})"
}

cargo::latest() {
  rustup update --no-self-update 2> /dev/null | xargs | awk '{print $5}'
}

cargo::is_outdated() {
  [[ "$(rustup update --no-self-update 2> /dev/null | xargs | awk '{print $2}')" == "updated" ]]
}

cargo::upgrade() {
  rustup update &> /dev/null
}

cargo::description() {
  echo -n "Cargo is a Rust package manager"
}

cargo::url() {
  echo -n "https://doc.rust-lang.org/cargo/ - https://crates.io"
}

cargo::title() {
  echo -n "📦 Cargo & ☢️ Rust compiler"
}
