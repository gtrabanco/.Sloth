#!/usr/bin/env bash

brew_title='🍺 Brew'

brew::is_available() {
  platform::command_exists brew
}

brew::install() {
  # Some aliases
  case "${1:-}" in
    "docpars") package="denisidoro/tools/docpars" ;;
    *) package="${1:-}" ;;
  esac

  brew install "$package"
}

brew::uninstall() {
  [[ $# -gt 0 ]] && brew uninstall "$@"
}

brew::package_exists() {
  [[ -n "${1:-}" ]] && brew info "$1" &> /dev/null
}

brew::is_installed() {
  platform::command_exists brew && brew list --formula "$@" &> /dev/null && return
  platform::command_exists brew && brew list --cask "$@" &> /dev/null && return

  return 1
}

brew::update_all() {
  brew::self_update
  brew::update_apps
}

brew::self_update() {
  brew update 2>&1 | log::file "Updating ${brew_title}"
}

brew::update_apps() {
  local outdated_apps outdated_app outdated_app_info app_new_version app_old_version app_info app_url
  outdated_apps=$(brew outdated)

  if [ -n "$outdated_apps" ]; then
    echo "$outdated_apps" | while IFS= read -r outdated_app; do
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

      brew upgrade "$outdated_app" 2>&1 | log::file "Updating ${brew_title} app: $outdated_app"
    done
  else
    output::answer "Already up-to-date"
  fi
}

brew::cleanup() {
  brew cleanup -s
  brew cleanup --prune=all
}

brew::dump() {
  HOMEBREW_DUMP_FILE_PATH="${1:-$HOMEBREW_DUMP_FILE_PATH}"

  if package::common_dump_check brew "$HOMEBREW_DUMP_FILE_PATH"; then
    brew bundle dump --file="$HOMEBREW_DUMP_FILE_PATH" --force | log::file "Exporting $brew_title packages"
    brew bundle --file="$HOMEBREW_DUMP_FILE_PATH" --force cleanup || true

    return 0
  fi

  return 1
}

brew::import() {
  HOMEBREW_DUMP_FILE_PATH="${1:-$HOMEBREW_DUMP_FILE_PATH}"

  if package::common_import_check brew "$HOMEBREW_DUMP_FILE_PATH"; then
    brew bundle install --file="$HOMEBREW_DUMP_FILE_PATH" | log::file "Importing $brew_title packages"

    return 0
  fi

  return 1
}
