#!/usr/bin/env bash

# First added paths prevails over lasts
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

  registry::command_exists "$recipe" "$command" &&
    registry::load_recipe "$recipe" &&
    "$recipe_command" "$@"
}

#;
# registry::install()
# Install the given recipe
# @param string recipe
# @return boolean
#"
registry::install() {
  local -r recipe="${1:-}"
  local -r command="install"
  [[ -z "$recipe" ]] && return 1

  registry::command "$recipe" "${command}"
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

  registry::command "$recipe" "${command}"
}

#;
# registry::is_outdated()
# Return if a recipe is outdated
# @param string recipe
# @return boolean
#"
registry::is_outdated() {
  local -r recipe="${1:-}"
  local -r command="is_outdated"
  [[ -z "$recipe" ]] && return 1

  registry::command "$recipe" "${command}"
}

#;
# registry::upgrade()
# Update a recipe. Will output the process
# @param string recipe
# @return boolean If error
#"
registry::upgrade() {
  local recipe_title icon="📃"
  local -r recipe="${1:-}"
  
  if [[ -z "$recipe" ]] || ! registry::is_installed "$recipe"; then
    return 1
  fi

  recipe_title="$(registry::_recipe_title)"

  output::empty_line
  registry::_recipe_info "$recipe"
  output::empty_line

  if registry::command_exists "$recipe" "is_outdated"; then
    if registry::is_outdated "$recipe"; then
      registry::command "$recipe" "upgrade"  | log::file "Updating ${icon} recipe app: ${recipe_title}"
    else
      output::solution "${icon} Already has lastest version of ${recipe_title}"
    fi
    output::empty_line
  elif registry::command_exists "$recipe" "upgrade"; then
    output::answer "Can not check if ${recipe_title} is outdated, trying to update it."
    registry::command "$recipe" "upgrade"  | log::file "Updating ${icon} recipe app: ${recipe_title}"
    output::empty_line
  fi
}

#;
# registry::_recipe_title()
# Private function to print the recipe title or default one
# @param string recipe
#"
registry::_recipe_title() {
  local icon="📃"
  if registry::command_exists "$recipe" "title"; then
    echo -n "$(registry::command "$recipe" "title")"
  else
    echo -n "${icon} ${recipe}"
  fi
}

#;
# registry::_recipe_info()
# Private function to print the information about update a registry recipe
# @param string recipe
# @return void
registry::_recipe_info() {
  local version_message first_info last_pos last_info info recipe_all_info
  local -r recipe="${1:-}"

  recipe_all_info=("$(registry::_recipe_title)")

  if registry::command_exists "$recipe" "version"; then
    version_message="$(registry::command "$recipe" "version")"
  fi

  if registry::command_exists "$recipe" "latest"; then
    version_message="${version_message} -> \`$(registry::command "$recipe" "latest")\`"
    recipe_all_info+=("${version_message}")
  elif [[ -n "${version_message:-}" ]]; then
    version_message="Current: ${version_message}"
    recipe_all_info+=("${version_message}")
  fi

  if registry::command_exists "$recipe" "description"; then
    recipe_all_info+=("$(registry::command "$recipe" "description")")
  fi

  if registry::command_exists "$recipe" "url"; then
    recipe_all_info+=("$(registry::command "$recipe" "url")")
  fi

  last_pos=$(( ${#recipe_all_info[@]} - 1 ))
  last_info="${recipe_all_info[$last_pos]}"
  first_info="${recipe_all_info[0]}"

  if [[ ${#recipe_all_info[@]} -gt 0 ]]; then
    for info in "${recipe_all_info[@]}"; do
      if [[ $info == "$first_info" ]]; then
        output::write "$info"
      elif [[ $info != "$last_info" ]]; then
        output::write " ├ ${info}"
      else
        output::write " └ ${info}"
      fi
    done
  fi
}

#;
# registry::list_all_recipes()
# Get all available recipes with given command if provide the argument if not, gives all the available recipes. Note: Gives user defined recipes preference over the core .Sloth recipes.
# @param string required_command If this optional param is set will give only the recipes with this command, you can provide multiple commands (without recipe:: at the beginning)
# @return output each recipe full path per row (all of them)
#"
registry::list_all_recipes() {
  local all_recipes_full_path recipe_path recipe_filename recipe recipes_name=() unique_recipes=()
  readarray -t all_recipes_full_path < <(find "${SLOTH_RECIPE_PATHS[@]}" -maxdepth 1 -name "*.sh" -type f 2>/dev/null)
  for recipe_path in "${all_recipes_full_path[@]}"; do
    recipe_filename="$(basename "$recipe_path")"

    # If exists due the paths order is a user defined recipe which prevails over the core recipe
    array::exists_value "$recipe_filename" "${recipes_name[@]}" && continue

    # Required functions
    if [[ -n "${*:-}" ]]; then
      recipe="${recipe_filename%.sh}"
      has_all=true
      for required_command in "$@"; do
        ! script::function_exists "$recipe_path" "${recipe}::${required_command}" && has_all=false
      done
      ! $has_all && continue
    fi

    # All is going right
    recipes_name+=("$recipe_filename")
    unique_recipes+=("$recipe_path")
  done

  printf "%s\n" "${unique_recipes[@]}"
}

#;
# registry::update_all()
# Update all available recipes that have defined, at least, the function ::update
#"
registry::update_all() {
  local recipe_file_path recipe_file_name recipe icon="📃"

  for recipe_file_path in $(registry::list_all_recipes "upgrade"); do
    [[ -z "$recipe_file_path" || ! -f "$recipe_file_path" ]] && continue
    recipe_file_name="$(basename "$recipe_file_path")"
    recipe="${recipe_file_name%.sh}"

    if registry::is_installed "$recipe"; then
      registry::upgrade "$recipe"
    fi
  done
}
