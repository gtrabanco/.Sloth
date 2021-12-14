#!/usr/bin/env bash

DOTFILES_RECIPES_PATH="${DOTFILES_RECIPES_PATH:-${DOTFILES_PATH:-${HOME}/.dotfiles}/package/recipes}"

# First added paths prevails over lasts
export SLOTH_RECIPE_PATHS=(
  "${SLOTH_RECIPES_PATH[@]:-}"
  "${DOTFILES_PATH:-${HOME}/.dotfiles}/package/recipes"
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
    recipe_file_path="${recipe_path}/${recipe}.sh"
    if [[ -f "$recipe_file_path" ]]; then
      echo -n "$recipe_file_path"
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
      "$recipe_command" "$@" 2>&1 | log::file "Installing package \`${recipe}\` using registry"
    elif [[ "$command" == "uninstall" ]]; then
      "$recipe_command" "$@" 2>&1 | log::file "Uninstalling package \`${recipe}\` using registry"
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
  local _args

  if [[ $* == *"--force"* ]]; then
    mapfile -t _args < <(array::substract "--force" "$@")
    registry::force_install "$recipe" "${_args[@]}" &&
      return
  else
    registry::command "$recipe" "install" "$@" &&
      return
  fi

  return 1
}

#;
# registry::add()
# Alias for registry::install
#"
registry::add() {
  registry::install "$@"
}

#;
# registry::force_install()
# Install the given recipe even if it's already installed
# @param string recipe
# @param any optional args
# @return boolean
#"
registry::force_install() {
  local trytoinstall=false
  local -r recipe="${1:-}"
  [[ -z "$recipe" ]] && return 1
  shift

  local _args
  mapfile -t _args < <(array::substract "--force" "$@")

  if registry::command_exists "$recipe" "force_install"; then
    registry::command "$recipe" "force_install" "${_args[@]}" &&
      return
  elif
    registry::command_exists "$recipe" "uninstall" &&
      registry::command_exists "$recipe" "install" &&
      registry::command "$recipe" "uninstall" "${_args[@]}"
  then
    trytoinstall=true
  fi

  if $trytoinstall; then
    if registry::command_exists "$recipe" "install"; then
      registry::command "$recipe" "install" "${_args[@]}" &&
        return
    else
      log::error "No install or add command found for recipe \`${recipe}\`, but was suceessfully uninstalled"
    fi
  fi

  return 1
}

#;
# registry::force_add()
# Alias for registry::force_install
#"
registry::force_add() {
  registry::force_install "$@"
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
