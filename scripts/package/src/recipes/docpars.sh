#!/usr/bin/env bash

docpars::install() {
  script::depends_on cargo

  cargo install docpars
}

docpars::is_installed() {
  platform::command_exists docpars
}
