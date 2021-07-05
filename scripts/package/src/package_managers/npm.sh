#!/usr/bin/env bash

npm_title='🌈 npm'
NPM_DUMP_FILE_PATH="$DOTFILES_PATH/langs/js/npm/$(hostname -s).txt"

npm::is_available() {
  platform::command_exists npm
}

npm::install() {
  [[ -n "${1:-}" ]] && platform::command_exists npm && npm install --global "$1" 
}

npm::is_installed() {
  [[ -n "${1:-}" ]] && platform::command_exists npm && npm list --global "$1" &>/dev/null
}

npm::package_exists() {
  [[ -n "${1:-}" ]] && npm::is_available && npm search grunt | awk '{print $1}' | tail -n +2 | grep -q "^$1$"
}

npm::update_all() {
  outdated=$(npm -g outdated | tail -n +2)

  if [ -n "$outdated" ]; then
    echo "$outdated" | while IFS= read -r outdated_app; do
      package=$(echo "$outdated_app" | awk '{print $1}')
      current_version=$(echo "$outdated_app" | awk '{print $2}')
      new_version=$(echo "$outdated_app" | awk '{print $4}')

      info=$(npm view "$package")
      summary=$(echo "$info" | tail -n +3 | head -n 1)
      url=$(echo "$info" | tail -n +4 | head -n 1)

      output::write "🌈 $package"
      output::write "├ $current_version -> $new_version"
      output::write "├ $summary"
      output::write "└ $url"
      output::empty_line

      npm install -g "$package" 2>&1 | log::file "Updating npm app: $package"
    done
  else
    output::answer "Already up-to-date"
  fi
}

npm::dump() {
  local npm_prefix node_modules
  npm_prefix="$(npm config --json -g ls -l | jq -r '.prefix' || echo -n)"
  node_modules="${npm_prefix:-/usr/local}/lib/node_modules"
  NPM_DUMP_FILE_PATH="${1:-$NPM_DUMP_FILE_PATH}"

  if package::common_dump_check npm "$NPM_DUMP_FILE_PATH"; then
    find "$node_modules" -maxdepth 1 -mindepth 1 -type d -print0 | xargs -0 -I _ basename _ | grep -v npm | tee "$NPM_DUMP_FILE_PATH" | log::file "Exporting ${npm_title} packages"

    return 0
  fi

  return 1
}

npm::import() {
  NPM_DUMP_FILE_PATH="${1:-$NPM_DUMP_FILE_PATH}"

  if package::common_import_check npm "$NPM_DUMP_FILE_PATH"; then
    xargs -I_ npm install -g _ <"$NPM_DUMP_FILE_PATH" | log::file "Importing ${npm_title} packages"
  fi

  return 1
}
