#!/usr/bin/env bash

# Prefix for SCRIPT_NAME variable
#shellcheck disable=SC2034
SLOTH_SCRIPT_BASE_NAME="dot"

if ! ${DOT_MAIN_SOURCED:-false}; then
  # platform and output should be at the first place because they are used
  # in other libraries
  for file in "${SLOTH_PATH:-${DOTLY_PATH:-}}"/scripts/core/src/{platform,output,args,array,async,collections,docs,dot,files,git,github,json,log,package,registry,script,str,sloth_update,yaml,wrapped}.sh; do
    #shellcheck source=/dev/null
    . "$file" || exit 5
  done
  unset file

  readonly DOT_MAIN_SOURCED=true
fi
