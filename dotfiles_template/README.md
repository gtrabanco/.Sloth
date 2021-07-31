<div align="center">
  <h1>
    .dotfiles created using <a href="https://github.com/gtrabanco/sloth">.Sloth</a>
    <div style="display:block">
      <a href="https://github.com/gtrabanco/sloth">
        <img src="sloth.svg" alt="Sloth Logo" width="256px" height="256px" />
      </a>
    </div>
  </h1>
</div>

## Initilize as repository

After installing <a href="https://github.com/gtrabanco/sloth">.Sloth</a> if you want to use it as repository you must initilize as repository:

```bash
cd "$DOTFILES_PATH"
git init
git remote add origin "git+ssh://git@github.com:<github_user>/<repository>.git"
git add .
git commit -m "Initial comit"
```

## Restore your Dotfiles manually

* Install git
* Clone your dotfiles repository `git clone [your repository of dotfiles] $HOME/.dotfiles`
* Go to your dotfiles folder `cd $HOME/.dotfiles`
* Install git submodules `git submodule update --init --recursive modules/sloth`
* Install your dotfiles `DOTFILES_PATH="$HOME/.dotfiles" SLOTH_PATH="$DOTFILES_PATH/modules/sloth" "${SLOTH_PATH:-${DOTLY_PATH:-}}/bin/dot" self install`
* Restart your terminal
* Import your packages `dot package import`

## Restore your Dotfiles with script

Using wget
```bash
bash <(wget -qO- https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/restorer)
```

Using curl
```bash
bash <(curl -s https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/restorer)
```

You need to know your GitHub username, repository and install ssh key if your repository is private.

It also supports other git repos, but you need to know your git repository url.
