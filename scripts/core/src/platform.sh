platform::command_exists() {
  type "$1" >/dev/null 2>&1
}

platform::get_os() {
  echo "$OSTYPE" | tr '[:upper:]' '[:lower:]'
}

platform::get_arch() {
  local architecture=""
  case $(uname -m) in
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
  [[ "$(platform::get_arch)" == "arm" ]]
}

platform::is_macos() {
  [[ "$(platform::get_os)" == "Darwin" ]]
}

platform::is_macos_arm() {
  platform::is_macos && platform::is_arm
}

platform::is_linux() {
  [[ "$(uname -s)" == "Linux" ]]
}

platform::is_wsl() {
  grep -qEi "(Microsoft|WSL|microsoft)" /proc/version &>/dev/null
}

platform::is_bsd() {
  platform::is_macos || [[ "$OSTYPE" == *"bsd"* ]]
}

platform::os() {
  local os="unknown"

  if platform::is_macos; then
    os="mac"
  elif platform::is_linux; then
    os="linux"
  elif platform::is_wsl; then
    os="wsl-linux"
  fi

  echo "$os"
}

platform::wsl_home_path() {
  wslpath "$(wslvar USERPROFILE 2>/dev/null)"
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
  if command -v semver &>/dev/null; then
    SEMVER_BIN="$(command -v "semver")"
  elif [[ -f "${SLOTH_PATH:-$DOTLY_PATH}/modules/semver-tool/src/semver" ]]; then
    SEMVER_BIN="${SLOTH_PATH:-$DOTLY_PATH}/modules/semver-tool/src/semver"
  else
    return 1
  fi

  "$SEMVER_BIN" "$@"
}
