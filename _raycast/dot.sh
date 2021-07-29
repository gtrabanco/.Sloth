#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Call dot shell scripts
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🦥
# @raycast.argument1 { "type": "text", "placeholder": "Context", "optional": false }
# @raycast.argument2 { "type": "text", "placeholder": "Script", "optional": false }
# @raycast.argument3 { "type": "text", "placeholder": "Arguments for .Sloth script", "optional": true }
# @raycast.packageName Productivity
# @raycast.needsConfirmation false

# Documentation:
# @raycast.description Executes lazy .Sloth shell scripts
# @raycast.author Gabriel Trabanco
# @raycast.authorURL https://github.com/gtrabanco

# For some scripts we need the user enviroment
#shellcheck disable=SC1091
[[ -f "${HOME}/.bashrc" ]] && . "${HOME}/.bashrc"

context="${1:-}"
script="${2:-}"
arg="${3:-}"

if command -v dot &> /dev/null; then
  dot "$context" "$script" $arg | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'
else
  echo "Error: dot is not installed for not login shell. Execute \`dot core install\` again"
  exit 1
fi