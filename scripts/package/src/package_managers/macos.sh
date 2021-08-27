#!/usr/bin/env bash
#shellcheck disable=SC2016,SC2116

macos_title='🍎 System MacOS'

macos::is_available() {
  platform::is_macos && command -vp softwareupdate &> /dev/null
}

macos::update_all() {
  macos::update_apps
}

macos::update_apps() {
  local IFS=$'\n'
  local app_info app_info_label app_info_name app_info_recommended app_info_version app_info_restart should_restart=false is_up_to_date=true
  local -r software_update="$(command -p softwareupdate --list 2> /dev/null)"

  #for app_info in $(echo "$software_update" | awk -F '[,:]' '$1~/(Label|Title)$/ {print $0}'); do
  for app_info in $(echo "$software_update"); do
    if echo "$app_info" | command -p grep -q -e '^\s*Title:.*'; then
      eval "$(echo "$app_info" | command -p awk -F '[,:]' 'function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s } { print "app_info_name=\""ltrim($2)"\""; print "app_info_version=\""ltrim($4)"\""; print "app_info_recommended=\""ltrim($6)"\""; print "app_info_restart=\""ltrim($8)"\"" }')"
      [[ -z "${app_info_label:-}" || -z "${app_info_name:-}" || "$app_info_label" != "$app_info_name"* ]] && continue

      output::write "🍎 $app_info_name"
      if [[ $app_info_recommended == "YES" ]]; then
        output::write "├ Update to $app_info_version"
        output::write "└ Recommended update to $app_info_version"
      else
        output::write "└ Update to $app_info_version"
      fi
      output::empty_line

      [[ $app_info_restart == "YES" ]] && should_restart=true

      command -p softwareupdate --agree-to-license --install "$app_info_label" 2>&1 | log::file "Updating ${macos_title} app: $app_info_name" && is_up_to_date=false
    elif echo "$app_info" | command -p grep -q -e '^* Label:'; then
      app_info_label="$(echo "$app_info" | awk -F ':' '$1~/\* Label/ {gsub(/^[ ]*/, "", $2); print $2}')"
    fi
  done

  if $should_restart; then
    output::write "You should reboot your system to finish the update"
  fi

  if $is_up_to_date; then
    output::answer "Already up-to-date"
  fi
}
