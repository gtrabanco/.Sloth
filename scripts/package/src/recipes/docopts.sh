#!/usr/bin/env bash
#? Author:
#?   Gabriel Trabanco Llano <gtrabanco@users.noreply.github.com>
#? v1.0.0

DOCOPTS_INSTALL_PATH="${DOCOPTS_INSTALL_PATH:-${HOME}/bin}"
DOCOPTS_BIN="$DOCOPTS_INSTALL_PATH/docopts"
#DOCOPTS_SH_INSTALL_PATH="${SLOTH_PATH}/scripts/core/src"

DOCOPTS_GIT_REPOSITORY="${DOCOPTS_GIT_REPOSITORY:-jacanales/docopts}"
DOCOPTS_GIT_REPOSITORY_URL="https://github.com/${DOCOPTS_GIT_REPOSITORY}"

# REQUIRED FUNCTION
docopts::is_installed() {
  #[[ -x "$DOCOPTS_BIN" && -r "$DOCOPTS_SH_INSTALL_PATH" ]]
  [[ -x "$DOCOPTS_BIN" ]]
}

# REQUIRED FUNCTION
docopts::install() {
  docopts::is_installed && return

  DOCOPTS_BINARY_FILENAME="${DOCOPTS_BINARY_FILENAME:-docopts_$(platform::get_os)_$(platform::get_arch)}"
  local -r docopts_bin_download_url="$(github::get_latest_package_release_download_url "$DOCOPTS_GIT_REPOSITORY" | grep "$DOCOPTS_BINARY_FILENAME")"

  if ! github::_is_valid_url "$docopts_bin_download_url"; then
    _log "Invalid URL: \`$docopts_bin_download_url\`"
    return 1
  fi

  mkdir -p "$DOCOPTS_INSTALL_PATH"

  [[ ! -w "$DOCOPTS_INSTALL_PATH" ]] &&
    _log "Cannot write to $DOCOPTS_INSTALL_PATH" &&
    return 1

  curl -s -L "$docopts_bin_download_url" -o "$DOCOPTS_BIN"
  chmod +x "$DOCOPTS_INSTALL_PATH/docopts"

  docopts::is_installed && return

  return 1
}

# OPTIONAL
docopts::uninstall() {
  rm -f "$DOCOPTS_BIN"
}

# OPTIONAL
docopts::force_install() {
  local _args
  mapfile -t _args < <(array::substract "--force" "$@")

  docopts::is_installed "${_args[@]}" &&
    docopts::uninstall "${_args[@]}" &&
    docopts::install "${_args[@]}" &&
    docopts::is_installed "${_args[@]}" &&
    return

  return 1
}

# ONLY REQUIRED IF YOU WANT TO IMPLEMENT AUTO UPDATE WHEN USING `up` or `up registry`
# Description, url and versions only be showed if defined
docopts::is_outdated() {
  local -r latest="$(docopts::latest)"
  local -r current="$(docopts::version)"

  [[ $(platform::semver compare "$current" "$latest") -lt 0 ]]
}

docopts::upgrade() {
  docopts::force_install "$@"
}

docopts::description() {
  echo "Shell interpreter for docopt, the command-line interface description language."
}

docopts::url() {
  #echo "https://github.com/docopt/docopts"
  echo "http://docopt.org/"
}

docopts::version() {
  docopts::is_installed && "$DOCOPTS_BIN" --version | head -n1 | awk '{print $2}'
}

docopts::latest() {
  git::remote_latest_tag_version "$DOCOPTS_GIT_REPOSITORY_URL"
}

docopts::title() {
  echo -n "DOCOPT docopts"
}