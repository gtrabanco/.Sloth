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

- [About this](#about-this)
- [Features](#features)
  - [Migration from Dotly](#migration-from-dotly)
- [Getting Started](#getting-started)
  - [After installing](#after-installing)
  - [Configuration](#configuration)
  - [Creating a custom script](#creating-a-custom-script)
  - [Fully automated restoration with restoration scripts](#fully-automated-restoration-with-restoration-scripts)
  - [Creating your own package manager wrapper](#creating-your-own-package-manager-wrapper)
  - [Creating your own recipe](#creating-your-own-recipe)
  - [Creating your own theme](#creating-your-own-theme)
  - [Init scripts](#init-scripts)
- [Contributing](#contributing)
- [Roadmap](#roadmap)

## About this
<!--
This section must be changed, Dotly was referenced in the top so no other references are necessary. The target of this section must be define the target of the project.
-->
[.Sloth](https://github.com/gtrabanco/sloth) is a [Dotly fork](https://github.com/CodelyTV/dotly) which widely changes from original project.

Dotly is a [@rgomezcasas](https://github.com/rgomezcasas) idea (supported by [CodelyTV](https://pro.codely.tv)) with the help of a lot of people (see [Dotly Contributors](https://github.com/CodelyTV/dotly/graphs/contributors)).

## Features
<!--
This need a very big improvement
- No more than 5/10 features, more features should be discovered and users needs samples of the stuff they can do
-->

* Abstraction from Framework loader you only need to add in your `.bashrc` or `.zshrc` (it will be done automatically but make a backup first).
 ```bash
 DOTFILES_PATH="${HOME}/.dotfiles"
 SLOTH_PATH="${DOTFILES_PATH}/modules/sloth"
. "${SLOTH_PATH:-${DOTLY_PATH:-}}/shell/init-sloth.sh"
 ```
* Init scripts [see (init-scripts](https://github.com/gtrabanco/dotfiles/tree/master/shell/init.scripts) in [gtrabanco/dotfiles](https://github.com/gtrabanco/dotfiles)). This provides many possibilities as modular loading of custom variables or aliases by machine, loading secrets... Whatever you can imagine.
* Per machine (or whatever name you want to) export packages `sloth packages dump` (you can use `dot` instead of `sloth`, we also have aliases for this command like `lazy` and `s`).
* Non opinionated `git` scripts.
* Compatibility with all Dotly features and scripts.
* When you install SLOTH a backup of all files that well be linked is done (`.bashrc`, `.zshrc`, `.zshenv`... All files in symlinks/conf.yaml and equivalent files that are applied with `sloth core install`). So you won't loose any old data if you migrate to SLOTH.
* Easy way to create new scripts from Terminal `sloth script create --help`
* Easy way to install scripts from Terminal `sloth script install_remote --help`
```
* Scripts marketplace (Coming soon...)
* Auto update (Coming soon...)
* We promise to reply all issues and support messages and review PRs.

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

## Getting Started

### After installing

### Configuration

### Creating a custom script

### Fully automated restoration with restoration scripts

### Creating your own package manager wrapper

### Creating your own recipe

### Creating your own theme

### Init scripts

<hr>

## Contributing

## Roadmap

View [Wiki](https://github.com/gtrabanco/sloth/wiki#roadmap) if you want to contribute and you do not know what to do or maybe is already a WIP (Work in Progress).
