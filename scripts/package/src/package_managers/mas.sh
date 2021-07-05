#!/usr/bin/env bash

mas_title='🍎 App Store'

mas::is_available() {
  platform::command_exists mas
}

mas::is_installed() {
  [[ -n "${1:-}" ]] && mas::is_available && mas list | awk '{print $2}' | grep -qi "^${1}$"
}

mas::package_exists() {
  [[ -n "${1:-}" ]] && mas::is_available && mas search "$1" | awk '{NF--; $1=""};$NF' | sed 's/^ //g' | grep -i "^${1}$"
}

mas::install() {
  [[ -n "${1:-}" ]] && mas::is_available && mas lucky "$1"
}

mas::update_all() {
  local outdated row app_id app_name app_new_version app_old_version app_url app_list_line
  mapfile -t outdated < <(mas outdated)

  if [[ ${#outdated[@]} -eq 0 ]]; then
    output::answer "Already up-to-date"
  else
    for row in "${outdated[@]}"; do
      app_id="$(echo "$row" | awk '{print $1}')"
      app_name="${row//$app_id /}"
      app_list_line=$(mas list | awk '{print $1}' | grep -n "^$app_id$" | cut -d ':' -f 1)
      app_old_version=$(mas list | head -n "$app_list_line" | tail -n 1 | awk '{print $NF}' | sed 's/[(|)]//g')
      app_new_version=$(mas info "$app_id" | head -n 1 | awk 'NF{NF--};{print $NF}')

      app_url=$(mas info "$app_id" | tail -n 1 | sed 's/From://g' | xargs)

      output::write "🍎 $app_name"
      output::write "├ $app_old_version -> $app_new_version"
      output::write "└ $app_url"
      output::empty_line
      mas upgrade "$app_id" | log::file "Updating ${mas_title} app: ${app_name}"
    done
  fi
}
