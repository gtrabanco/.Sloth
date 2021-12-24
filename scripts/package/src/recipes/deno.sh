#!/usr/bin/env bash
#shellcheck disable=SC2120

deno::install() {
  if [[ "${1:-}" = "--force" ]]; then
    deno::force_install
  fi

  package::install deno auto "$@"
  package::is_installed deno auto &&
    output::solution "Deno installed" &&
    return 0

  if
    ! deno::is_installed &&
      {
        ! platform::command_exists unzip ||
          ! platform::command_exists curl
      }
  then
    script::depends_on curl unzip

    if platform::command_exists curl; then
      curl -fsSL https://deno.land/x/install/install.sh | sh
    fi
  fi

  if platform::command_exists deno; then
    output::solution "Deno installed"
    return
  fi

  output::error "Deno could not be installed"
  return 1
}

deno::uninstall() {
  if [[ $(package::which_package_manager "deno") != "registry" ]]; then
    package::uninstall deno auto
  fi

  rm -rf "${HOME}/.deno/bin/deno" "${HOME}/.cargo/bin/deno"
}

deno::force_install() {
  deno::uninstall &&
    deno::install
}

deno::is_installed() {
  platform::command_exists deno && [[ -x "${HOME}/.deno/bin/deno" ]]
}

deno::is_outdated() {
  ! deno upgrade --dry-run 2>&1 | tail -n 1 | grep -q "is the most recent release$"
}

deno::upgrade() {
  deno upgrade
}

deno::description() {
  echo "Deno is a simple, modern and secure runtime for JavaScript and TypeScript that uses V8 and is built in Rust."
}

deno::url() {
  echo "https://deno.land/"
}

deno::version() {
  deno --version | head -n1 | awk '{print $2}'
}

deno::latest() {
  if deno::is_outdated; then
    deno upgrade --dry-run | head -n2 | tail -n1 | awk '{print $NF}'
  else
    deno::version
  fi
}

deno::title() {
  echo -n "🦕 Deno"
}
