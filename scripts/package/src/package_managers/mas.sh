#!/usr/bin/env bash

mas::is_available() {
  platform::command_exists mas
}

mas::is_installed() {
  if
    [[ -z "${1:-}" ]] ||
    ! mas::is_available
  then
    return 1
  fi

  mas list | awk '{print $2}' | grep -qi "^xcode$"
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
      app_new_version=$(mas info "$app_id" | head -n 1 | awk 'NF{NF-=1};{print $NF}')
      
      app_url=$(mas info "$app_id" | tail -n 1 | sed 's/From://g' | xargs)

      output::write "🍺 $app_name"
      output::write "├ $app_old_version -> $app_new_version"
      output::write "└ $app_url"
      output::empty_line
    done
  fi
}
