#!/usr/bin/env bash

brew_title='🍺 Brew'

brew::title() {
  echo -n "🍺 Brew"
}

brew::is_available() {
  platform::command_exists brew
}

brew::install() {
  local force=false packages
  ! brew::is_available && return 1

  if [[ $* == *--force* ]]; then
    force=true
  fi

  readarray -t packages < <(array::substract "--force" "$@")

  if array::exists_value "docpars" "${packages[@]}"; then
    readarray -t packages < <(array::substract "docpars" "${packages[@]}")
    packages+=("denisidoro/tools/docpars")
    brew tap "denisidoro/tools"
  fi

  if $force; then
    brew install --force "${packages[@]}"
  else
    brew install "${packages[@]}"
  fi
}

brew::force_install() {
  local _args
  readarray -t _args < <(array::substract "--force" "$@")
  brew unlink "${_args[@]}" > /dev/null 2>&1 || true
  brew reinstall "${_args[@]}"
}

brew::uninstall() {
  [[ $# -gt 0 ]] && brew::is_available && brew uninstall "$@"
}

brew::package_exists() {
  [[ -n "${1:-}" ]] && brew::is_available && brew info "$1" > /dev/null 2>&1
}

brew::is_installed() {
  ! brew::is_available && return 1

  platform::command_exists brew && brew list --formula "$@" > /dev/null 2>&1 && return
  platform::command_exists brew && brew list --cask "$@" > /dev/null 2>&1 && return

  return 1
}

brew::update_all() {
  brew::self_update
  brew::update_apps
}

brew::self_update() {
  brew::is_available && brew update 2>&1 | log::file "Updating ${brew_title}"
}

brew::update_apps() {
  ! brew::is_available && return 1
  local outdated_apps outdated_app outdated_app_info app_new_version app_old_version app_info app_url
  readarray -t outdated_apps < <(brew outdated | awk '{print $1}')

  if [ ${#outdated_apps[@]} -gt 0 ]; then
    for outdated_app in "${outdated_apps[@]}"; do
      outdated_app_info=$(brew info "$outdated_app")

      app_new_version=$(echo "$outdated_app_info" | head -1 | sed "s|$outdated_app: ||g")
      app_old_version=$(brew list "$outdated_app" --versions | sed "s|$outdated_app ||g")
      app_info=$(echo "$outdated_app_info" | head -2 | tail -1)
      app_url=$(echo "$outdated_app_info" | head -3 | tail -1 | head -1)

      output::write "🍺 $outdated_app"
      output::write "├ $app_old_version -> $app_new_version"
      output::write "├ $app_info"
      output::write "└ $app_url"
      output::empty_line

      brew upgrade "$outdated_app" 2>&1 | log::file "Updating ${brew_title} app: $outdated_app" || continue
    done
  else
    output::solution "Already up-to-date"
  fi

  return 0
}

brew::cleanup() {
  ! brew::is_available && return 1
  brew cleanup -s
  brew cleanup --prune=all
  output::answer "${brew_title} cleanup complete"
}

brew::dump() {
  ! brew::is_available && return 1
  HOMEBREW_DUMP_FILE_PATH="${1:-$HOMEBREW_DUMP_FILE_PATH}"

  if package::common_dump_check brew "$HOMEBREW_DUMP_FILE_PATH"; then
    brew bundle dump --file="$HOMEBREW_DUMP_FILE_PATH" --force | log::file "Exporting $brew_title packages"
    brew bundle --file="$HOMEBREW_DUMP_FILE_PATH" --force cleanup || true

    return 0
  fi

  return 1
}

brew::import() {
  ! brew::is_available && return 1
  HOMEBREW_DUMP_FILE_PATH="${1:-$HOMEBREW_DUMP_FILE_PATH}"

  if package::common_import_check brew "$HOMEBREW_DUMP_FILE_PATH"; then
    brew bundle install --file="$HOMEBREW_DUMP_FILE_PATH" | log::file "Importing $brew_title packages"

    return 0
  fi

  return 1
}
