## About adding new package managers

Forbbiden names:
* `recipe`
* `recipes`
* `auto`

### Registry, recipe(s)
If you plan to add any new package manager you must know that any package manager called `recipe` or `recipes` will not work because they are a valid aliases for `registry` package manager.

### Auto
Similar thing happen with keyword `auto` which is a keyword to say `package::install` and `package::uninstall` use any package manager that is not the `registry`.
