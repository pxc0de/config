# VSCode Configuration

Everything is automated in `setup.sh`.

## Settings

VS Code provides different scopes for settings:
- **User settings** - Settings that apply globally to any instance of VS Code you open.
- **Workspace settings** - Settings stored inside your workspace and only apply when the workspace is opened.

### User `settings.json` location:
```
Windows - %APPDATA%\Code\User\settings.json
macOS   - $HOME/Library/Application Support/Code/User/settings.json
Linux   - $HOME/.config/Code/User/settings.json
```

VS Code stores workspace settings at the root of the project in a `.vscode` folder. This makes it easy to share settings with others in a version-controlled (for example, Git) project.

## Keymaps

There are two files where my keybindings are defined:
1. `keybindings.json` (location is same as User `settings.json`) - This is for VSCode's built-ins
2. `init.lua` in `.config/vscode` which is used by vscode-neovim plugin.

## Extensions

Extensions are installed in a per user extensions folder. Depending on your platform, the location is in the following folder:
```
Windows - %USERPROFILE%\.vscode\extensions
macOS   - ~/.vscode/extensions
Linux   - ~/.vscode/extensions
```

## Backup

The best option to backup and sync settings, keymaps and extensions is to use built-in `Backup and Sync Settings`.

But, if required, manual options to backup as follows:
- Move `settings.json` and `keybindings.json` from older machine or dotfiles repository to new machine.
- Export extensions in old machine as follows:
```shell
code --list-extensions > extensions.txt
```
- Install extensions in new machine:
```bash
cat extensions.txt | xargs -L 1 code --install-extension
```
> **Note:** This is included in `setup.sh`.

## References

- [VSCode Settings Documentation](https://code.visualstudio.com/docs/configure/settings)
- [Extension Marketplace Documentation](https://code.visualstudio.com/docs/configure/extensions/extension-marketplace)
- [VSCode Configuration Tutorial](https://www.youtube.com/watch?v=tTyQqE72gAk&list=PLXDouhCU5r6r53o_0yfbAj5bckF2nXrQL)