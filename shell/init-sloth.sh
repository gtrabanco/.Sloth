# Needed dotly/sloth functions
#shellcheck disable=SC2148
function cdd() {
  #shellcheck disable=SC2012
  cd "$(ls -d -- */ | fzf)" || echo "Invalid directory"
}

function j() {
  fname=$(declare -f -F _z)

  #shellcheck source=/dev/null
  [ -n "$fname" ] || . "$SLOTH_PATH/modules/z/z.sh"

  _z "$1"
}

function recent_dirs() {
  # This script depends on pushd. It works better with autopush enabled in ZSH
  escaped_home=$(echo "$HOME" | sed 's/\//\\\//g')
  selected=$(dirs -p | sort -u | fzf)

  # shellcheck disable=SC2001
  cd "$(echo "$selected" | sed "s/\~/$escaped_home/")" || echo "Invalid directory"
}

# Advise no vars defines
{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Checking SLOTH_PATH and DOTFILES_PATH variables"; } || true
if [[ -z "${DOTFILES_PATH:-}" || ! -d "${DOTFILES_PATH:-}" || -z "${SLOTH_PATH:-${DOTLY_PATH:-}}" || ! -d "${SLOTH_PATH:-${DOTLY_PATH:-}}" ]]; then
  if [[ -d "$HOME/.dotfiles" && -d "$HOME/.dotfiles/modules/dotly" ]]; then
    DOTFILES_PATH="$HOME/.dotfiles"
    SLOTH_PATH="$DOTFILES_PATH/modules/dotly"
    DOTLY_PATH="$SLOTH_PATH"
  elif [[ -d "$HOME/.dotfiles" && -d "$HOME/.dotfiles/modules/sloth" ]]; then
    DOTFILES_PATH="$HOME/.dotfiles"
    SLOTH_PATH="$DOTFILES_PATH/modules/sloth"
    DOTLY_PATH="$SLOTH_PATH"
  else
    echo -e "\033[0;31m\033[1mDOTFILES_PATH or SLOTH_PATH is not defined or is wrong, .Sloth will fail\033[0m"
  fi
fi

# Envs
# GPG TTY
{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Defining GPG_TTY"; } || true
GPG_TTY="$(tty || echo -n)"
export GPG_TTY

# Sloth aliases and functions
{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Defining Sloth aliases"; } || true
alias dotly='"$SLOTH_PATH/bin/dot"'
alias sloth='"$SLOTH_PATH/bin/dot"'
alias lazy='"$SLOTH_PATH/bin/dot"'
alias s='"$SLOTH_PATH/bin/dot"'

# SLOTH_PATH & DOTLY_PATH compatibility
{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Checking DOTLY_PATH and SLOTH_PATH. We want both not just one..."; } || true
[[ -z "${SLOTH_PATH:-}" && -n "${DOTLY_PATH:-}" ]] && SLOTH_PATH="$DOTLY_PATH"
[[ -z "${DOTLY_PATH:-}" && -n "${SLOTH_PATH:-}" ]] && DOTLY_PATH="$SLOTH_PATH"

{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Loading user exports"; } || true
# shellcheck source=/dev/null
[[ -f "$DOTFILES_PATH/shell/exports.sh" ]] && . "$DOTFILES_PATH/shell/exports.sh"

# Paths
{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Loading user PATH's"; } || true
# shellcheck source=/dev/null
[[ -f "$DOTFILES_PATH/shell/paths.sh" ]] && . "$DOTFILES_PATH/shell/paths.sh"

# Temporary store user path in paths (this is done to avoid do a breaking change and keep compatibility with dotly)
user_paths=("${path[@]}")
# Define PATH to be used with brew and use of uname, we keep user paths because maybe brew is installled in other path
PATH="${PATH:+$PATH}:/usr/bin:/bin:/usr/sbin:/sbin"

# Define variables for OS, arch and shell
{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Defining SLOTH_UNAME, SLOTH_OS, SLOTH_ARCH and SLOTH_SHELL"; } || true
#shellcheck disable=SC2034,SC2207
SLOTH_UNAME=($(uname -sm))
if [[ -n "${SLOTH_UNAME[0]:-}" ]]; then
  SLOTH_OS="${SLOTH_UNAME[0]}"
  SLOTH_ARCH="${SLOTH_UNAME[1]}"
else
  SLOTH_OS="${SLOTH_UNAME[1]}"
  SLOTH_ARCH="${SLOTH_UNAME[2]}"
fi

SLOTH_SHELL="${SHELL##*/}"
# PR Note about this: $SHELL sometimes see zsh under certain circumstances in macOS
if [[ -n "${BASH_VERSION:-}" ]]; then
  SLOTH_SHELL="bash"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  SLOTH_SHELL="zsh"
fi
export SLOTH_UNAME SLOTH_OS SLOTH_ARCH SLOTH_SHELL

###### Macports support ######
{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Loading macports if installed"; } || true
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
###### End of Macports support ######

###### Brew Package manager support ######
{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Loading Brew"; } || true
# BREW_BIN is necessary because maybe is not set the path where it is brew installed
BREW_BIN=""
# Locating brew binary
if [[ -d "/home/linuxbrew/.linuxbrew" && -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
elif [[ -d "${HOME}/.linuxbrew" && -x "${HOME}/.linuxbrew/bin/brew" ]]; then
  BREW_BIN="${HOME}/.linuxbrew/bin/brew"
elif [[ -x "/opt/homebrew/bin/brew" ]]; then
  BREW_BIN="/opt/homebrew/bin/brew"
elif [[ -x "/usr/local/bin/brew" ]]; then
  BREW_BIN="/usr/local/bin/brew"
elif command -v brew &> /dev/null; then
  BREW_BIN="$(command -v brew)"
fi

# Check with -x has no sense because we have done it before :)
if [[ -n "$BREW_BIN" ]]; then
  HOMEBREW_PREFIX="$("$BREW_BIN" --prefix)"
  HOMEBREW_CELLAR="${HOMEBREW_PREFIX}/Cellar"
  HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}/Homebrew"

  # Brew add gnutools in macos or bsd only and brew paths
  if [[ "$SLOTH_OS" == Darwin* || "$SLOTH_OS" == *"BSD"* ]]; then
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

  MANPATH="${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnuman:${HOMEBREW_PREFIX}/share/man:$MANPATH"
  INFOPATH="${HOMEBREW_PREFIX}/share/info:${INFOPATH:-}"
  export MANPATH INFOPATH HOMEBREW_PREFIX HOMEBREW_CELLAR HOMEBREW_REPOSITORY
  [[ -d "${HOMEBREW_PREFIX}/etc/gnutls/" ]] && export GUILE_TLS_CERTIFICATE_DIRECTORY="${GUILE_TLS_CERTIFICATE_DIRECTORY:-${HOMEBREW_PREFIX}/etc/gnutls/}"
else
  # No brew :(
  export path=(
    "${user_paths[@]}"
  )
fi
###### End of Brew Package manager support ######

###### PATHS ######
{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Conditional PATHs"; } || true
# Conditional paths
[[ -d "$HOME/.cargo/bin" ]] && path+=("$HOME/.cargo/bin")
[[ -d "${JAVA_HOME:-}" ]] && path+=("$JAVA_HOME/bin")
[[ -d "${GEM_HOME:-}" ]] && path+=("$GEM_HOME/bin")
[[ -d "${GOHOME:-}" ]] && path+=("$GOHOME/bin")
[[ -d "$HOME/.deno/bin" ]] && path+=("$HOME/.deno/bin")

# System paths
[[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "System PATHs"
path+=("/usr/bin")
path+=("/bin")
path+=("/usr/sbin")
path+=("/sbin")
###### END OF PATHS ######

# Load dotly core for your current BASH
{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Loading Sloth for the shell \`${SLOTH_SHELL}\`"; } || true
if [[ -n "$SLOTH_SHELL" && -f "${SLOTH_PATH:-$DOTLY_PATH}/shell/${SLOTH_SHELL}/init.sh" ]]; then
  #shellcheck source=/dev/null
  . "${SLOTH_PATH:-$DOTLY_PATH}/shell/${SLOTH_SHELL}/init.sh"
else
  echo -e "\033[0;31m\033[1mDOTLY Could not be loaded: Initializer not found for \`${SLOTH_SHELL}\`\033[0m"
fi

# If nix package manager is installed load the env
{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Loading Nix package manager if present"; } || true
# Load single user nix installation in the shell
if [[ -r "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
  #shellcheck disable=SC1091
  . "${HOME}/.nix-profile/etc/profile.d/nix.sh"

# Load nix env when installed for all os users
elif [[ -r "/etc/profile.d/nix.sh" ]]; then
  #shellcheck disable=SC1091
  . "/etc/profile.d/nix.sh"
fi

# Aliases
{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Loading user aliases"; } || true
#shellcheck source=/dev/null
{ [[ -f "$DOTFILES_PATH/shell/aliases.sh" ]] && . "$DOTFILES_PATH/shell/aliases.sh"; } || true

# Functions
{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Loading user functions"; } || true
#shellcheck source=/dev/null
{ [[ -f "$DOTFILES_PATH/shell/functions.sh" ]] && . "$DOTFILES_PATH/shell/functions.sh"; } || true

# Auto Init scripts at the end
[[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Auto init scripts that are enabled"
init_scripts_path="$DOTFILES_PATH/shell/init.scripts-enabled"
if [[ ${SLOTH_INIT_SCRIPTS:-true} == true ]] && [[ -d "$init_scripts_path" ]]; then
  find "$DOTFILES_PATH/shell/init.scripts-enabled" -mindepth 1 -maxdepth 1 -type f,l -print0 2> /dev/null | xargs -0 -I _ realpath --quiet --logical _ | while read -r init_script; do
    [[ -z "$init_script" ]] && continue
    { [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "Trying to load \`${init_script}\`"; } || true
    #shellcheck source=/dev/null
    { [[ -f "$init_script" ]] && . "$init_script"; } || echo -e "\033[0;31m${init_script} could not be loaded\033[0m"
  done
fi

# Unset loader variables
unset init_script init_scripts_path BREW_BIN user_paths

{ [[ "${DOTLY_ENV:-PROD}" == "CI" ]] && echo "End of the .Sloth initiliser"; } || true
