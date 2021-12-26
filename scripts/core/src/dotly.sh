#!/usr/bin/env bash

dotly::list_bash_files() {
  grep --exclude-dir=*template* "#!/usr/bin/env bash" "${SLOTH_PATH:-${DOTLY_PATH:-}}"/{bin,dotfiles_template,scripts,shell,installer,restorer} -R | awk -F':' '{print $1}' 2> /dev/null
  grep --exclude-dir=*template* "#!/usr/bin/env sloth" "${SLOTH_PATH:-${DOTLY_PATH:-}}"/{bin,dotfiles_template,scripts,shell,installer,restorer} -R | awk -F':' '{print $1}' 2> /dev/null
  grep --exclude-dir=*template* "#!/bin/bash" "${SLOTH_PATH:-${DOTLY_PATH:-}}"/{bin,dotfiles_template,scripts,shell,installer,restorer} -R | awk -F':' '{print $1}' 2> /dev/null
  find "${SLOTH_PATH:-${DOTLY_PATH:-}}"/{bin,dotfiles_template,scripts,shell} -type f -name "*.sh" -not -path "*template*" -print0 2> /dev/null | xargs -0 -I _ echo _ | grep -v 'shell/zsh'
}

dotly::list_dotfiles_bash_files() {
  grep --exclude-dir=*template* "#!/usr/bin/env bash" "${DOTFILES_PATH}/"{bin,scripts,shell,restoration_scripts} -R | awk -F':' '{print $1}' 2> /dev/null
  grep --exclude-dir=*template* "#!/usr/bin/env sloth" "${DOTFILES_PATH}/"{bin,scripts,shell,restoration_scripts} -R | awk -F':' '{print $1}' 2> /dev/null
  grep --exclude-dir=*template* "#!/bin/bash" "${DOTFILES_PATH}/"{bin,scripts,shell,restoration_scripts} -R | awk -F':' '{print $1}' 2> /dev/null
  find "${DOTFILES_PATH}/"{bin,scripts,shell,restoration_scripts} -type f -name "*.sh" "*/template" -not -path "*template*" -print0 2> /dev/null | xargs -0 -I _ echo _ | grep -v 'shell/zsh'
}
