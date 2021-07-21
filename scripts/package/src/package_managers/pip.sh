#!/usr/bin/env bash

pip_title='🐍 pip'
PYTHON_DUMP_FILE_PATH="$DOTFILES_PATH/langs/python/$(hostname -s).txt"

# Just a wrapper to change it anytime that would be neccesary
pip::pip() {
  python3 -m pip "$@"
}

pip::is_available() {
  platform::command_exists python3 && python3 -c "import pip; print(pip.__version__)" &> /dev/null
}

pip::is_installed() {
  [[ -n "${1:-}" ]] && pip::pip show "$1" &> /dev/null
}

# Not define the function because it is not possible to do it with pip
# pip::package_exists() {
#   return
# }

pip::install() {
  [[ -n "${1:-}" ]] && pip::is_available && pip::pip install --user --no-cache-dir "$@"
}

pip::uninstall() {
  [[ -n "${1:-}" ]] && pip::is_available && pip::pip uninstall --yes "$@"
}

pip::update_apps() {
  outdated=$(pip::pip list --outdated | tail -n +3)

  if [ -n "$outdated" ]; then
    echo "$outdated" | while IFS= read -r outdated_app; do
      package=$(echo "$outdated_app" | awk '{print $1}')
      current_version=$(echo "$outdated_app" | awk '{print $2}')
      new_version=$(echo "$outdated_app" | awk '{print $3}')
      info=$(pip::pip show "$package")

      summary=$(echo "$info" | head -n3 | tail -n1 | sed 's/Summary: //g')
      url=$(echo "$info" | head -n4 | tail -n1 | sed 's/Home-page: //g')

      output::write "🐍 $package"
      output::write "├ $current_version -> $new_version"
      output::write "├ $summary"
      output::write "└ $url"
      output::empty_line

      pip::pip install install -U "$package" 2>&1 | log::file "Updating pip app: ${package}"
    done
  else
    output::answer "Already up-to-date"
  fi
}

pip::self_update() {
  pip::pip install --upgrade --user pip 2>&1 | log::file "Self updating pip"
}

pip::update_all() {
  ! pip::is_available && return 1
  pip::self_update
  pip::update_apps
}

pip::dump() {
  PYTHON_DUMP_FILE_PATH="${1:-$PYTHON_DUMP_FILE_PATH}"

  if package::common_dump_check pip::pip "$PYTHON_DUMP_FILE_PATH"; then
    pip::pip freeze | tee "$PYTHON_DUMP_FILE_PATH" | log::file "Exporting ${pip_title} packages"

    return 0
  fi

  return 1
}

pip::import() {
  PYTHON_DUMP_FILE_PATH="${1:-$PYTHON_DUMP_FILE_PATH}"

  if package::common_import_check pip::pip "$PYTHON_DUMP_FILE_PATH"; then
    pip::pip install -r "$PYTHON_DUMP_FILE_PATH" | log::file "Importing ${pip_title} packages"

    return 0
  fi

  return 1
}
