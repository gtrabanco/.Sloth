#!/usr/bin/env bash

hyperfine::install() {
  script::depends_on cargo

  platform::command_exists cargo && cargo install hyperfine && hyperfine::is_installed && return

  return 1
}

hyperfine::is_installed() {
  platform::command_exists hyperfine
}
