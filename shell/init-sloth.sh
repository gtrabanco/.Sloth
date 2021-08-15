# Needed dotly/sloth functions
#shellcheck disable=SC2148,SC1090,SC1091
function cdd() {
  #shellcheck disable=SC2012
  cd "$(ls -d -- */ | fzf)" || echo "Invalid directory"
}

function j() {
  fname=$(declare -f -F _z)

  #shellcheck source=/dev/null
  [ -n "$fname" ] || . "${SLOTH_PATH:-${DOTLY_PATH:-}}/modules/z/z.sh"

  _z "$1"
}

function recent_dirs() {
  # This script depends on pushd. It works better with autopush enabled in ZSH
  escaped_home=$(echo "$HOME" | sed 's/\//\\\//g')
  selected=$(dirs -p | sort -u | fzf)

  # shellcheck disable=SC2001
  cd "$(echo "$selected" | sed "s/\~/$escaped_home/")" || echo "Invalid directory"
}

[[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo ".Sloth initializer started"

# Advise no vars defines
if [[ -z "${DOTFILES_PATH:-}" || ! -d "${DOTFILES_PATH:-}" || -z "${SLOTH_PATH:-${DOTLY_PATH:-}}" || ! -d "${SLOTH_PATH:-${DOTLY_PATH:-}}" ]]; then
  if [[ -d "$HOME/.dotfiles" && -d "${HOME}/.dotfiles/modules/dotly" ]]; then
    DOTFILES_PATH="${HOME}/.dotfiles"
    SLOTH_PATH="${DOTFILES_PATH}/modules/dotly"
    DOTLY_PATH="${SLOTH_PATH:-${DOTLY_PATH:-}}"
  elif [[ -d "${HOME}/.dotfiles" && -d "${HOME}/.dotfiles/modules/sloth" ]]; then
    DOTFILES_PATH="${HOME}/.dotfiles"
    SLOTH_PATH="${DOTFILES_PATH}/modules/sloth"
    DOTLY_PATH="${SLOTH_PATH:-${DOTLY_PATH:-}}"
  else
    echo -e "\033[0;31m\033[1mDOTFILES_PATH or SLOTH_PATH is not defined or is wrong, .Sloth will fail\033[0m"
  fi
fi

# Envs
# GPG TTY
GPG_TTY="$(tty || echo -n)"
export GPG_TTY

# SLOTH_PATH & DOTLY_PATH compatibility
SLOTH_PATH="${SLOTH_PATH:-${DOTLY_PATH:-}}"
DOTLY_PATH="${DOTLY_PATH:-${SLOTH_PATH:-}}"

# Sloth aliases and functions
alias dotly='"${SLOTH_PATH:-${DOTLY_PATH:-}}/bin/dot"'
alias sloth='"${SLOTH_PATH:-${DOTLY_PATH:-}}/bin/dot"'
alias lazy='"${SLOTH_PATH:-${DOTLY_PATH:-}}/bin/dot"'
alias s='"${SLOTH_PATH:-${DOTLY_PATH:-}}/bin/dot"'

[[ -r "${DOTFILES_PATH}/shell/exports.sh" ]] && . "$DOTFILES_PATH/shell/exports.sh"

# Paths
[[ -r "$DOTFILES_PATH/shell/paths.sh" ]] && . "$DOTFILES_PATH/shell/paths.sh"

[[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo ".Sloth initializer: PATHs loaded"

# Temporary store user path in paths (this is done to avoid do a breaking change and keep compatibility with dotly)
user_paths=("${path[@]}")
# Temporary PATH to the system paths
PATH="${PATH:+${PATH}:}$(command -p getconf PATH)"

#shellcheck disable=SC2034,SC2207
SLOTH_UNAME=($(command -p uname -sm))
if [[ -n "${SLOTH_UNAME[0]:-}" ]]; then
  SLOTH_OS="${SLOTH_UNAME[0]}"
  SLOTH_ARCH="${SLOTH_UNAME[1]}"
else
  SLOTH_OS="${SLOTH_UNAME[1]}"
  SLOTH_ARCH="${SLOTH_UNAME[2]}"
fi

# PR Note about this: $SHELL sometimes see zsh under certain circumstances in macOS
if [[ -n "${BASH_VERSION:-}" ]]; then
  SLOTH_SHELL="bash"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  SLOTH_SHELL="zsh"
else
  SLOTH_SHELL="${SHELL##*/}"
fi
export SLOTH_UNAME SLOTH_OS SLOTH_ARCH SLOTH_SHELL

###### Macports support ######
# Load macports paths in user paths because we prefer brew over macports
if [[ -x "/opt/local/bin/port" && -n "$BREW_PREFIX" ]]; then
  export user_paths=(
    "/opt/local/bin"
    "/opt/local/sbin"
    "${user_paths[@]}"
  )
  export MANPATH="/opt/local/share/man:$MANPATH"
elif [[ -x "/opt/local/bin/port" ]]; then
  export user_paths=(
    "/opt/local/bin"
    "/opt/local/sbin"
    "${user_paths[@]}"
  )
  export MANPATH="/opt/local/share/man:$MANPATH"
fi
[[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo ".Sloth initializer: End macports"
###### End of Macports support ######

###### Brew Package manager support ######

# BREW_BIN is necessary because maybe is not set the path where it is brew installed
if [[ -z "${BREW_BIN:-}" || ! -x "$BREW_BIN" ]]; then
  # Locating brew binary
  if [[ -d "/home/linuxbrew/.linuxbrew" && -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
    HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
  elif [[ -d "${HOME}/.linuxbrew" && -x "${HOME}/.linuxbrew/bin/brew" ]]; then
    BREW_BIN="${HOME}/.linuxbrew/bin/brew"
    HOMEBREW_PREFIX="${HOME}/.linuxbrew"
  elif [[ -x "/opt/homebrew/bin/brew" ]]; then
    BREW_BIN="/opt/homebrew/bin/brew"
    HOMEBREW_PREFIX="/opt/homebrew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    BREW_BIN="/usr/local/bin/brew"
    HOMEBREW_PREFIX="/usr/local"
  elif command -v brew &> /dev/null; then
    BREW_BIN="$(command -v brew)"
  elif command -vp brew &> /dev/null; then
    BREW_BIN="$(command -vp brew)"
  fi
fi

if [[ -n "$BREW_BIN" ]]; then
  HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$("$BREW_BIN" --prefix)}"
  PATH="${HOMEBREW_PREFIX}/bin${PATH:+:${PATH}}"
  # Brew add gnutools in macos or bsd only and brew paths
  if [[ "$SLOTH_OS" == Darwin* ]]; then
    export path=(
      "${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin"
      "${HOMEBREW_PREFIX}/opt/findutils/libexec/gnubin"
      "${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin"
      "${HOMEBREW_PREFIX}/opt/gnu-tar/libexec/gnubin"
      "${HOMEBREW_PREFIX}/opt/gnu-which/libexec/gnubin"
      "${HOMEBREW_PREFIX}/opt/grep/libexec/gnubin"
      "${HOMEBREW_PREFIX}/opt/make/libexec/gnubin"
      "${user_paths[@]}"
      "${HOMEBREW_PREFIX}/bin"
      "${HOMEBREW_PREFIX}/sbin"
    )
  else
    # Brew paths
    export path=(
      "${user_paths[@]}"
      "${HOMEBREW_PREFIX}/bin"
      "${HOMEBREW_PREFIX}/sbin"
    )
  fi

  # Open SSL if exists
  [[ -d "${HOMEBREW_PREFIX}/opt/openssl@1.1/bin" ]] && path+=("${HOMEBREW_PREFIX}/opt/openssl@1.1/bin")

  #Homebrew ruby and python over the system
  [[ -d "${HOMEBREW_PREFIX}/opt/ruby/bin" ]] && path+=("${HOMEBREW_PREFIX}/opt/ruby/bin")
  [[ -d "${HOMEBREW_PREFIX}/opt/python/libexec/bin" ]] && path+=("${HOMEBREW_PREFIX}/opt/python/libexec/bin")

  # MANPATH & INFOPATH
  MANPATH="${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnuman:${HOMEBREW_PREFIX}/share/man${MANPATH:+:$MANPATH}"
  INFOPATH="${HOMEBREW_PREFIX}/share/info:${INFOPATH:+:$INFOPATH}"

  export MANPATH INFOPATH HOMEBREW_PREFIX HOMEBREW_CELLAR HOMEBREW_REPOSITORY
  [[ -d "${HOMEBREW_PREFIX}/etc/gnutls/" ]] && export GUILE_TLS_CERTIFICATE_DIRECTORY="${GUILE_TLS_CERTIFICATE_DIRECTORY:-${HOMEBREW_PREFIX}/etc/gnutls/}"
else
  # No brew :(
  export path=(
    "${user_paths[@]}"
  )
fi
[[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo ".Sloth initializer: End brew"
###### End of Brew Package manager support ######

###### PATHS ######
# Conditional paths
[[ -d "${HOME}/.cargo/bin" ]] && path+=("${HOME}/.cargo/bin")
[[ -d "${JAVA_HOME:-}" ]] && path+=("${JAVA_HOME}/bin")
if command -v gem &> /dev/null || command -vp gem &> /dev/null; then
  gem_bin="$(command -v gem || command -vp gem)"
  gem_paths="$("$gem_bin" env gempath 2> /dev/null)"
  #shellcheck disable=SC2207
  [[ -n "$gem_paths" ]] && path+=($(echo "$gem_paths" | command -p tr ':' "\n" | command -p xargs -I _ echo _"/bin"))
fi

[[ -d "${GOHOME:-}" ]] && path+=("${GOHOME}/bin")
[[ -d "${HOME}/.deno/bin" ]] && path+=("${HOME}/.deno/bin")
if command -v python3 &> /dev/null; then
  python_path="$(command python3 -c 'import site; print(site.USER_BASE)' | command -p xargs)/bin"
  [[ -d "$python_path" ]] && path+=("$(command python3 -c 'import site; print(site.USER_BASE)' | command -p xargs)/bin")
fi

# System paths
#shellcheck disable=SC2207
path+=($(command -p getconf PATH | command -p tr ':' '\n'))
[[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo ".Sloth initializer: End PATHs"
###### END OF PATHS ######

###### Load dotly core for your current BASH ######
if [[ -n "$SLOTH_SHELL" && -f "${SLOTH_PATH:-${DOTLY_PATH:-}}/shell/${SLOTH_SHELL}/init.sh" ]]; then
  . "${SLOTH_PATH:-${DOTLY_PATH:-}}/shell/${SLOTH_SHELL}/init.sh"
else
  printf "\033[0;31m\033[1mDOTLY Could not be loaded: Initializer not found for \`%s\`\033[0m\n" "${SLOTH_SHELL}"
fi
###### End of load dotly core for your current BASH ######

###### Load nix package manager if available ######
# Load single user nix installation in the shell
if [[ -r "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
  #shellcheck disable=SC1091
  . "${HOME}/.nix-profile/etc/profile.d/nix.sh"

# Load nix env when installed for all os users
elif [[ -r "/etc/profile.d/nix.sh" ]]; then
  #shellcheck disable=SC1091
  . "/etc/profile.d/nix.sh"
fi
[[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo ".Sloth initializer: End Nix"
###### End of load nix package manager if available ######

###### .Sloth bin path first & Remove duplicated PATHs ######
PATH="${SLOTH_PATH:-${DOTLY_PATH:-}}/bin:$PATH"

# Remove duplicated PATH's
#shellcheck disable=SC2016
PATH=$(printf %s "$PATH" | command -p awk -v RS=':' -v ORS='' '!a[$0]++ {if (NR>1) printf(":"); printf("%s", $0) }')
export PATH
[[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo ".Sloth initializer: Removed duplicated PATHs"
###### End of .Sloth bin path first & Remove duplicated PATHs ######

###### User aliases & functions ######
[[ -r "${DOTFILES_PATH}/shell/aliases.sh" ]] && . "${DOTFILES_PATH}/shell/aliases.sh"

[[ -r "${DOTFILES_PATH}/shell/functions.sh" ]] && . "${DOTFILES_PATH}/shell/functions.sh"
[[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo ".Sloth initializer: User aliases and functions loaded"
###### End of User aliases & functions ######

###### User init scripts ######
init_scripts_path="${DOTFILES_PATH:-}/shell/init.scripts-enabled"
if
  ${SLOTH_INIT_SCRIPTS:-true} &&
    [[ 
      -n "${DOTFILES_PATH:-}" &&
      -d "$init_scripts_path" ]]
then

  for init_script in $(command -p find "${DOTFILES_PATH}/shell/init.scripts-enabled" -mindepth 1 -maxdepth 1 -not -iname ".*" -type f,l -print0 2> /dev/null | command -p xargs -0 -I _ realpath --quiet --logical _); do
    [[ -z "$init_script" ]] && continue

    { [[ -f "$init_script" ]] && . "$init_script"; } || echo -e "\033[0;31m${init_script} could not be loaded\033[0m"
  done
fi
###### End of User init scripts ######

# Unset loader variables
unset init_script init_scripts_path BREW_BIN user_paths gem_bin gem_paths python_path

[[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo ".Sloth initializer finish loading"
