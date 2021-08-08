# Default target
default: install

# Set SLOTH Path as the directory of the Makefile
export SLOTH_PATH ?=  $(CURDIR)
export DOTLY_PATH ?=  $(CURDIR)
export DOTLY_INSTALLER=true

all: init install loader link

init:
	@echo "Initilise .Sloth installation as repository..."
	@chmod u+x "scripts/core/install"
	@./scripts/core/install --only-git-init-sloth

install:
	if [[ -n "${DOTFILES_PATH:-}" ]]; then
		@echo "Install dotfiles in: \`${DOTFILES_PATH}\`"
		@chmod u+x ./scripts/dotfiles/create
		@./scripts/dotfiles/create
	fi

	@chmod u+x "scripts/core/install"
	@./scripts/core/install --ignore-symlinks --ignore-restoration

link:
	@echo "Added link in /usr/local/bin for dot command"
	@ln -s "${SLOTH_PATH}/bin/dot" "/usr/local/bin/dot"

unlink:
	@echo "Removed link in /usr/local/bin for dot command"
	@rm -f /usr/local/bin/dot

loader:
	@echo "Installing loader for .Sloth..."
	@chmod u+x "./bin/dot"
	@./bin/dot core loader bashrc --modify
	@./bin/dot core loader zshrc --modify
