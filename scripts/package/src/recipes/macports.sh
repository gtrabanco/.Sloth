#!/usr/bin/env bash

. "${SLOTH_PATH:-$DOTLY_PATH}/scripts/core/src/_main.sh"

macports_repository_url="https://github.com/macports/macports-base.git"
macports_download_base_url="https://github.com/macports/macports-base/releases/download"

macports::file_name() {
  local version
  ! platform::is_macos && return

  local -r version_name=$(platform::macos_version_name)
  local -r version_number=$(platform::macos_version)

  if [[ ${version_number%.*} -gt 10 ]]; then
    version="${version_number%.*}"
  else
    version="$version_number"
  fi

  echo "MacPorts-$(macports::latest)-$version-${version_name// /}.pkg"
}

macports::latest_download() {
  local latest_url tmp_path
  # macports_releases_api_url="https://api.github.com/repos/macports/macports-base/releases/latest"
  # latest_url="$(curl -s "$macports_releases_api_url" 2>/dev/null | grep -i "$(macports::file_name)" | cut -d'"' -f 4 | grep '^https://' | grep -v '.asc$' || true)"
  latest_url="${macports_download_base_url}/v$(macports::latest)/$(macports::file_name)"

  tmp_path="$(mktemp -d)"
  tmp_file_path="$tmp_path/$(macports::file_name)"
  if curl -fsSL --output "$tmp_file_path" "$latest_url" && [[ -f "$tmp_file_path" ]]; then
    echo "$tmp_file_path"
  fi
}

macports::is_installed() {
  [[ -x "/opt/local/bin/port" ]] || platform::is_macos && platform::command_exists port
}

macports::latest() {
  git ls-remote --tags --refs "$macports_repository_url" 'v*' 2> /dev/null | awk '{print $NF}' | sed 's#refs/tags/v##g' | sort -r | head -n1
}

macports::install() {
  local macports_downloaded_path
  if ! platform::is_macos; then
    output::write "🤔 MacPorts is only available for macOS 😕"
    return 1
  fi

  script::depends_on clt curl

  output::answer "Downloading MacPorts... This could take a while."
  macports_downloaded_path="$(macports::latest_download)"

  if [[ -f "$macports_downloaded_path" ]] && sudo -v; then
    # Install MacPorts
    sudo installer -pkg "$macports_downloaded_path" -target /
    # Install MacPorts' dependencies
    sudo /opt/local/bin/port -v selfupdate

    macports::is_installed && output::solution "MacPorts installed" && output::answer "To use it restart your terminal"
  else
    output::error "MacPorts could not be downloaded"
    output::empty_line
    output::write "Try installing manually from:"
    output::answer "https://github.com/macports/macports-base/releases/latest"
    return 1
  fi
}

macports::uninstall() {
  if ! sudo -v -B; then
    output::error "MacPorts requires sudo access"
    return 1
  fi

  # Uninstall all port packages
  if [[ -x "/opt/local/bin/port" ]] && /usr/bin/sudo /opt/local/bin/port -fp uninstall installed; then
    output::write "Before uninstall, execute first (until fails):"
    output::answer "\`sudo port -fp uninstall installed\`"
    return 1
  fi

  output::answer "Deleting MacPorts' users and groups"
  /usr/bin/sudo /usr/bin/dscl . -delete /Users/macports &> /dev/null
  /usr/bin/sudo /usr/bin/dscl . -delete /Groups/macports &> /dev/null

  output::answer "Deleting MacPorts' files"
  /usr/bin/sudo /bin/rm -rf /opt/local /Applications/DarwinPorts /Applications/MacPorts
  /usr/bin/sudo /bin/rm -rf /Library/LaunchDaemons/org.macports.* /Library/Receipts/DarwinPorts*.pkg /Library/Receipts/MacPorts*.pkg /Library/StartupItems/DarwinPortsStartup /Library/Tcl/darwinports1.0 /Library/Tcl/macports1.0
  /usr/bin/sudo /bin/rm -rf ~/.macports

  ! macports::is_installed && output::solution "Package \`MacPorts\` uninstalled"
}
