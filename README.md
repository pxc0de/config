## Quick Start

On a fresh Mac, one command does everything (Homebrew, Xcode CLI tools, clone into `~/config`, packages, apps, dotfiles, languages, Neovim plugins, macOS defaults):

```bash
curl -fsSL https://raw.githubusercontent.com/pxc0de/config/main/setup.sh | bash
```

You'll be asked for your password once. Restart the Mac when it finishes.

If the repo is already cloned, run `./setup.sh install` instead.

## Usage

| Command | What it does |
|---|---|
| `./setup.sh install` | Full setup. Safe to re-run; never upgrades anything already installed. |
| `./setup.sh sync` | Installs only what's new in the Brewfile and re-links dotfiles. No upgrades, no surprises. |
| `./setup.sh update` | Upgrades **everything**: Homebrew packages and apps, Rust, uv/Python, Node 22, Claude Code, Neovim and tmux plugins. Lists macOS updates without installing them. |
| `./setup.sh cleanup` | Lists anything installed via Homebrew that isn't in the Brewfile and, after you confirm, uninstalls it. Then prunes caches, unused plugins and dangling dotfile links. |
| `./setup.sh remove` | Removes everything this repo installed. |

Typical flow: add a line to the Brewfile → `./setup.sh sync`. Once a month → `./setup.sh update`, then commit `lazy-lock.json` if Neovim plugins changed.

## macOS System Customization

`./setup.sh install` applies these macOS system preferences automatically. To re-apply them on their own:

```bash
./os/macos/defaults/macos.defaults.sh
```

**Note:** Some settings require a logout or restart to take effect. 


## Customization

### Adding New Dotfiles

1. Create a new directory in `dotfiles/` for your application
2. Structure it to mirror your home directory
3. Run `./setup.sh install` to symlink the new configuration

Example for adding a new config:
```
dotfiles/myapp/
└── .config/
    └── myapp/
        └── config.yml
```
