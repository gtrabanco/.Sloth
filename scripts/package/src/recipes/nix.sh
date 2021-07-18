#!/usr/bin/env bash

nix::execute_from_url() {
  [[ -z "${1:-}" ]] && return 1
  local -r url="$1"
  shift
  if platform::command_exists curl; then
    sh <(curl -L "$url") --no-daemon "$@" 2>&1
  elif platform::command_exists wget; then
    sh <(curl -q0 - "$url") --no-daemon "$@" 2>&1
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

nix::install() {
  local -r nix_install_script="https://nixos.org/nix/install"

  case "$(uname -s).$(uname -m)" in
    Linux.x86_64 | Linux.i?86 | Linux.aarch64 | Darwin.x86_64 | Darwin.arm64)
      # Can be installed
      ;;
    *)
      output::error "Nix is not compatible with your system"
      return 1
      ;;
  esac

  if nix::macos_version_apfs; then
    output::answer "Installing macOS APFS version of nix package manager"
    nix::execute_from_url "$nix_install_script" --darwin-use-unencrypted-nix-store-volume
  else
    output::answer "Installing nix package manager"
    nix::execute_from_url "$nix_install_script"
  fi

  if [[ -r "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
    #shellcheck disable=SC1091
    . "${HOME}/.nix-profile/etc/profile.d/nix.sh"
  fi
}

nix::uninstall() {
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
    # If you are on macOS, you will need to run:
    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
    sudo rm /Library/LaunchDaemons/org.nixos.nix-daemon.plist
    output::write "To finish the installation you must manually do these steps:"
    output::answer "1. Remove the entry from fstab using \`sudo vifs\`"
    output::answer "2. Locate the volumen that mounts \`/Nix\` by executing \`diskutil apfs list\`."
    output::answer "3. Destroy the data volume using \`diskutil apfs deleteVolume <disk> (<disk> should be somthing similar to \`disk1s7\`)\`"
    output::answer "4. Execute \` sudo vim /etc/synthetic.conf\` and remove the 'nix' line or remove the entire file \`sudo rm -f /etc/synthetic.conf\`"
  fi

  ! nix::is_installed
}

nix::is_installed() {
  platform::command_exists nix
}
