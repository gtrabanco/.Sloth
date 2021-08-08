# Default target
default: install

SLOTH_PATH=${SLOTH_PATH:-$(dirname $BASH_SOURCE)}

install:
	@echo "Initilise .Sloth installation as repository..."
	@chmod u+x "scripts/core/install"
	@./scripts/core/install --only-git-init-sloth