#!/usr/bin/env bash

#
# If you need more system information, consider to add neofetch as submodule
#   https://github.com/dylanaraps/neofetch
#

#shellcheck disable=SC2034,SC2207
DOTLY_UNAME=($(uname -sm))
if [[ -n "${DOTLY_UNAME[0]:-}" ]]; then
  DOTLY_OS="$(echo "${DOTLY_UNAME[0]}" | tr '[:upper:]' '[:lower:]')"
  DOTLY_ARCH="${DOTLY_UNAME[1]}"
else
  DOTLY_OS="$(echo "${DOTLY_UNAME[1]}" | tr '[:upper:]' '[:lower:]')"
  DOTLY_ARCH="${DOTLY_UNAME[2]}"
fi

platform::command_exists() {
  type "$1" > /dev/null 2>&1
}

platform::macos_version() {
  { platform::is_macos && sw_vers -productVersion; } || return
}

platform::macos_version_name() {
  local version_name="macOS"

  ! platform::is_macos && return

  case "$(platform::macos_version)" in
      "10.4"*) version_name="Mac OS X Tiger" ;;
      "10.5"*) version_name="Mac OS X Leopard" ;;
      "10.6"*) version_name="Mac OS X Snow Leopard" ;;
      "10.7"*) version_name="Mac OS X Lion" ;;
      "10.8"*) version_name="OS X Mountain Lion" ;;
      "10.9"*) version_name="OS X Mavericks" ;;
      "10.10"*) version_name="OS X Yosemite" ;;
      "10.11"*) version_name="OS X El Capitan" ;;
      "10.12"*) version_name="macOS Sierra" ;;
      "10.13"*) version_name="macOS High Sierra" ;;
      "10.14"*) version_name="macOS Mojave" ;;
      "10.15"*) version_name="macOS Catalina" ;;
      "11"*) version_name="macOS Big Sur" ;;
      "12"*) version_name="macOS Monterey" ;;
  esac

  echo "$version_name"
}

platform::get_os() {
  echo "$DOTLY_OS" | tr '[:upper:]' '[:lower:]'
}

platform::get_arch() {
  local architecture="unknown"
  case "$DOTLY_ARCH" in
    x86_64)
      architecture="amd64"
      ;;
    arm)
      architecture="arm"
      ;;
    ppc64)
      architecture="ppc64"
      ;;
    i?86)
      architecture="x86"
      ;;
  esac

  echo "$architecture"
}

platform::is_arm() {
  [[ $(platform::get_arch) == "arm" ]]
}

platform::is_macos() {
  [[ $DOTLY_OS == "darwin"* ]]
}

platform::is_macos_arm() {
  platform::is_macos && platform::is_arm
}

platform::is_linux() {
  [[ $DOTLY_OS == *"linux"* ]]
}

platform::is_wsl() {
  grep -qEi "(Microsoft|WSL|microsoft)" /proc/version &> /dev/null || grep -q -F 'Microsoft' /proc/sys/kernel/osrelease
}

platform::is_bsd() {
  [[ $DOTLY_OS == *"bsd"* ]]
}

platform::os() {
  # Should never show unknown but expect the unexpected ;)
  local os="unknown"

  case "$DOTLY_OS" in
    darwin*)
      os="macos"
      ;;
    linux|gnu)
      if platform::is_wsl; then
        os="wsl"
      else
        os="linux"
      fi
      ;;
    *bsd*)
      os="bsd"
      ;;
    *)
      os="$DOTLY_OS"
      ;;
  esac

  echo "$os"
}

platform::wsl_home_path() {
  wslpath "$(wslvar USERPROFILE 2> /dev/null)"
}

# It does not support beta, rc and similar suffix
platform::semver_compare() {
  platform::semver compare "${1//v/}" "${2//v/}"
}

# Equal version return false because there is not difference
platform::semver_is_minor_or_patch_update() {
  local diff_type
  diff_type="$(platform::semver diff "${1//v/}" "${2//v/}" | tr '[:upper:]' '[:lower:]')"
  [[ -n "${diff_type}" && "$diff_type" != "major" ]]
}

platform::semver() {
  local SEMVER_BIN=""
  if command -v semver &> /dev/null; then
    SEMVER_BIN="$(command -v "semver")"
  elif [[ -f "${SLOTH_PATH:-$DOTLY_PATH}/modules/semver-tool/src/semver" ]]; then
    SEMVER_BIN="${SLOTH_PATH:-$DOTLY_PATH}/modules/semver-tool/src/semver"
  else
    return 1
  fi

  "$SEMVER_BIN" "$@"
}
