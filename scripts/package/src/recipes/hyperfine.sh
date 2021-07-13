#!/usr/bin/env bash

hyperfine::install() {
  script::depends_on cargo

  cargo install docpars
}

hyperfine::is_installed() {
  platform::command_exists hyperfine
}
