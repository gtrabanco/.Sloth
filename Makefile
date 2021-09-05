# Default target
default: install

# Set SLOTH Path as the directory of the Makefile
export INSTALL_PREFIX ?= "/usr/local"
export SLOTH_PATH ?=  $(CURDIR)
export DOTLY_PATH ?=  $(CURDIR)
export DOTFILES_PATH ?=  $(SLOTH_PATH)/dotfiles_template
export DOTLY_INSTALLER ?= true

all: init install loader link

.PHONY: init
init:
	@echo "Initilise .Sloth installation as repository..."
	@chmod u+x "./scripts/core/install"
	"./scripts/core/install" --only-git-init-sloth

.PHONY: standalone-install
standalone-install:
	@echo "Appling symlinks"
	@chmod u+x "$(SLOTH_PATH)/bin/dot"
	"$(SLOTH_PATH)/bin/dot" symlinks apply --backup --continue-on-error

	@echo "Appling loader"
	"$(SLOTH_PATH)/bin/dot" core loader bashrc --modify
	"$(SLOTH_PATH)/bin/dot" core loader zshrc --modify

.PHONY: install
install:
	@chmod u+x "$(SLOTH_PATH)/bin/dot"
	"$(SLOTH_PATH)/scripts/core/install" --backup --ignore-restoration --ignore-loader --link-prefix "$(INSTALL_PREFIX)"

.PHONY: create
create: install
	@echo "Install dotfiles in: \`${DOTFILES_PATH}\`"
	@chmod u+x "./scripts/dotfiles/create"
	"$(SLOTH_PATH)/scripts/dotfiles/create"

.PHONY: link
link: init
	@echo "Added link in /usr/local/bin for dot command"
	ln -s "$(SLOTH_PATH)/bin/dot" "$(INSTALL_PREFIX)/bin/dot"

.PHONY: unlink
unlink:
	@echo "Removed link in $(INSTALL_PREFIX)/bin for dot command"
	rm -f "$(INSTALL_PREFIX)/bin/dot"

.PHONY: loader
loader:
	@echo "Installing loader for .Sloth..."
	@chmod u+x "$(SLOTH_PATH)/bin/dot"
	"$(SLOTH_PATH)/bin/dot" core loader bashrc --modify
	"$(SLOTH_PATH)/bin/dot" core loader zshrc --modify

.PHONY: uninstall
uninstall:
	@echo "Uninstalling .Sloth"
	rm -rf ~/.bashrc ~/.bash_profile ~/.zshrc ~/.zshenv ~/.zimrc ~/.zlogin ~/.inputrc
