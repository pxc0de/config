## Quick Start

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd config
   ```

2. Run the setup script:
   ```bash
   ./setup.sh install
   ```

3. Restart your shell:
   ```bash
   exec $SHELL
   ```

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

For macOS users, additional system preferences can be applied using the defaults script, 
this is NOT called by `setup.sh` and requires explicit run:

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
