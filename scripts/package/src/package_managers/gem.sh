#!/usr/bin/env bash

#shellcheck disable=SC2034
gem_title='♦️  gem'

if command -v gem &> /dev/null; then
  [[ -z "${GEM_HOME:-}" ]] && export GEM_HOME="${HOME}/.gem"

  # Path GEM HOME does not exist in PATH
  PATH="$(command -v gem env gempath)${PATH:+:$PATH}"
fi

gem::is_available() {
  platform::command_exists gem
}

gem::install() {
  [[ -n "${1:-}" ]] && gem::is_available && gem install "$@"
}

gem::is_installed() {
  [[ -z "${1:-}" ]] && return 1
  ! gem::is_available && return 1
  gem list | awk '{print $1}' | grep -q "^${1}$" || return 1

  if [[ $# -gt 1 ]]; then
    gem::is_installed "${@:2}" || return 1
  fi
}

gem::package_exists() {
  [[ -z "${1:-}" ]] && return 1
  ! gem::is_available && return 1

  gem query -r "$1" | awk '{print $1}' | grep -q "^${1}$"
}

gem::self_update() {
  gem::is_available && gem update --system  | log::file "Updating ${gem_title}"
}

gem::update_apps() {
  ! gem::is_available && return 1
  outdated=$(gem outdated)

  if [ -n "$outdated" ]; then
    echo "$outdated" | while IFS= read -r outdated_app; do
      package=$(echo "$outdated_app" | awk '{print $1}')
      current_version=$(echo "$outdated_app" | awk '{print $2}' | sed 's/(//g')
      new_version=$(echo "$outdated_app" | awk '{print $4}' | sed 's/)//g')

      output::write "♦️  $package"
      output::write "└ $current_version -> $new_version"
      output::empty_line

      gem update "$package" 2>&1 | log::file "Updating ${gem_title} app: $package"
    done
  else
    output::answer "Already up-to-date"
  fi
}

gem::update_all() {
  gem::self_update
  gem::update_apps
}

gem::cleanup() {
  gem::is_available && gem cleanup
}
