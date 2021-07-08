#!/usr/bin/env bash

export SLOTH_RECIPES_PATHS=(
  "${SLOTH_RECIPES_PATH[@]:-}"
  "$DOTLY_PATH/scripts/package/src/recipes"
  "${DOTFILES_PATH:-}/package/recipes"
)

registry::recipe_exists() {
  local recipe_path recipe_file_path
  local -r recipe="${1:-}"

  [[ -z "$recipe" ]] && return

  for recipe_path in "${SLOTH_RECIPES_PATHS[@]}"; do
    recipe_file_path=""
    recipe_file_path="$recipe_path/$recipe.sh"
    if [[ -f "$recipe_file_path" ]]; then
      echo "$recipe_file_path"
      break
    fi
  done
}

registry::install() {
  local -r recipe="${1:-}"
  local -r install_command="${recipe}::install"
  local -r recipe_file_path="$(registry::recipe_exists "$recipe")"

  [[ -z "$recipe" || -z "$recipe_file_path" ]] && return 1

  dot::load_library "$recipe_file_path"

  if [[ "$(command -v "$install_command")" ]]; then
    "$install_command"
    return $?
  fi

  return 1
}

registry::is_installed() {
  local -r recipe="${1:-}"
  local -r is_installed_command="${recipe}::is_installed"
  local -r recipe_file_path="$(registry::recipe_exists "$recipe")"
  [[ -z "$recipe" || -z "$recipe_file_path" ]] && return 1
  dot::load_library "$recipe_file_path"

  if [[ "$(command -v "$is_installed_command")" ]]; then
    "$is_installed_command"
    return $?
  fi

  return 1
}
