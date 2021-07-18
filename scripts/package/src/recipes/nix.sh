#!/usr/bin/env bash

nix::execute_from_url() {
  [[ -z "${1:-}" ]] && return 1
  local -r url="$1"
  shift
  if platform::command_exists curl; then
    sh <(curl -L "$url") --no-daemon "$@"
  elif platform::command_exists wget; then
    sh <(curl -q0 - "$url") --no-daemon "$@"
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
    "10.4"*| "10.5"* | "10.6"* | "10.7"* | "10.8"* | "10.9"* | "10.10"* | "10.11"* | "10.12" | "10.13" | "10.14") return 1
  esac
}

nix::install() {
  local -r nix_install_script="https://nixos.org/nix/install"

  case "$(uname -s).$(uname -m)" in
    linux.x86_64 | linux.i?86 | linux.aarch64 | darwin.x86_64 | darwin.arm64)
      # Can be installed
      ;;
    *)
      return 1
      ;;
  esac

  if nix::macos_version_apfs; then
    nix::execute_from_url "$nix_install_script" --darwin-use-unencrypted-nix-store-volume
  else
    nix::execute_from_url "$nix_install_script"
  fi
}

nix::uninstall() {
  sudo -v
  sudo rm -rf /etc/profile/nix.sh /etc/nix /nix ~root/.nix-profile ~root/.nix-defexpr ~root/.nix-channels
  rm -rf "${HOME}/.nix-profile" "${HOME}/.nix-defexpr" "${HOME}/.nix-channels" &>/dev/null

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
  fi

  ! nix::is_installed
}

nix::is_installed() {
  platform::command_exists nix
}
