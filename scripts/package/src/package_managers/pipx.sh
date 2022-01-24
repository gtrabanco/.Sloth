#!/usr/bin/env bash
#? Author:
#?   Gabriel Trabanco Llano <gtrabanco@users.noreply.github.com>
#? This file contains instrucctions to use the package manager pipx
#? v1.0.0

# REQUIRED VARIABLE
pipx_title='PIPX pipx'

pipx::pipx() {
  PIPX_BIN="${PIPX_BIN:-$(command -v pipx)}"
  if [ ! -x "${PIPX_BIN}" ]; then
    return 1
  fi

  "$PIPX_BIN" "$@"
}

# REQUIRED
pipx::is_installed() {
  [ -n "$(package::which_package_manager pipx)" ]
}

# REQUIRED FUNCTION
pipx::title() {
  echo -n "𝙓 pipX"
}

# REQUIRED FUNCTION
pipx::is_available() {
  platform::command_exists pipx
}

# REQUIRED FUNCTION TO USE INSTALL
pipx::install() {
  local _args
  ! pipx::is_available &&
    return 1

  if [[ $* == *--force* ]]; then
    mapfile -t _args < <(array::substract "--force" "$@")
    pipx::force_install "${_args[@]}" &&
      return
  else
    pipx::pipx install "$@" &&
      pipx::is_installed "$@" &&
      return
  fi

  # Not show an error if ::package_exists is not implemented because the
  # installation will be try when using dot package add when that function
  # is not implemented
  return 1
}

# OPTIONAL FUNCTION TO USE FORCE INSTALL
pipx::force_install() {
  local _args
  ! pipx::is_available &&
    return 1

  readarray -t _args < <(array::substract "--force" "$@")

  pipx::pipx install --force "${_args[@]}"
}

# REQUIRED FUNCTION TO UNINSTALL
pipx::uninstall() {
  [[ $# -gt 0 ]] &&
    pipx::is_available &&
    pipx::pipx uninstall "$@"
}

# REQUIRED TO USE `up` or `up pipx`
pipx::update_all() {
  pipx::self_update
  pipx::update_apps
}

# Internal function
pipx::self_update() {
  if [ "$(package::which_package_manager pipx)" == "pip" ] || [ "$(package::which_package_manager pipx)" == "pip3" ]; then
    python3 -m pip install --user -U pipx
  fi
}

# Internal function
pipx::update_apps() {
  pipx::pipx upgrade-all --include-injected
}

# Only require for backup your packages
pipx::dump() {
  ! pipx::is_available && return 1
  PIPX_DUMP_FILE_PATH="${1:-$PIPX_DUMP_FILE_PATH}"

  if package::common_dump_check pipx "$PIPX_DUMP_FILE_PATH"; then
    script::depends_on jq

    readarray -t packages < <(pipx::pipx list --json | jq -re 'if has("venvs") then .venvs | keys | .[] else "" end' 2> /dev/null)
    printf "%s\n" "${packages[@]}" | tee "$PIPX_DUMP_FILE_PATH" | log::file "Exporting $pipx_title packages"

    return 0
  fi

  return 1
}

# Only required for importing your packages from previous backup
pipx::import() {
  ! pipx::is_available && return 1
  PIPX_DUMP_FILE_PATH="${1:-${PIPX_DUMP_FILE_PATH:-${DOTFILES_PATH:-${HOME}/.dotfiles}/langs/python/pipx-$(hostname -s).txt}}"

  if package::common_import_check pipx "$PIPX_DUMP_FILE_PATH"; then
    while read -r pkg; do
      [ -z "$pkg" ] && continue
      package:install "$pkg" "pipx"
    done < "$PIPX_DUMP_FILE_PATH"

    return 0
  fi

  return 1
}
