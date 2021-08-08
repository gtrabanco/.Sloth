# Default target
default: install

SLOTH_PATH=${SLOTH_PATH:-$(dirname $BASH_SOURCE)}

install:
	@echo "Initilise .Sloth installation as repository..."
	@chmod u+x "scripts/core/install"
	@./scripts/core/install --only-git-init-sloth

link:
	@echo "Added link in /usr/local/bin for dot command"
	@ln -s "${SLOTH_PATH}/bin/dot" /usr/local/bin/dot

unlink:
	@echo "Removed link in /usr/local/bin for dot command"
	@rm -f /usr/local/bin/dot
