#!/usr/bin/env bash

dotly::list_bash_files() {
  grep "#!/usr/bin/env bash" "${SLOTH_PATH:-${DOTLY_PATH:-}}"/{bin,dotfiles_template,scripts,shell,installer,restorer} -R | awk -F':' '{print $1}'
  find "${SLOTH_PATH:-${DOTLY_PATH:-}}"/{bin,dotfiles_template,scripts,shell} -type f -name "*.sh" -print0 | xargs -0 -I _ echo _
}

dotly::list_dotfiles_bash_files() {
  grep "#!/usr/bin/env bash" "${DOTFILES_PATH}/"{bin,scripts,shell,restoration_scripts} -R | awk -F':' '{print $1}'
  find "${DOTFILES_PATH}/"{bin,scripts,shell,restoration_scripts} -type f -name "*.sh" -print0 | xargs -0 -I _ echo _
}
