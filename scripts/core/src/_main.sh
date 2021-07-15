#!/usr/bin/env bash

if ! ${DOT_MAIN_SOURCED:-false}; then
  # platform and output should be at the first place because they are used
  # in other libraries
  for file in "${SLOTH_PATH:-$DOTLY_PATH}"/scripts/core/src/{platform,output,log,args,array,async,collections,documentation,dot,files,git,json,package,registry,script,str,yaml}.sh; do
    #shellcheck source=/dev/null
    . "$file" || exit 5
  done
  unset file

  readonly DOT_MAIN_SOURCED=true
fi
