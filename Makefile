# Default target
default: install

# Set SLOTH Path as the directory of the Makefile
export SLOTH_PATH ?=  $(CURDIR)
export DOTLY_PATH ?=  $(CURDIR)
export DOTLY_INSTALLER = true

all: init install loader link

.PHONY: init
init:
  @echo "Initilise .Sloth installation as repository..."
  @chmod u+x "${SLOTH_PATH}/scripts/core/install"
  "${SLOTH_PATH}/scripts/core/install" --only-git-init-sloth

.PHONY: install
install:
  if [[ -n "${DOTFILES_PATH:-}" ]]; then
    @echo "Install dotfiles in: \`${DOTFILES_PATH}\`"
    @chmod u+x "${SLOTH_PATH}/scripts/dotfiles/create"
    "${SLOTH_PATH}/scripts/dotfiles/create"
  fi

  @chmod u+x "scripts/core/install"
  "${SLOTH_PATH}/scripts/core/install" --ignore-symlinks --ignore-restoration

.PHONY: link
link:
  @echo "Added link in /usr/local/bin for dot command"
  ln -s "${SLOTH_PATH}/bin/dot" "/usr/local/bin/dot"

.PHONY: unlink
unlink:
  @echo "Removed link in /usr/local/bin for dot command"
  rm -f "/usr/local/bin/dot"

.PHONY: loader
loader:
  @echo "Installing loader for .Sloth..."
  @chmod u+x "${SLOTH_PATH}/bin/dot"
  "${SLOTH_PATH}/bin/dot" core loader bashrc --modify
  "${SLOTH_PATH}/bin/dot" core loader zshrc --modify
