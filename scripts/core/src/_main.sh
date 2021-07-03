#!/usr/bin/env bash

if ! ${DOT_MAIN_SOURCED:-false}; then
  for file in "${SLOTH_PATH:-$DOTLY_PATH}"/scripts/core/src/{args,array,async,collections,documentation,dot,files,git,log,platform,output,registry,script,str}.sh; do
    #shellcheck source=/dev/null
    . "$file" || exit 5
  done
  unset file

  readonly DOT_MAIN_SOURCED=true
fi
