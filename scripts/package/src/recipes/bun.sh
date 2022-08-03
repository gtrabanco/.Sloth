#!/usr/bin/env bash
#? Author:
#?   Gabriel Trabanco Llano <gtrabanco@users.noreply.github.com>
#? This file contains instrucctions to install the package bun. If you
#? want install fish completions for bun, you should do it manually or
#? use the script in the official bun page, bun.sh.
#? v1.0.0

GITHUB_BASE_URL="${GITHUB_BASE_URL:-https://github.com}"
BUN_GITHUB_REPOSITORY="${BUN_GITHUB_REPOSITORY:-oven-sh/bun}"
BUN_INSTALL="${BUN_INSTALL:-${HOME}/.bun}"
BUN_BIN_DIR="${BUN_BIN_DIR:-${BUN_INSTALL}/bin}"
BUN_BIN_FILE="${BUN_BIN_FILE:-${BUN_BIN_DIR}/bun}"
BUN_COMPLETIONS_INIT_SCRIPT="${BUN_COMPLETIONS_INIT_SCRIPT:-bun-completions}"
BUN_VERSION="${BUN_VERSION:-latest}"

bun::target() {
  case $(uname -sm) in
  "Darwin x86_64")
    if sysctl sysctl.proc_translated >/dev/null 2>&1; then
      target="darwin-aarch64"
    elif [[ $(sysctl -n machdep.cpu.features) != *avx2* ]]; then
      target="darwin-x64-baseline"
    else
      target="darwin-x64"
    fi
    ;;
  "Darwin arm64") target="darwin-aarch64" ;;
  "Linux aarch64") target="linux-aarch64" ;;
  "Linux arm64") target="linux-aarch64" ;;
  "Linux x86_64") target="linux-x64" ;;
  *) target="linux-x64" ;;
  esac

  if [[ $target == linux-x64 ]] && grep --no-messages avx2 /proc/cpu; then
    target="linux-x64-baseline"
  fi

  printf "%s" "$target"
}

bun::filename() {
  printf "bun-%s.zip" "$(bun::target)"
}

#shellcheck disable=SC2120
bun::download_url_version() {
  dot::load_library "github"
  local -r version="$(echo "${1:-${BUN_VERSION:-latest}}" | awk '{gsub(/^(bun-)?[vV]/, "",$0); print $0}' | xargs)"
  local -r filename="$(bun::filename)"

  if [[ "$version" == "latest" ]]; then
    printf "%s" "${GITHUB_BASE_URL:-https://github.com}/${BUN_GITHUB_REPOSITORY}/releases/latest/download/${filename}" | xargs
  else
    local -r files="$(github::get_release_download_url_tag "$BUN_GITHUB_REPOSITORY" "bun-v${version##bun-[vV]}")"
    local -r result="$(printf "%s" "$(echo "$files" | grep "$filename")" | xargs)"

    if [ -z "$result" ]; then
      printf "%s" "$files" | grep -E "${filename//\-baseline/}"
    else
      printf "%s" "$result"
    fi
  fi
}

bun::install_script() {
  script::depends_on unzip
  local -r download_url="$(bun::download_url_version "${BUN_VERSION:-latest}")"
  local -r filename="$(basename "$download_url")"
  local -r tmp_path="$(mktemp -d)"

  echo "Downloading ${download_url} to ${tmp_path}/${filename%%.*}"
  open "$tmp_path"
  sleep 5
  curl --fail --location --silent --output "${tmp_path}/${filename}" "$download_url"
  unzip -o "${tmp_path}/${filename}" -d "${tmp_path}"
  mkdir -p "${BUN_BIN_DIR}"
  mv "${tmp_path}/${filename%%.*}/bun" "$BUN_BIN_DIR"
  chmod u+x "$BUN_BIN_FILE"

  dot::add_to_path_file "$BUN_BIN_DIR"
}

bun::init_script() {
  cat <<EOF
#!/usr/bin/env bash

if [ -s "${HOME}/.bun/_bun" ]; then
  #shellcheck disable=SC1091
  . "${HOME}/.bun/_bun"
fi

EOF
}

bun::create_enable_init_script() {
  dot::load_library init init

  if ! init::exists_script "${BUN_COMPLETIONS_INIT_SCRIPT}"; then
    bun::init_script | tee "${DOTFILES_INIT_SCRIPTS_PATH}/${BUN_COMPLETIONS_INIT_SCRIPT}" >/dev/null 2>&1
  fi

  init::enable "${BUN_COMPLETIONS_INIT_SCRIPT}"
}

bun::disable_init_script() {
  dot::load_library init init

  if init::exists_script "${BUN_COMPLETIONS_INIT_SCRIPT}"; then
    init::disable "${BUN_COMPLETIONS_INIT_SCRIPT}"
  fi
}

# REQUIRED FUNCTION
bun::is_installed() {
  platform::command_exists bun || [[ -x "$BUN_BIN_FILE" ]]
}

# REQUIRED FUNCTION
bun::install() {
  if [[ " $* " == *" --force "* ]]; then
    # output::answer "\`--force\` option is ignored with this recipe"
    bun::force_install "$@" &&
      return
  else
    # Install using a package manager, in this case auto but you can choose brew, pip...
    bun::install_script

    if bun::is_installed; then
      bun::create_enable_init_script
    fi

    bun::is_installed &&
      output::solution "bun installed" &&
      return 0
  fi

  output::error "bun could not be installed"
  return 1
}

# OPTIONAL
bun::uninstall() {
  rm -rf "${BUN_INSTALL}"

  if command -v bun &>/dev/null; then
    dirname "$(dirname "$(command -v bun)")" | xargs rm -rf
  fi

  # Disable init script if it exists and is enable
  bun::disable_init_script
  dot::remove_from_path_file "$BUN_BIN_DIR"

  ! bun::is_installed &&
    output::solution "bun uninstalled" &&
    return 0

  ourput::error "bun could not be uninstalled"
  return 1
}

# OPTIONAL
bun::force_install() {
  local _args
  mapfile -t _args < <(array::substract "--force" "$@")

  bun::uninstall "${_args[@]}"
  bun::install "${_args[@]}"

  bun::is_installed "${_args[@]}"
}

# ONLY REQUIRED IF YOU WANT TO IMPLEMENT AUTO UPDATE WHEN USING `up` or `up registry`
# Description, url and versions only be showed if defined

bun::upgrade() {
  ! bun::is_installed && return 1
  bun upgrade >/dev/null 2>&1
  return $?
}

bun::description() {
  echo "Bundle, transpile, install and run JavaScript & TypeScript projects — all in Bun. Bun is a new JavaScript runtime with a native bundler, transpiler, task runner and npm client built-in.."
}

bun::url() {
  # Please modify
  echo "https://bun.sh"
}

bun::version() {
  # Get the current installed version
  bun --version
}

bun::latest() {
  dot::load_library github

  bun_remote_version=$(curl --silent "$(github::get_api_url oven-sh/bun "releases/latest")" | jq -r '.tag_name')
  printf "%s\n" "${bun_remote_version##*v}"
}

bun::is_outdated() {
  local -r latest="$(bun::latest)"
  local -r installed="$(bun::version)"
  [[ -z "$installed" || -z "$latest" ]] && return 1
  [[ $(platform::semver_compare "$installed" "$latest") -eq -1 ]]
}

bun::title() {
  echo -n "🧅 bun"
}
