#!/usr/bin/env bash

docpars::install() {
  script::depends_on cargo

  #shellcheck disable=SC1091
  [[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
  cargo install docpars
}

docpars::is_installed() {
  platform::command_exists docpars
}
