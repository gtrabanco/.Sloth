#!/usr/bin/env bash
#shellcheck disable=SC2120
#? Author:
#?   Gabriel Trabanco Llano <gtrabanco@users.noreply.github.com>
#? v1.0.0

INSTALL_COMPOSER_BIN_DIR="${COMPOSER_INSTALL_DIR:-${HOME}/bin}"
INSTALL_COMPOSER_FILENAME="${INSTALL_COMPOSER_FILENAME:-composer}"

composer::is_installed() {
  platform::command_exists composer || [[ -x "${INSTALL_COMPOSER_BIN_DIR}/${INSTALL_COMPOSER_FILENAME}" ]]
}

composer::install() {
  local tmp_dir HASH

  if [[ " $* " == *" --force "* ]]; then
    composer::uninstall
  fi

  if composer::is_installed; then
    output::solution "Composer is already installed"
    return
  fi

  if [[ -n "$(package::manager_exists brew)" ]]; then
    package::install "composer" "brew"

  elif ! composer::is_installed && ! platform::is_macos; then
    script::depends_on php-cli php-zip wget unzip
  fi

  if ! composer::is_installed && platform::command_exists php; then
    tmp_dir="$(mktempt -d)"
    php -r "copy('https://getcomposer.org/installer', '${tmp_dir}/composer-setup.php');"
    HASH="$(wget -q -O - https://composer.github.io/installer.sig)"

    [[ $HASH != "$(php -r "(hash_file('SHA384', '${tmp_dir}/composer-setup.php');")" ]] &&
      log::error "Invalid composer installer signature" &&
      return 1

    mkdir -p "$COMPOSER_INSTALL_DIR"
    php "${tmp_dir}/composer-setup.php" --install-dir="$INSTALL_COMPOSER_BIN_DIR" --filename="$INSTALL_COMPOSER_FILENAME"
  fi

  # Install using a package manager, in this case auto but you can choose brew, pip...
  ! composer::is_installed &&
    package::install composer auto "${1:-}" &&
    composer::is_installed &&
    output::solution "\`composer\` installed" &&
    return

  output::error "\`composer\` could not be installed"
  return 1
}

composer::uninstall() {
  rm -f "${INSTALL_COMPOSER_BIN_DIR}/${INSTALL_COMPOSER_FILENAME}"
}

composer::force_install() {
  rm -f "${INSTALL_COMPOSER_BIN_DIR}/${INSTALL_COMPOSER_FILENAME}"
  composer::uninstall "$@"

  composer::install
}

# ONLY REQUIRED IF YOU WANT TO IMPLEMENT AUTO UPDATE WHEN USING `up` or `up registry`
# Description, url and versions only be showed if defined
composer::is_outdated() {
  # Check if current installed version is outdated, 0 means needs to be updated
  return
}

composer::upgrade() {
  composer::is_installed && composer self-update
}

composer::description() {
  echo "A Dependency Manager for PHP."
}

composer::url() {
  # Please modify
  echo "https://getcomposer.org"
}

composer::version() {
  # Get the current installed version
  composer::is_installed && composer --version
}

composer::title() {
  echo -n "PHP Composer"
}