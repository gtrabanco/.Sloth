#!/usr/bin/env bash

. "${SLOTH_PATH:-$DOTLY_PATH}/scripts/core/src/_main.sh"

macports_repository_url="https://github.com/macports/macports-base.git"
macports_releases_api_url="https://api.github.com/repos/macports/macports-base/releases/latest"
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

macports::latest_download_url() {
  # curl -s "$macports_releases_api_url" | grep -i "$(macports::file_name)" | cut -d'"' -f 4 | grep '^https://' | grep -v '.asc$' || echo "${macports_download_base_url}/v$(macports::latest)/$(macports::file_name)"
  echo "${macports_download_base_url}/v$(macports::latest)/$(macports::file_name)"
}

macports::latest() {
  git ls-remote --tags --refs "$macports_repository_url" 'v*' 2>/dev/null | awk '{print $NF}' | sed 's#refs/tags/v##g' | sort -r | head -n1
}


macports::latest_download_url
