#!/usr/bin/env bash
#shellcheck disable=SC2016
# ------------------------------------------------------------------------------
# GENERAL INFORMATION ABOUT THIS FILE
# The variables here are loaded previously PATH is defined. Use full path if you
# need to do something like JAVA_HOME here or consider to add a init-script
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Sloth config
# ------------------------------------------------------------------------------
export SLOTH_INIT_SCRIPTS=true       # Init scripts enabled (only defined false
export SLOTH_AUTO_UPDATE_PERIOD_IN_DAYS=7
export SLOTH_AUTO_UPDATE_MODE="auto" # silent, auto (default), info, prompt
export SLOTH_UPDATE_VERSION="stable" # latest, stable (default), or any specified
# version if you want to pin to that version
export SLOTH_ENV="production"                   # production or development. If
# you define development all updates must be manually or when you have a clean
# working directory and pushed all your commits.
# This is done to avoid conflicts and lost changes.
# For development all other configuration will be ignored and every time it
# can be updated you will get the latest version.

# These files should be added to the .gitignore and are used by .Sloth
# to check for updates.
# You can change the were these files are created and deleted
export SLOTH_UPDATED_FILE='${DOTFILES_PATH}/.sloth_updated'
export SLOTH_UPDATE_AVAILABE_FILE='${DOTFILES_PATH}/.sloth_update_available'
export SLOTH_FORCE_CURRENT_VERSION_FILE='${DOTFILES_PATH}/.sloth_force_current_version'

# ------------------------------------------------------------------------------
# Codely theme config
# ------------------------------------------------------------------------------
export CODELY_THEME_MINIMAL=false
export CODELY_THEME_MODE="dark"
export CODELY_THEME_PROMPT_IN_NEW_LINE=false
export CODELY_THEME_PWD_MODE="short" # full, short, home_relative

# ------------------------------------------------------------------------------
# Languages
# ------------------------------------------------------------------------------
JAVA_HOME="$(/usr/libexec/java_home 2>&1 /dev/null)"
GEM_HOME="$HOME/.gem"
GOPATH="$HOME/.go"
export JAVA_HOME GEM_HOME GOPATH

# ------------------------------------------------------------------------------
# Apps
# ------------------------------------------------------------------------------
if [ "$CODELY_THEME_MODE" = "dark" ]; then
  fzf_colors="pointer:#ebdbb2,bg+:#3c3836,fg:#ebdbb2,fg+:#fbf1c7,hl:#8ec07c,info:#928374,header:#fb4934"
else
  fzf_colors="pointer:#db0f35,bg+:#d6d6d6,fg:#808080,fg+:#363636,hl:#8ec07c,info:#928374,header:#fffee3"
fi

export FZF_DEFAULT_OPTS="--color=$fzf_colors --reverse"
