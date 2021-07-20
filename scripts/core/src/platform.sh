#!/usr/bin/env bash

#
# If you need more system information, consider to add neofetch as submodule
#   https://github.com/dylanaraps/neofetch
#

if [[ -z "${SLOTH_OS:-}" || -z "${SLOTH_ARCH}" ]]; then
  #shellcheck disable=SC2034,SC2207
  [[ -z "${SLOTH_UNAME:-}" ]] && SLOTH_UNAME=($(uname -sm))
  if [[ -n "${SLOTH_UNAME[0]:-}" ]]; then
    SLOTH_OS="${SLOTH_UNAME[0]}"
    SLOTH_ARCH="${SLOTH_UNAME[1]}"
  else
    SLOTH_OS="${SLOTH_UNAME[1]}"
    SLOTH_ARCH="${SLOTH_UNAME[2]}"
  fi
fi
export SLOTH_UNAME SLOTH_OS SLOTH_ARCH

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
  echo "${SLOTH_OS}" | tr '[:upper:]' '[:lower:]'
}

platform::get_arch() {
  local architecture="unknown"
  case "${SLOTH_ARCH}" in
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
      if platform::is_macos && sysctl hw.optional.x86_64 | grep -q ': 1$'; then
        architecture="amd64"
      else
        architecture="x86"
      fi
      ;;
  esac

  echo "$architecture"
}

platform::is_arm() {
  [[ $(platform::get_arch) == "arm" ]]
}

platform::is_macos() {
  [[ $SLOTH_OS == "Darwin"* ]]
}

platform::is_macos_arm() {
  platform::is_macos && platform::is_arm
}

platform::is_linux() {
  [[ $SLOTH_OS == *"Linux"* ]]
}

platform::is_wsl() {
  grep -qEi "(Microsoft|WSL|microsoft)" /proc/version &> /dev/null || grep -q -F 'Microsoft' /proc/sys/kernel/osrelease
}

platform::is_bsd() {
  [[ $SLOTH_OS == *"BSD"* ]]
}

platform::os() {
  # Should never show unknown but expect the unexpected ;)
  local os="unknown"

  case "$(platform::get_os)" in
    darwin*)
      os="macos"
      ;;
    linux | gnu)
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
      os="$SLOTH_OS"
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
