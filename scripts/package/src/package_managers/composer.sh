#!/usr/bin/env bash

#shellcheck disable=SC2034
composer_title='🐘 Composer'

composer::title() {
  echo -n "🐘 Composer"
}

composer::is_available() {
  platform::command_exists composer
}

composer::update_all() {
  script::depends_on jq

  if [ -f "$HOME/.composer/composer.json" ]; then
    outdated=$(composer global outdated --direct -f json --no-ansi)
    total_outdated=$(echo "$outdated" | yq -p=json '.installed' | yq -p=json length)

    if [ 0 -ne "$total_outdated" ]; then
      echo "$outdated" | yq -p=json -cr '.installed | .[]' | while IFS= read -r dependency; do
        composer::update "$dependency"
      done
    else
      output::answer "Already up-to-date"
    fi
  else
    output::answer "There is no composer global file, process skipped"
  fi

}

composer::update() {
  name=$(echo "$1" | yq -p=json -r '.name')
  current_version=$(echo "$1" | yq -p=json -r '.version')
  new_version=$(echo "$1" | yq -p=json -r '.latest')
  summary=$(echo "$1" | yq -p=json -r '.description')
  url="https://packagist.org/packages/$name"

  output::write "🐘 $name"
  output::write "├ $current_version -> $new_version"
  output::write "├ $summary"
  output::write "└ $url"
  output::empty_line

  composer global require -W "$name"
}
