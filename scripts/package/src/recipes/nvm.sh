#!/usr/bin/env bash
#shellcheck disable=SC1091

# Try to load nvm
. "${SLOTH_PATH:-${DOTLY_PATH:-}}/shell/init.scripts/nvm"

nvm::install_script() {
  PROFILE="/dev/null" curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v$(nvm::latest)/install.sh" | bash
}

nvm::finish_install() {
  nvm install --lts --latest-npm
  sleep 1s
  nvm use --lts
  sleep 1s
  nvm alias default node
}

nvm::is_installed() {
  if
    [[ -z "${NVM_DIR:-}" && -z "${XDG_CONFIG_HOME:-}" ]] &&
      command -v brew &> /dev/null &&
      [[ -n "$(brew --prefix nvm)" ]]
  then
    NVM_DIR="$(brew --prefix nvm)"
  elif [[ -z "${NVM_DIR:-}" && -z "${XDG_CONFIG_HOME:-}" ]]; then
    NVM_DIR="$HOME/.nvm"
  elif [[ -z "${NVM_DIR:-}" ]]; then
    NVM_DIR="${XDG_CONFIG_HOME}/nvm"
  fi
  export NVM_DIR

  [[ -s "${NVM_DIR}/nvm.sh" ]] && platform::command_exists nvm
}

nvm::install() {
  script::depends_on curl clt

  if [[ "$*" == *"--force"* ]]; then
    output::answer "Force detected, uninstall first and try a reinstall"
    nvm::uninstall
  fi

  if ! nvm::is_installed; then
    nvm::install_script
  fi

  if nvm::is_installed && [[ -n "${DOTFILES_PATH:-}" ]]; then
    nvm::finish_install
    ln -sf "${SLOTH_PATH:-${DOTLY_PATH:-}}/shell/init.scripts/nvm" "${DOTFILES_PATH:-}/shell/init.scripts-enabled/nvm"
    #shellcheck disable=SC1091
    . "${SLOTH_PATH:-${DOTLY_PATH:-}}/shell/init.scripts/nvm" && output::solution "You can use nvm, node, npm and npx now"
    output::answer "Nvm, node, npm and npx installed"
    return 0
  elif nvm::is_installed; then
    nvm::finish_install
    output::empty_line
    output::answer "You should add these lines to your \`.bashrc\` & \`.zshrc\` manully because your \`DOTFILES_PATH\` could not be detected"
    output::write "    \`. \"${SLOTH_PATH:-${DOTLY_PATH:-}}/shell/init.scripts/nvm\"\`"
    output::empty_line

    #shellcheck disable=SC1091
    output::answer "Nvm, node, npm and npx installed"
    return 0
  fi

  return 1
}

nvm::uninstall() {
  [[ -d "${NVM_DIR:-}" ]] && rm -rf "${NVM_DIR:-}"
  [[ -e "${DOTFILES_PATH:-}/shell/init.scripts-enabled/nvm" ]] && rm -rf "${DOTFILES_PATH:-}/shell/init.scripts-enabled/nvm"
  ! nvm::is_installed && output::answer "nvm uninstalled" && return 0

  output::error "NVM could not be uninstalled"
  return 1
}

nvm::is_outdated() {
  ! platform::command_exists nvm && return 1
  local -r installed="$(nvm --version)"
  local -r latest="$(nvm::latest)"
  [[ -z "$installed" || -z "$latest" ]] && return 1
  [[ $(platform::semver_compare "$installed" "$latest") -eq -1 ]]
}

nvm::upgrade() {
  # Update only if nvm is installed
  platform::command_exists nvm && nvm::install_script
}

nvm::description() {
  echo "nvm is a version manager for node.js, designed to be installed per-user, and invoked per-shell."
}

nvm::url() {
  echo "https://nvm.sh"
}

nvm::version() {
  platform::command_exists nvm && nvm --version
}

nvm::latest() {
  # TODO when github.sh library will be implemented update this to use it
  curl --silent "https://api.github.com/repos/nvm-sh/nvm/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"v([^"]+)".*/\1/' || echo -n "0.38.0" # Fallback to latest known version
  # Fallback is added because is the latest version in the date this recipe was created
  # this allow to know at least one known latest when github api is not available
}

nvm::title() {
  echo -n "🟩 NVM"
}
