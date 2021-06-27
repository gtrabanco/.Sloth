export DOTFILES_PATH="XXX_DOTFILES_PATH_XXX"
export DOTLY_PATH="$DOTFILES_PATH/modules/dotly"
export DOTLY_THEME="codely"

if [[ -f "${SLOTH_PATH:-$DOTLY_PATH}/shell/init-sloth.sh" ]]
then
  . "${SLOTH_PATH:-$DOTLY_PATH}/shell/init-sloth.sh"
else
  echo "\033[0;31m\033[1mDOTLY Loader could not be found, check \$DOTFILES_PATH variable\033[0m"
fi
