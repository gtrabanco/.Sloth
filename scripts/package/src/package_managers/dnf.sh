#!/usr/bin/env bash

#shellcheck disable=SC2034
dnf_title='▣ DNF'

dnf::is_available() {
  platform::command_exists dnf
}

dnf::install() {
  dnf::is_available && sudo dnf -y install "$@"
}

dnf::uninstall() {
  [[ $# -gt 0 ]] && dnf::is_available && dnf remove "$@"
}

dnf::is_installed() {
  local package
  if [[ $# -gt 1 ]]; then
    for package in "$@"; do
      if platform::command_exists rpm &&
        ! rpm -qa | grep -qw "$package"; then
        return 1
      fi
    done

    return 0
  else
    [[ -n "${1:-}" ]] && platform::command_exists rpm && rpm -qa | grep -qw "${1:-}"
  fi
}

dnf::package_exists() {
  ! dnf::is_available && return 1
  [[ -z "${1:-}" ]] && return 1
  local -r package_name="${1:-}"
  local -r arch="${SLOT_ARCH:-$(uname -m)}"
  dnf search -q "$package_name" 2> /dev/null | awk '{print $1}' | grep -qw "^${package_name}.${arch}"
}

dnf::cleanup() {
  dnf::is_available && dnf clean all
}

dnf::update_apps() {
  local outdated_app outdated_app_full_info outdated_app_name outdated_app_version outdated_app_info outdated_app_url

  for outdated_app in $(dnf::outdated_app); do
    outdated_app_name="${outdated_app%%.*}"
    outdated_app_full_info="$(dnf info "$outdated_app_name" | cut -d " " -f 3-)"

    outdated_app_version="$(echo "$outdated_app_info" | head -n 5 | tail -n 1)"
    outdated_app_info="$(outdated_app_full_info | head -n 9 | tail -n 1)"
    outdated_app_url="$(outdated_app_full_info | head -n 10 | tail -n 1)"

    output::write "▣ $outdated_app_name"
    output::write "├ $outdated_app_version -> latest"
    output::write "├ $outdated_app_info"
    output::write "└ $outdated_app_url"
    output::empty_line

    dnf update -y "$outdated_app_name"
  done
}

dnf::outdated_app() {
  ! dnf::is_available && return 1
  dnf check-update | awk '{print $1}'
}

dnf::update_all() {
  ! dnf::is_available && return 1
  dnf::update_apps
}

dnf::dump() {
  DNF_DUMP_FILE_PATH="${1:-$DNF_DUMP_FILE_PATH}"

  if package::common_dump_check apt "$DNF_DUMP_FILE_PATH"; then
    dnf repoquery --qf '%{name}' --userinstalled |
      grep -v -- '-debuginfo$' |
      grep -v '^\(kernel-modules\|kernel\|kernel-core\|kernel-devel\)$' | tee "$DNF_DUMP_FILE_PATH" | log::file "Exporting ${dnf_title} packages"

    return 0
  fi

  return 1
}

dnf::import() {
  DNF_DUMP_FILE_PATH="${1:-$DNF_DUMP_FILE_PATH}"

  if package::common_import_check apt "$DNF_DUMP_FILE_PATH"; then
    xargs sudo dnf -y install < "$DNF_DUMP_FILE_PATH" | log::file "Importing ${dnf_title} packages"
  fi
}
