#!/usr/bin/env bash

nix::execute_from_url() {
  [[ -z "${1:-}" ]] && return 1
  local -r url="$1"
  shift
  if platform::command_exists curl; then
    sh <(curl -L "$url") "$@" 2>&1
  elif platform::command_exists wget; then
    sh <(curl -q0 - "$url") "$@" 2>&1
  else
    script::depends_on curl

    if platform::command_exists curl; then
      nix::execute_from_url "$url"
    else
      return 1
    fi
  fi
}

nix::macos_version_apfs() {
  ! platform::is_macos && return 1

  case "$(platform::macos_version)" in
    "10.4"* | "10.5"* | "10.6"* | "10.7"* | "10.8"* | "10.9"* | "10.10"* | "10.11"* | "10.12" | "10.13" | "10.14") return 1 ;;
  esac
}

nix::delete_rc_modifications_by_nix() {
  local file
  local -r pattern="/# added by Nix installer/d"
  local -r files=(
    "${HOME}/.bash_profile"
    "${HOME}/.zshenv"
    "/etc/bashrc"
    "/etc/zshrc"
  )

  for file in "${files[@]}"; do
    wrapped::sed -i "$pattern" "$file"
  done
}

nix::menu() {
  local PS3 title
  [[ $# -lt 2 ]] && return
  title="$1"; shift

  output::write "$title"
  PS3="Choose an option: "
  select opt in "$@"; do
    echo "$opt"
    return
  done
}

nix::install() {
  local option single_user=true
  local -r nix_install_script="https://nixos.org/nix/install"

  case "$(uname -s).$(uname -m)" in
    Linux.x86_64 | Linux.i?86 | Linux.aarch64 | Darwin.x86_64 | Darwin.arm64)
      # Can be installed
      # Avoid modify the bash profile and zsh env
      export NIX_INSTALLER_NO_MODIFY_PROFILE=1
      if [[ "${DOTLY_ENV:-PROD}" != "CI" ]]; then
        option="$(nix::menu "Select what kind of installation do you want" "Single user (default)" "Multi user")"
        case "$option" in
          "Multi user") single_user=false ;;
          *) single_user=true ;;
        esac
      fi
      ;;
    *)
      output::error "Nix is not compatible with your system"
      return 1
      ;;
  esac

  if nix::macos_version_apfs; then
    output::answer "Installing macOS APFS version of nix package manager"
    if $single_user; then
      nix::execute_from_url "$nix_install_script" --no-daemon --darwin-use-unencrypted-nix-store-volume
    else
      nix::execute_from_url "$nix_install_script" --daemon --darwin-use-unencrypted-nix-store-volume
    fi
  else
    output::answer "Installing nix package manager"
    if $single_user; then
      nix::execute_from_url "$nix_install_script" --no-daemon
    else
      nix::execute_from_url "$nix_install_script" --daemon
    fi
  fi

  if [[ -r "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
    #shellcheck disable=SC1091
    dot::load_library "${HOME}/.nix-profile/etc/profile.d/nix.sh"
  elif [[ -r "/etc/profile.d/nix.sh" ]]; then
    dot::load_library "/etc/profile.d/nix.sh"
  else
    output::error "Nix was not installed"
    return 1
  fi

  if platform::command_exists nix-shell; then
    output::answer "Nix initial configuration"
    nix-shell -p nix-info --run "nix-info -m"
  fi

  output::solution "Nix for single user was installed sucessfully"
}

nix::uninstall() {
  # TODO Automate single user uninstall
  # TODO Adds multi user uninstall
  if sudo -v; then
    sudo rm -rf /etc/profile/nix.sh /etc/nix /nix ~root/.nix-profile ~root/.nix-defexpr ~root/.nix-channels
    rm -rf "${HOME}/.nix-profile" "${HOME}/.nix-defexpr" "${HOME}/.nix-channels" &> /dev/null
  fi

  if platform::is_linux; then
    # If you are on Linux with systemd, you will need to run:
    sudo systemctl stop nix-daemon.socket
    sudo systemctl stop nix-daemon.service
    sudo systemctl disable nix-daemon.socket
    sudo systemctl disable nix-daemon.service
    sudo systemctl daemon-reload
  elif platform::is_macos; then
    if ! sudo -v; then
      output::error "You need to run this script with sudo"
      return 1
    fi
    # If you are on macOS, you will need to run:
    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
    sudo rm /Library/LaunchDaemons/org.nixos.nix-daemon.plist
    local -r disk="$(mount | awk '$3 == "/nix" {print $1}')"
    if [[ -n "$disk" ]]; then
      diskutil apfs deleteVolume "$disk"
    fi

    output::write "Tried to have it done automatically but check these steps are done and if not, do it automatically:"
    output::answer "1. Remove the entry from fstab using \`sudo vifs\`"
    output::answer "2. Locate the volumen that mounts \`/Nix\` by executing \`diskutil apfs list\`."
    output::answer "3. Destroy the data volume using \`diskutil apfs deleteVolume <disk> (<disk> should be somthing similar to \`disk1s7\`)\`"
    output::answer "4. Execute \` sudo vim /etc/synthetic.conf\` and remove the 'nix' line or remove the entire file \`sudo rm -f /etc/synthetic.conf\`"
  fi

  delete_rc_modifications_by_nix

  if [[ $(wc -l < /etc/synthetic.conf) -gt 1 ]]; then
    sudo wrapped::sed --silent -i '/^nix/d' /etc/synthetic.conf
  else
    sudo rm -f /etc/synthetic.conf
  fi

  sudo wrapped::sed --silent -i '/^LABEL=Nix/d' '/etc/fstab'

  ! nix::is_installed
}

nix::is_installed() {
  platform::command_exists nix
}
