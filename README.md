<p align="center">
  <a href="https://github.com/gtrabanco/sloth">
    <img src="sloth.svg" alt="Sloth Logo" width="256px" height="256px" />
  </a>
</p>

<h1 align="center">
  .Sloth
</h1>

<p align="center">
  Dotfiles for laziness
</p>

<p align="right">
  Original idea is <a href="https://github.com/codelytv/dotly" alt="Dotly repository">Dotly Framework</a> by <a href="https://github.com/rgomezcasas" alt="Dotly orginal developer">Rafa Gomez</a>
</p>

- [Getting Started](#getting-started)
  - [After installing using installer](#after-installing-using-installer)
  - [Future restoration of your dotfiles](#future-restoration-of-your-dotfiles)
  - [Configuration](#configuration)
  - [Creating a custom script](#creating-a-custom-script)
    - [.Sloth Scripts](#sloth-scripts)
  - [Fully automated restoration with restoration scripts](#fully-automated-restoration-with-restoration-scripts)
  - [Creating your own package manager wrapper](#creating-your-own-package-manager-wrapper)
  - [Creating your own recipe](#creating-your-own-recipe)
  - [Creating your own theme](#creating-your-own-theme)
  - [Init scripts](#init-scripts)
    - [NVM](#nvm)
- [Contributing](#contributing)
- [Roadmap](#roadmap)

## About this
<!--
This section must be changed, Dotly was referenced in the top so no other references are necessary. The target of this section must be define the target of the project.
-->
[.Sloth](https://github.com/gtrabanco/sloth) is a [Dotly fork](https://github.com/CodelyTV/dotly) which widely changes from original project.

Dotly is a [@rgomezcasas](https://github.com/rgomezcasas) idea (supported by [CodelyTV](https://pro.codely.tv)) with the help of a lot of people (see [Dotly Contributors](https://github.com/CodelyTV/dotly/graphs/contributors)).

<a href="https://twitter.com/intent/tweet?text=Be%20%more%20%productive%20%by%20%using%20%.Sloth%20%as%20%your%20%dotfiles%20%framework%20%#dotfiles%20%#dotSloth&url=https%3A%2F%2Fgithub.com%2Fgtrabanco%2F.Sloth" class="twitter-share-button" data-size="large" data-show-count="false" title="Tweet about .Sloth">Tweet about .Sloth</a><script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

## Features
<!--
This need a very big improvement
- No more than 5/10 features, more features should be discovered and users needs samples of the stuff they can do
-->

* Can be installed as standalone, not mandatory to be as git submodule (Should be done manually). 
* Init scripts ([see init-scripts](https://github.com/gtrabanco/dotfiles/tree/master/shell/init.scripts) in [gtrabanco/dotfiles](https://github.com/gtrabanco/dotfiles)). This provides many possibilities as modular loading of custom variables or aliases by machine, loading secrets... Whatever you can imagine.
* Per machine (or whatever name you want to) export packages `sloth packages dump` (you can use `dot` instead of `sloth`, we also have aliases for this command like `lazy` and `s`).
* Compatibility with all Dotly scripts.
* When you install SLOTH a backup of all previous files is done (`.bashrc`, `.zshrc` and `.zshenv`) if you request it.
* Easy way to create new scripts from Terminal `sloth script create --help`
* Easy way to install scripts on GitHub from Terminal `sloth script install_remote --help`
* Auto update
* We promise to reply all issues and support messages and review PRs.
* Improved package managers and the way they are executed. You can also create your own wrappers for your package manager.
* Improved registry (recipes) and how recipes can be updated as if they were packages.

**About autocompletion** Is a known issue that current autocompletion for `dot` command does not work as good as supposed and currently only autocomplete the first argument (option). This will be fixed in the future but suppossed a gain in complexity for autocompletion that I am not interested in develop now. [See PR #146 for more information](https://github.com/gtrabanco/.Sloth/pull/146)

## INSTALLATION

### Linux, macOS, FreeBSD

Using wget
```bash
bash <(wget -qO- https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/installer)
```

Using curl
```bash
bash <(curl -s https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/installer)
```

### Migration from Dotly

If you have currently dotly in your .dotfiles you can migrate.

Using wget
```bash
bash <(wget -qO- https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/dotly-migrator)
```

Using curl
```bash
bash <(curl -s https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/dotly-migrator)
```


<!--

Maybe this section should be in the getting started (at the end)


## Restoring dotfiles

In your repository you see a way to restore your dotfiles, anyway you can restory by using the restoration script.

### Linux, macOS, FreeBSD

Using wget
```bash
bash <(wget -qO- https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/restorer)
```

Using curl
```bash
bash <(curl -s https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/restorer)
```
-->

# Getting Started

## After installing using installer

The first thing you must do is restart your terminal.

You can check installation steps that have be done and check those which fail by using `dot self core`.

After that you should create a repository if you want to store your dotfiles as repository in github and init your `${DOTFILES_PATH}` as your repository.

```bash
dotfiles
git remote add origin git@github.com:${GITHUB_USER}/${GITHUB_DOTFILES_REPOSITORY}.git
git add .
git commit -m "Initial commit"
git push origin master
```
Replace the variables for your own values or the full url for your repository.

**IMPORTANT** If you make your repository public take care about the information you publish like tokens, password or any other sensible data. The responsability of this is from yourself and not from any .Sloth developer.

## Future restoration of your dotfiles

See the README that is created in your repository or in [`dotfiles_template`](dotfiles_template)


## Configuration

Next thing you have to do is personalize the configuration. How .Sloth is updated and theme, do that by customize files in `DOTFILES_PATH` variable.

If you use VSCode (for example), you can view all files and customize with:

```bash
code "$DOTFILES_PATH"
```

Pay attention to those files that are in `${DOTFILES_PATH}/shell`. To be more precise the configuration is in `exports.sh`.

Add any additional PATH where to find binaries in the array in `paths.sh`. **IMPORTANT** There are PATHs that are configured in the .Sloth initialiser like gnu stuff in macOS, brew PATH, macports PATH (if you have it installed) or Nix Package Manager PATH.

Other PATHs that are loaded are:
* `JAVA_HOME`
* Python
* Ruby
* Go

For other envs use init scripts or make a PR.

## Creating a custom script

The main idea of these framework is try to avoid loading bash functions so you can create your own scripts directly from command line, for that use the themplates. View the help:

```bash
dot script create --help
```

There are two kind of scripts that can be created, Dotly compatible scripts and .Sloth scripts. By default these ones are created which are for a simple `echo` around 10ms faster.

You can create also core scripts which are created in `SLOTH_PATH`. Use only these feature if you have developing a core script that you will send to as with a PR please.

### .Sloth Scripts
* The parse of the help and version are ignored because is done automatically with .Sloth.
* .Sloth scripts are included and not executed so the source of core Dotly/.Sloth scripts can be omited.

## Fully automated restoration with restoration scripts

In your `DOTFILES_PATH` you will have a folder called `restoration_scripts` you can add scripts there that will be executed automatically when using `dot core install`. This useful to automate post installation steps that we want to execute when we restore our dotfiles. See examples in [my dotfiles repository](https://github.com/gtrabanco/dotfiles).

## Creating your own package manager wrapper

If you use a package manager that is not in the core or you want to replace how any work, you can by simply add the library in `${DOTFILES_PATH}/package/managers/mypackage_manager_name.sh`. See `brew` wrapper as the better example. It can dump and make a backup of all installed packages, update apps, install new apps and little stuff more.

## Creating your own recipe

If you want to create your own recipe to install any package or add it as custom dependency for any reason (for example compilation and postcompilation configuration) you can create your custom recipes in `${DOTFILES_PATH}/package/recipes`. Recipes can be autoupdated, see `deno.sh` as good example of recipe that can be installed by using a package manager or installed from source, updated and show information of the package.

## Creating your own theme

Themes are in `${DOTFILES_PATH}/shell/{zsh,bash}/themes`, see `dotly` theme as good example but you can have other installed like [Spaceship Prompt](https://spaceship-prompt.sh/)

## Init scripts

Init scripts can be enabled or disabled and check their status by using `dot init` context. Init scripts are initialized at the end of sloth initilizer and can reduce a lot the performance. There is a notificator for .Sloth updater and nvm init script by default.

Init scripts should be stored in `${DOTFILES_PATH}/shell/init.scripts` and can be enabled by using `dot init enable`. You will see fzf and you can select multiple with `Shift + Tab`. You will only see those that are disabled.

To check which init scripts are enabled or disables use `dot init status`.

### NVM

There is a recipe for NVM and NVM and default LTS node, npm & npx are installed by executing `dot package add nvm`. You will need to enable init script for NVM by using `dot init enable nvm`

<hr>

# Contributing

You can contribute to the project by making a PR, reporting an issue, suggesting a feature, writting about the project or by applying any idea you have. All contributions that respect our [Code of Conduct](https://github.com/gtrabanco/.Sloth/blob/master/.github/code-of-conduct.md) are very welcoming.

# Roadmap

View [Wiki](https://github.com/gtrabanco/sloth/wiki#roadmap) if you want to contribute and you do not know what to do or maybe is already a WIP (Work in Progress).

You can contribute also by using PR to any working branch (Drafted PRs).
