## Quick Start

On a fresh Mac, one command does everything (Homebrew, Xcode CLI tools, clone into `~/config`, packages, apps, dotfiles, languages, Neovim plugins, macOS defaults):

```bash
curl -fsSL https://raw.githubusercontent.com/pxc0de/config/main/setup.sh | bash
```

You'll be asked for your password once. Restart the Mac when it finishes.

If the repo is already cloned, run `./setup.sh install` instead.

## Usage

The `setup.sh` script provides three main commands:

### Install Command

Install packages and dotfiles:

```bash
# Install everything
./setup.sh install
```

### Remove Command

Remove packages and dotfiles:

```bash
# Remove everything
./setup.sh remove
```

### Help

Display usage information:

```bash
./setup.sh --help
```

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
