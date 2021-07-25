#!/usr/bin/env bash

# First added paths prevails over lasts
export SLOTH_RECIPE_PATHS=(
  "${SLOTH_RECIPES_PATH[@]:-}"
  "${DOTFILES_PATH:-}/package/recipes"
  "${SLOTH_PATH:-${DOTLY_PATH:-}}/scripts/package/src/recipes"
)

#;
# registry::recipe_exists()
# Check if a recipe exists in any of the SLOTH_RECIPE_PATHS
# @param string recipe
# @return string The full path to the recipe or empty string
#"
registry::recipe_exists() {
  local recipe_path recipe_file_path
  local -r recipe="${1:-}"

  [[ -z "$recipe" ]] && return

  for recipe_path in "${SLOTH_RECIPE_PATHS[@]}"; do
    recipe_file_path=""
    recipe_file_path="$recipe_path/$recipe.sh"
    if [[ -f "$recipe_file_path" ]]; then
      echo "$recipe_file_path"
      break
    fi
  done
}

#;
# registry::load_recipe()
# Load recipe only if exists in any of the SLOTH_RECIPE_PATHS
# @param string recipe
# @return string The full path to the recipe or empty string
#"
registry::load_recipe() {
  local recipe_file_path
  local -r recipe="${1:-}"
  recipe_file_path="$(registry::recipe_exists "$recipe")"
  [[ -z "${recipe}" || -z "$recipe_file_path" ]] && return 1
  dot::load_library "$recipe_file_path"
}

#;
# registry::command_exists()
# Check if a command (function) exists in recipe. For example 'registry::command_exists cargo install' will check if cargo::install exists in cargo recipe.
# @param string recipe
# @param string recipe_command The function name in the recipe
# @return boolean
#"
registry::command_exists() {
  local -r recipe="${1:-}"
  local -r recipe_command="${recipe}::${2:-}"
  local -r recipe_file_path="$(registry::recipe_exists "$recipe")"
  [[ -z "${1:-}" || -z "${2:-}" || -z "${recipe_file_path}" ]] && return 1

  script::function_exists "$recipe_file_path" "$recipe_command"
}

#;
# registry::command()
# Execute a function of the given recipe. Like registry::command_exists but executing it if exists. Accepts additional params that would be passed to the recipe function.
# @param string recipe
# @param string command
# @param any optional args
# @return any Whatever the command return
#"
registry::command() {
  local -r recipe="${1:-}"
  local -r command="${2:-}"
  local -r recipe_command="${recipe}::${command}"
  [[ -z "$recipe" || -z "$command" ]] && return 1
  shift 2

  if
    registry::command_exists "$recipe" "$command" &&
      registry::load_recipe "$recipe"
  then
    if [[ "$command" == "install" ]]; then
      "$recipe_command" "$@" 2>&1 | log::file "Installing package \`$recipe\` using registry"
    elif [[ "$command" == "uninstall" ]]; then
      "$recipe_command" "$@" 2>&1 | log::file "Uninstalling package \`$recipe\` using registry"
    else
      "$recipe_command" "$@"
    fi
  else
    return 1
  fi
}

#;
# registry::install()
# Install the given recipe
# @param string recipe
# @param any optional args
# @return boolean
#"
registry::install() {
  local -r recipe="${1:-}"
  [[ -z "$recipe" ]] && return 1
  shift

  registry::command "$recipe" "install" "$@"
}

#;
# registry::uninstall()
# Uninstall the given recipe
# @param string recipe
# @param any optional args
# @return boolean
#"
registry::uninstall() {
  local -r recipe="${1:-}"
  [[ -z "$recipe" ]] && return 1
  shift

  registry::command "$recipe" "uninstall" "$@"
}

#;
# registry::is_installed()
# Check if a recipe is installed
# @param string recipe
# @return boolean
#"
registry::is_installed() {
  local -r recipe="${1:-}"
  local -r command="is_installed"
  [[ -z "$recipe" ]] && return 1

  registry::command_exists "$recipe" "${command}" && registry::command "$recipe" "${command}" && return 0
  return 1
}
