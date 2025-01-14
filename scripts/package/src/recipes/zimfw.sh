#!/usr/bin/env bash

# ZIMFW_GIT_REPOSITORY_URL="git@github.com:zimfw/zimfw.git"
ZIMFW_GIT_REPOSITORY_URL="https://github.com/zimfw/zimfw.git"

zimfw::fix_zim_home() {
  if [[ "$ZIM_HOME" == *"modules/zimfw"* ]]; then
    unset ZIM_HOME
  fi

  export ZIM_HOME="${ZIM_HOME:-${DOTFILES_PATH}\/shell\/zsh\/.zimfw}"
}

zimfw::fix_zim_home

zimfw::is_installed() {
  [[ -r "${ZIM_HOME}/zimfw.zsh" ]]
}

zimfw::install() {
  zimfw::fix_zim_home

  script::depends_on curl

  dot::load_library "templating.sh" "core"

  curl -fsSL --create-dirs -o "${ZIM_HOME}/zimfw.zsh" "https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh" 2>&1

  zsh "${ZIM_HOME}/zimfw.zsh" install 2>&1

  git::add_to_gitignore "${DOTFILES_PATH}/.gitignore" "${ZIM_HOME//${DOTFILES_PATH}\//}" || true

  if zimfw::is_installed; then
    templating::modify_bash_file_variable "${DOTFILES_PATH}/shell/zsh/.zshenv" "ZIM_HOME" "${ZIM_HOME//$DOTFILES_PATH/\${DOTFILES_PATH\}}" || true
  else
    return 1
  fi
}

zimfw::uninstall() {
  zimfw::fix_zim_home

  rm -rf "${ZIM_HOME}"
}

zimfw::is_outdated() {
  [[ $(platform::semver_compare "$(zimfw::latest)" "$(zimfw::version)") -lt 0 ]]
}

zimfw::upgrade() {
  zsh -c ". \"${HOME}/.zshrc\"; zimfw clean; zimfw update; zimfw upgrade; zimfw compile"
}

zimfw::description() {
  echo "Zim is a Zsh configuration framework with blazing speed and modular extensions"
}

zimfw::url() {
  echo "https://zimfw.sh"
}

zimfw::version() {
  zsh -c ". \"${HOME}/.zshrc\"; zimfw version"
}

zimfw::latest() {
  git::remote_latest_tag_version "${ZIMFW_GIT_REPOSITORY_URL:-git@github.com:zimfw/zimfw.git}" "v*.*.*"
}

zimfw::title() {
  echo -n "ZIM:FW"
}
