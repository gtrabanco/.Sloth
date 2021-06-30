if ! ${DOT_MAIN_SOURCED:-false}; then
  for file in $DOTLY_PATH/scripts/core/src/{args,array,async,collections,documentation,dot,files,git,json,log,platform,output,script,str,yaml}.sh; do
    #shellcheck disable=SC1090
    . "$file" || exit 5
  done
  unset file

  readonly DOT_MAIN_SOURCED=true
fi