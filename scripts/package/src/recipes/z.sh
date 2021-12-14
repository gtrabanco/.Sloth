#!/usr/bin/env bash
#? Author:
#?   Gabriel Trabanco Llano <gtrabanco@users.noreply.github.com>
#? v1.0.0

Z_REPOSITORY_URL="${Z_REPOSITORY_URL:-https://github.com/rupa/z}"
Z_GITHUB_REPOSITORY="${Z_GITHUB_REPOSITORY:-rupa/z}"
Z_GITHUB_PATH="${Z_GITHUB_PATH:-z.sh}"
Z_LIBRARY_DOWNLOAD_URL="https://raw.githubusercontent.com/rupa/z/HEAD/z.sh"
DOTFILES_PATH="${DOTFILES_PATH:-${HOME}/.dotfiles}"
GITIGNORE_PATH="${DOTFILES_PATH}/.gitignore"
Z_INSTALL_PATH="${Z_INSTALL_PATH:-${DOTFILES_PATH:-${HOME}/.dotfiles}/shell/zsh/.z}"

z::add_to_gitignore() {
  if [[ -d "$DOTFILES_PATH" ]]; then
    touch "$GITIGNORE_PATH"
  fi

  if [[ -f "$GITIGNORE_PATH" ]]; then
    grep -q "${Z_INSTALL_PATH//$DOTFILES_PATH\//}" "$GITIGNORE_PATH" || echo "${Z_INSTALL_PATH//$DOTFILES_PATH\//}" | tee -a "$GITIGNORE_PATH" &> /dev/null
  fi
}

# REQUIRED FUNCTION
z::is_installed() {
  [[ -r "${Z_INSTALL_PATH:-${DOTFILES_PATH:-${HOME}/.dotfiles}/shell/zsh/.z}/z.sh" ]]
}

# REQUIRED FUNCTION
z::install() {
  local -r full_z_path="${Z_INSTALL_PATH:-${DOTFILES_PATH:-${HOME}/.dotfiles}/shell/zsh/.z}/z.sh"
  if [[ $* == *"--force"* ]]; then
    # output::answer "\`--force\` option is ignored with this recipe"
    z::force_install "$@" && return
  elif ! z::is_installed; then
    script::depends_on "curl"

    curl -fsL "${Z_LIBRARY_DOWNLOAD_URL}" -o "$full_z_path"
  fi

  z::is_installed && output::solution "z installed" && return

  output::error "z could not be installed"
  return 1
}

# OPTIONAL
z::uninstall() {
  rm -rf "${Z_INSTALL_PATH:-${DOTFILES_PATH:-${HOME}/.dotfiles}/shell/zsh/.z}" "${HOME}/.z"
}

# OPTIONAL
z::force_install() {
  local _args
  mapfile -t _args < <(array::substract "--force" "$@")
  
  z::is_installed "${_args[@]}" &&
    z::uninstall "${_args[@]}" &&
    z::install "${_args[@]}" &&
    z::is_installed "${_args[@]}"
}

# ONLY REQUIRED IF YOU WANT TO IMPLEMENT AUTO UPDATE WHEN USING `up` or `up registry`
# Description, url and versions only be showed if defined
z::is_outdated() {
  [[ $(z::version) != "$(z::latest_version)" ]]
}

z::upgrade() {
  z::uninstall
  z::install
}

z::description() {
  echo "Tracks your most used directories, based on 'frecency'."
}

z::url() {
  # Please modify
  echo "${Z_REPOSITORY_URL:-https://github.com/rupa/z}"
}

z::version() {
  local -r full_z_path="${Z_INSTALL_PATH:-${DOTFILES_PATH:-${HOME}/.dotfiles}/shell/zsh/.z}/z.sh"
  git::hash "$full_z_path"
}

z::latest() {
  github::get_remote_file_path_json "${Z_GITHUB_REPOSITORY:-rupa/z}" "${Z_GITHUB_PATH:-z.sh}" | jq -r '.sha'
}

z::title() {
  echo -n ".Z Jump start"
}