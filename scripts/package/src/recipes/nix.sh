#!/usr/bin/env bash

nix::execute_from_url() {
  [[ -z "${1:-}" ]] && return 1
  local -r url="$1"
  shift
  if platform::command_exists curl; then
    sh <(curl -L "$url") "$@"
  elif platform::command_exists wget; then
    sh <(curl -q0 - "$url") "$@"
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
  local -r text='# added by Nix installer'
  local -r files=(
    "${HOME}/.bash_profile"
    "${HOME}/.zshenv"
  )

  for file in "${files[@]}"; do
    if [[ -f "$file" ]] && grep -q "${text}$" "$file"; then
      printf "%s\n" "g/${text}$/d" w q | ed -s "$file" || true
    fi
  done

  [[ -f "/etc/bashrc" ]] && grep -q "${text}$" "/etc/bashrc" && sudo -v -B && sudo bash -c 'printf "%s\n" "g/^${text}/d" w q | ed -s "/etc/bashrc"'
  [[ -f "/etc/zshrc" ]] && grep -q "${text}$" "/etc/zshrc" && sudo -v -B && sudo bash -c 'printf "%s\n" "g/^${text}/d" w q | ed -s "/etc/zshrc"'
}

nix::menu() {
  local PS3 title
  [[ $# -lt 2 ]] && return
  title="$1"
  shift

  output::write "$title"
  PS3="Choose an option: "
  select opt in "$@"; do
    echo "$opt"
    return
  done
}

nix::is_installed() {
  platform::command_exists nix
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
  if sudo -v; then
    sudo rm -rf /etc/profile/nix.sh /etc/nix ~root/.nix-profile ~root/.nix-defexpr ~root/.nix-channels
    rm -rf "${HOME}/.nix-profile" "${HOME}/.nix-defexpr" "${HOME}/.nix-channels"
  fi

  nix::delete_rc_modifications_by_nix

  if platform::is_linux && sudo -v -B; then
    # If you are on Linux with systemd, you will need to run:
    sudo systemctl stop nix-daemon.socket
    sudo systemctl stop nix-daemon.service
    sudo systemctl disable nix-daemon.socket
    sudo systemctl disable nix-daemon.service
    sudo systemctl daemon-reload
  elif platform::is_macos && sudo -v -B; then
    local -r disk="$(mount | awk '$3 == "/nix" {print $1}')"
    if [[ -n "$disk" ]]; then
      sudo diskutil apfs deleteVolume "$disk"
    fi

    [[ -f '/etc/fstab' ]] && grep -q '^LABEL=Nix' '/etc/fstab' 2> /dev/null && sudo bash -c 'printf "%s\n" "g/^LABEL=Nix/d" w q | ed -s "/etc/fstab" || true'

    if ! sudo -v; then
      output::error "You need to run this script with sudo"
      return 1
    fi
    # If you are on macOS, you will need to run:
    [[ -f "/Library/LaunchDaemons/org.nixos.nix-daemon.plist" ]] && sudo launchctl unload "/Library/LaunchDaemons/org.nixos.nix-daemon.plist"
    [[ -f "/Library/LaunchDaemons/org.nixos.nix-daemon.plist" ]] && sudo rm "/Library/LaunchDaemons/org.nixos.nix-daemon.plist"
  fi

  if [[ -f "/etc/synthetic.conf" && $(wc -l < "/etc/synthetic.conf") -gt 1 ]] && sudo -v -B; then
    sudo bash -c 'printf "%s\n" "g/^nix/d" w q | ed -s "/etc/synthetic.conf" || true'
  elif [[ -f "/etc/synthetic.conf" ]] && grep -q '^nix' "/etc/synthetic.conf" && sudo -v -B; then
    sudo rm -f "/etc/synthetic.conf"
  fi

  {
    [[ -d "/nix" ]] && sudo -v -B && sudo rm -rf /nix 2> /dev/null
  } || true

  output::write "Reboot to make dissapear the directory \`/nix\` on macOS"

  ! nix::is_installed
}
