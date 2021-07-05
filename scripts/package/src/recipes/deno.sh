#!/usr/bin/env bash
deno::install() {
  if platform::command_exists cargo; then
    cargo install deno
  else
    "${SLOTH_PATH:-$DOTLY_PATH}/bin/dot" package add --skip-recipe deno
  fi

  if ! platform::command_exists deno &&
    ! platform::command_exists curl; then
    script::depends_on curl unzip
  fi

  if platform::command_exists curl; then
    curl -fsSL https://deno.land/x/install/install.sh | sh
  fi

  if platform::command_exists deno; then
    return
  fi

  return 1
}

deno::is_installed() {
  platform::command_exists deno
}