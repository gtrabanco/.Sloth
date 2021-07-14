#!/usr/bin/env bash

export SLOTH_RECIPE_PATHS=(
  "${SLOTH_RECIPES_PATH[@]:-}"
  "${DOTFILES_PATH:-}/package/recipes"
  "$DOTLY_PATH/scripts/package/src/recipes"
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

  script::function_exists "$recipe_command" "$recipe_file_path"
}

#;
# registry::command()
# Execute a function of the given recipe. Like registry::command_exists but executing it if exists. Accepts additional params that would be passed to the recipe function.
# @param string recipe
# @param string command
# @param any optional args
# @return boolean
#"
registry::command() {
  echo
}

#;
# registry::install()
# Install the given recipe
# @param string recipe
# @return boolean
#"
registry::install() {
  local -r recipe="${1:-}"
  local -r install_command="${recipe}::install"
  local -r recipe_file_path="$(registry::recipe_exists "$recipe")"

  [[ -z "$recipe" || -z "$recipe_file_path" ]] && return 1

  # TODO This is not finish
  if registry; then
    dot::load_library "$recipe_file_path"
    "$install_command"
    return $?
  fi

  return 1
}

#;
# registry::is_installed()
# Check if a recipe is installed
# @param string recipe
# @return boolean
#"
registry::is_installed() {
  local -r recipe="${1:-}"
  local -r is_installed_command="${recipe}::is_installed"
  [[ -z "$recipe" || -z "$(registry::recipe_exists "$recipe")" ]] && return 1

  # TODO Change this
  dot::load_library "$recipe_file_path"

  if [[ "$(command -v "$is_installed_command")" ]]; then
    "$is_installed_command"
    return $?
  fi

  return 1
}

#;
# registry::outdated()
# Return if a recipe is outdated
# @param string recipe
# @return boolean
#"
registry::outdated() {
  # TODO
  echo
}

#;
# registry::update()
# Update a recipe. Will output the process
# @param string recipe
# @return boolean If error
#"
registry::update() {
  # TODO
  echo
}

#;
# registry::list_all_recipes()
# Get all available recipes. Gives user defined recipes preference over the core .Sloth recipes.
# @return output each recipe full path per row (all of them)
#"
registry::list_all_recipes() {
  # TODO
  echo
}

#;
# registry::update_all()
# Update all available recipes that have defined, at least, the function ::update
#"
registry::update_all() {
  # TODO
  # only if recipe::update is present
  # If have ::current_version, ::latest_version, ::description and ::url it will show that information before execute ::update
  echo
}

#;
# registry::_check_many_functions_exists()
# Private function to check if many functions exists on a recipe
# @param string recipe
# @params array functions
# @return boolean Only true if exists all functions
#"
registry::_check_many_functions_exists() {
  local fn_name fns_list
  local -r recipe="${1:-}"
  local -r recipe_file_path="$(registry::recipe_exists "$recipe")"
  [[ -z "$recipe" || -z "$recipe_file_path" || ! -f "$recipe_file_path" ]] && return 1
  shift

  readarray -t fns_list < <(script::list_functions "$recipe_file_path")

  for fn_name in "${@:-}"; do
    [[ -z "$fn" ]] && continue
    ! array::exists_value "${recipe}::${fn_name}" "${fns_list[@]}" && return 1
  done
}
