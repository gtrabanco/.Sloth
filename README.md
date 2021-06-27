<p align="center">
  <a href="https://github.com/gtrabanco/sloth">
    <img src="sloth.svg" alt="Sloth Logo" width="256px" height="256px" />
  </a>
</p>

<h1 align="center">
  Dotfiles for laziness
</h1>

<p align="right">
  Original idea is <a href="https://github.com/codelytv/dotly" alt="Dotly repository">Dotly Framework</a> by <a href="https://github.com/rgomezcasas" alt="Dotly orginal developer">Rafa Gomez</a>
</p>

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

### [WIP] Installation for Windows

Using elevated PowerShell (WIP: It will be available soon):
```powershell
Invoke-Command ...
```

## Restoring dotfiles

In your repository you see a way to restore your dotfiles, anyway you can restory by using the restoration script

### Linux, macOS, FreeBSD

Using wget
```bash
bash <(wget -qO- https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/restorer)
```

Using curl
```bash
bash <(curl -s https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/restorer)
```
### Windows

```PowerShell
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/install.ps1"))
```

<!--
Source PowerShell:
 . ([Scriptblock]::Create((([System.Text.Encoding]::ASCII).getString((Invoke-WebRequest -Uri "${FUNCTIONS_URI}").Content))))
-->

<hr>

## Roadmap

View [Wiki](https://github.com/gtrabanco/sloth/wiki#roadmap) if you want to contribute and you do not know what to do or maybe is already a WIP (Work in Progress).
