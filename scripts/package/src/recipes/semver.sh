#!/usr/bin/env bash
#? Author:
#?   Gabriel Trabanco Llano <gtrabanco@users.noreply.github.com>
#? v1.0.0

SEMVER_INSTALL_PATH="${SEMVER_INSTALL_PATH:-${HOME}/bin}"
SEMVER_REPOSITORY_URL="${SEMVER_REPOSITORY_URL:-https://github.com/fsaintjacques/semver-tool}"
SEMVER_GITHUB_REPOSITORY="${SEMVER_GITHUB_REPOSITORY:-fsaintjacques/semver-tool}"
SEMVER_GITHUB_PATH="${SEMVER_GITHUB_PATH:-src/semver}"
SEMVER_DOWNLOAD_URL="https://raw.githubusercontent.com/fsaintjacques/semver-tool/HEAD/src/semver"

# github::get_remote_file_path_json

# REQUIRED FUNCTION
semver::is_installed() {
  platform::command_exists semver || [[ -x "${SEMVER_INSTALL_PATH}/semver" ]]
}

# REQUIRED FUNCTION
semver::install() {
  script::depends_on "curl"

  curl -fsL "${SEMVER_DOWNLOAD_URL}" -o "${SEMVER_INSTALL_PATH}/semver"
  chmod +x "${SEMVER_INSTALL_PATH}/semver"

  if [[ $* == *"--force"* ]]; then
    # output::answer "\`--force\` option is ignored with this recipe"
    semver::force_install "$@" && return
  else
    semver::is_installed && output::solution "semver installed" && return
  fi

  output::error "semver could not be installed"
  return 1
}

# OPTIONAL
semver::uninstall() {
  rm -f "${SEMVER_INSTALL_PATH}/semver"
}

# OPTIONAL
semver::force_install() {
  local _args
  mapfile -t _args < <(array::substract "--force" "$@")

  {
    semver::uninstall "${_args[@]}" &&
      semver::install "${_args[@]}" &&
      semver::is_installed "${_args[@]}"
  } || true

  semver::is_installed
}

# ONLY REQUIRED IF YOU WANT TO IMPLEMENT AUTO UPDATE WHEN USING `up` or `up registry`
# Description, url and versions only be showed if defined
semver::is_outdated() {
  local -r current_sha="$(github::hash "${SEMVER_INSTALL_PATH}/semver")"
  local -r latest_sha="$(github::get_remote_file_path_json "${SEMVER_GITHUB_REPOSITORY:-fsaintjacques/semver-tool}" "${SEMVER_GITHUB_PATH:-src/semver}" | jq -r '.sha')"

  [[ $current_sha != "$latest_sha" ]]
}

semver::upgrade() {
  semver::uninstall
  semver::install
}

semver::description() {
  echo "Little tool to manipulate version bumping in a project that follows the semver 2.x specification."
}

semver::url() {
  # Please modify
  echo "${SEMVER_REPOSITORY_URL:-https://github.com/fsaintjacques/semver-tool}"
}

semver::version() {
  # Get the current installed version
  "${SEMVER_INSTALL_PATH}/semver" --version
}

semver::latest() {
  if semver::is_outdated; then
    "> $(semver::version)"
  else
    semver::version
  fi
}

semver::title() {
  echo -n "SEMVER semver"
}