# config

My macOS setup: packages, apps, dotfiles, language toolchains and system defaults.

## Fresh Mac

```bash
curl -fsSL https://raw.githubusercontent.com/pxc0de/config/main/setup.sh | bash
```

This installs Homebrew and the Xcode Command Line Tools, clones the repo into `~/config`, and runs `./setup.sh install`. You're asked for your password once. Restart when it finishes.

## Commands

| Command | What it does |
|---|---|
| `./setup.sh install` | Sets up everything. Safe to re-run. Never upgrades anything already installed. |
| `./setup.sh sync` | Installs what's new in the `Brewfile`, re-links dotfiles, installs new tmux plugins. |
| `./setup.sh update` | Upgrades Homebrew packages and apps, Rust, uv and Python, Node 22, Claude Code, and Neovim and tmux plugins. Lists macOS updates without installing them. |
| `./setup.sh cleanup` | Lists Homebrew packages that aren't in the `Brewfile` and uninstalls them once you confirm. Then prunes caches, unused plugins and dangling dotfile links. |

To add a tool, add a line to the `Brewfile` and run `./setup.sh sync`. Once a month, run `./setup.sh update` and commit `lazy-lock.json` if Neovim plugins changed.

## Layout

| Path | Purpose |
|---|---|
| `setup.sh` | The commands above. |
| `Brewfile` | Every Homebrew formula and app. |
| `macos.sh` | System preferences. `install` runs it, and you can re-run it alone. Some settings need a restart. |
| `dotfiles/` | One [GNU Stow](https://www.gnu.org/software/stow/) package per program. Each mirrors `$HOME` and gets symlinked into it. |

To add a program's config, create `dotfiles/<program>/` with the same paths it has under `$HOME` (for example `dotfiles/myapp/.config/myapp/config.yml`), then run `./setup.sh sync`.

Machine-local shell settings such as private aliases and SSH hosts go in `~/.zshrc.local`, which stays out of the repo.
