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

dnf::dump() {
  DNF_DUMP_FILE_PATH="${1:-$DNF_DUMP_FILE_PATH}"

  if package::common_dump_check apt "$DNF_DUMP_FILE_PATH"; then
    dnf repoquery --qf '%{name}' --userinstalled \
      | grep -v -- '-debuginfo$' \
      | grep -v '^\(kernel-modules\|kernel\|kernel-core\|kernel-devel\)$' | tee "$DNF_DUMP_FILE_PATH" | log::file "Exporting ${dnf_title} packages"

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
