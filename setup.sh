#!/usr/bin/env bash

set -euo pipefail

#=============================================================================
# CONFIGURATION
#=============================================================================

# BASH_SOURCE is empty when piped via `curl ... | bash`; bootstrap() handles that case
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR=""
fi
readonly SCRIPT_DIR
readonly REPO_URL="https://github.com/pxc0de/config.git"
readonly REPO_DIR="$HOME/config"
readonly XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
readonly XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
readonly XDG_BIN_HOME="$HOME/.local/bin"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m'

# System detection
OS=""
PKG_MGR=""

#=============================================================================
# LOGGING
#=============================================================================

log() {
    local level="$1" message="$2"
    local timestamp="$(date '+%H:%M:%S')"

    case "$level" in
        error)   echo -e "${RED}[${timestamp}] ERROR:${NC} $message" >&2 ;;
        warn)    echo -e "${YELLOW}[${timestamp}] WARN:${NC} $message" ;;
        info)    echo -e "${BLUE}[${timestamp}] INFO:${NC} $message" ;;
        success) echo -e "${GREEN}[${timestamp}] SUCCESS:${NC} $message" ;;
        step)    echo -e "${CYAN}[${timestamp}] STEP:${NC} $message" ;;
        *)       echo -e "${GRAY}[${timestamp}]${NC} $message" ;;
    esac
}

banner() {
    echo
    echo -e "${WHITE}================================${NC}"
    echo -e "${WHITE}  $1${NC}"
    echo -e "${WHITE}================================${NC}"
    echo
}

#=============================================================================
# SYSTEM DETECTION
#=============================================================================

detect_system() {
    case "$(uname -s)" in
        Darwin)
            OS="macos"
            PKG_MGR="brew"
            ;;
        Linux)
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                if [[ "${ID:-}" == "ubuntu" || "${ID_LIKE:-}" == *ubuntu* ]]; then
                    OS="ubuntu"
                    PKG_MGR="apt"
                fi
            fi
            ;;
    esac

    [[ -z "$OS" ]] && {
        log error "Unsupported OS. Supports: macOS, Ubuntu"
        exit 1
    }

    log info "Detected: $OS"
}

#=============================================================================
# CORE FUNCTIONS
#=============================================================================

setup_xdg() {
    log step "Setting up XDG directories"

    local dirs=("$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_BIN_HOME")
    for dir in "${dirs[@]}"; do
        [[ ! -d "$dir" ]] && mkdir -p "$dir"
    done
    log info "XDG directories setup completed"
}

load_brew_env() {
    local brew_bin
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [[ -x "$brew_bin" ]] && { eval "$("$brew_bin" shellenv)"; return 0; }
    done
    return 0
}

# Ask for the password once and keep sudo alive (Homebrew and some casks need it)
keep_sudo_alive() {
    [[ "$OS" == "macos" ]] || return 0
    log step "Requesting administrator access (asked once)"
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

# When run via `curl ... | bash`, clone the repo and re-run from the clone
bootstrap() {
    [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/dotfiles" ]] && return 0

    banner "Bootstrapping"
    detect_system
    keep_sudo_alive
    install_package_manager

    if [[ ! -d "$REPO_DIR/.git" ]]; then
        log step "Cloning $REPO_URL into $REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR"
    fi
    exec bash "$REPO_DIR/setup.sh" "${@:-install}" </dev/tty
}

# Run a step without aborting the whole install if it fails
run_step() {
    "$@" || log warn "Step '$1' failed, continuing"
}

install_package_manager() {
    log step "Setting up package manager"
    case "$PKG_MGR" in
        brew)
            load_brew_env
            command -v brew >/dev/null 2>&1 || {
                # Also installs Xcode Command Line Tools (and git) headlessly
                log step "Installing Homebrew"
                NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                load_brew_env
            }

            xcode-select -p >/dev/null 2>&1 || {
                log step "Installing Xcode Command Line Tools"
                xcode-select --install
                while ! xcode-select -p >/dev/null 2>&1; do sleep 2; done
            }
            ;;
        apt)
            dpkg -s build-essential >/dev/null 2>&1 || {
                log step "Installing build-essential"
                sudo apt-get update -y
                sudo apt-get install -y build-essential
            }
            ;;
    esac
    log info "Package manager setup completed"
}

install_fonts() {
    log step "Installing fonts"

    case "$OS" in
        ubuntu)
            log info "Installing JetBrains Mono Nerd Font"
            local fonts_dir="$HOME/.local/share/fonts"
            local jetbrains_font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip"
            local temp_dir="/tmp/jetbrains-font"

            # Create fonts directory if it doesn't exist
            [[ ! -d "$fonts_dir" ]] && mkdir -p "$fonts_dir"

            # Download and install JetBrains Mono Nerd Font if not already installed
            if ! fc-list | grep -i "jetbrains.*mono.*nerd" >/dev/null 2>&1; then
                log info "Downloading JetBrains Mono Nerd Font"
                mkdir -p "$temp_dir"

                if curl -L -o "$temp_dir/JetBrainsMono.zip" "$jetbrains_font_url"; then
                    log info "Extracting JetBrains Mono Nerd Font"
                    unzip -q "$temp_dir/JetBrainsMono.zip" -d "$temp_dir"

                    # Copy .ttf files to fonts directory
                    find "$temp_dir" -name "*.ttf" -exec cp {} "$fonts_dir/" \;

                    # Update font cache
                    fc-cache -fv >/dev/null 2>&1

                    # Cleanup
                    rm -rf "$temp_dir"

                    log success "JetBrains Mono Nerd Font installed successfully"
                else
                    log warn "Failed to download JetBrains Mono Nerd Font"
                fi
            else
                log info "JetBrains Mono Nerd Font is already installed"
            fi
            ;;
        macos)
            log info "JetBrains Mono Nerd Font will be installed via Homebrew"
            ;;
    esac
}

install_packages() {
    log step "Installing packages"

    case "$PKG_MGR" in
        brew)
            log info "Installing packages from Brewfile"
            local brewfile="$SCRIPT_DIR/os/macos/packages/Brewfile"
            [[ -f "$brewfile" ]] && {
                # Only install what's missing; upgrading is `./setup.sh update`'s job
                brew bundle install --no-upgrade --file "$brewfile"
            }
            ;;
        apt)
            log info "Installing packages from apt.txt"
            local aptfile="$SCRIPT_DIR/os/ubuntu/packages/apt.txt"
            [[ -f "$aptfile" ]] && {
                local packages=()
                mapfile -t packages < <(grep -vE '^\s*(#|$)' "$aptfile")
                [[ ${#packages[@]} -gt 0 ]] && {
                    sudo apt-get update -y
                    sudo apt-get install -y "${packages[@]}"
                }
            }
            ;;
    esac

    # Install fonts after packages
    install_fonts
}

setup_rust() {
    log step "Setting up Rust"

    # Check if rustup is already installed
    if [[ ! -d "$HOME/.cargo" ]]; then
        log info "Installing Rust using official rustup installer"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path || {
            log error "Failed to install Rust"
            return 1
        }
    else
        log info "Rust is already installed"
    fi

    # Source cargo environment to update PATH in current session
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

    # Verify installation
    if [[ -f "$HOME/.cargo/bin/rustup" ]]; then
        log info "Configuring Rust toolchain"
        "$HOME/.cargo/bin/rustup" toolchain install stable || true
        "$HOME/.cargo/bin/rustup" default stable || true
        "$HOME/.cargo/bin/rustup" component add rustfmt clippy || true
        
        log success "Rust setup completed"
        log info "Note: Restart your shell to ensure ~/.cargo/bin is in PATH: exec \$SHELL"
    else
        log error "Rust installation verification failed"
        return 1
    fi
}

setup_go() {
    log step "Setting up Go"

    if command -v go >/dev/null 2>&1; then
        local go_version=$(go version | awk '{print $3}')
        log success "Go installed: $go_version"
        
        # Set up Go environment variables
        local go_bin_path
        go_bin_path=$(go env GOPATH)/bin
        if [[ ! "$PATH" =~ $go_bin_path ]]; then
            log info "Note: Add $go_bin_path to your PATH for Go tools"
        fi
    else
        log warn "go not found. Go may not be properly installed."
        return 1
    fi
}

setup_uv() {
    log step "Setting up UV (Python package manager)"

    if command -v uv >/dev/null 2>&1; then
        log info "UV is already installed"
    else
        log info "Installing UV from astral.sh"
        # PATH is handled by dotfiles/shell/.zshrc; don't let the installer write ~/.zshrc
        curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh || {
            log warn "Failed to install UV"
            return 1
        }
    fi

    if [[ -x "$HOME/.local/bin/uv" ]]; then
        log info "Installing latest Python via UV and setting it system-wide default"
        # --default also installs `python`/`python3` shims into ~/.local/bin,
        # which is prepended to PATH (see dotfiles/shell/.zshrc), so a bare
        # `python` resolves to UV's latest interpreter instead of /usr/bin/python3.
        "$HOME/.local/bin/uv" python install --default --preview-features python-install-default || {
            log warn "Failed to install Python via UV"
        }
        log success "UV setup completed"
    fi
}

setup_nvm() {
    log step "Setting up NVM (Node.js version manager)"

    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"

    if [[ -d "$nvm_dir" ]]; then
        log info "NVM is already installed"
    else
        log info "Installing NVM"
        # PROFILE=/dev/null: dotfiles/shell/.zshrc already loads nvm
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash || {
            log warn "Failed to install NVM"
            return 1
        }
    fi

    # Source NVM for this session
    if [[ -s "$nvm_dir/nvm.sh" ]]; then
        set +eu; . "$nvm_dir/nvm.sh"; set -eu
    fi

    if command -v nvm >/dev/null 2>&1; then
        log info "Installing Node.js v22 via NVM"
        # nvm is a shell function and trips `set -u`, so relax it here
        (set +u; nvm install 22 && nvm alias default 22) || {
            log warn "Failed to install Node.js via NVM"
        }
        log success "NVM setup completed"
    fi
}

setup_tmux() {
    log step "Setting up Tmux configuration"

    local tpm_dir="$HOME/.tmux/plugins/tpm"

    # Install TPM (Tmux Plugin Manager) if not already installed
    if [[ ! -d "$tpm_dir" ]]; then
        log info "Installing TPM (Tmux Plugin Manager)"
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir" || {
            log warn "Failed to clone TPM repository"
            return 1
        }
        log success "TPM installed successfully"
    else
        log info "TPM is already installed"

        # Update TPM to latest version
        log info "Updating TPM to latest version"
        (cd "$tpm_dir" && git pull) || {
            log warn "Failed to update TPM"
        }
    fi

    # Check if tmux is available
    if ! command -v tmux >/dev/null 2>&1; then
        log warn "Tmux not found. Please install tmux first."
        return 1
    fi

    # Install/update tmux plugins
    log info "Installing/updating tmux plugins"

    # If tmux is running, we need to be careful about reloading
    if pgrep -x tmux >/dev/null; then
        log info "Tmux is running. You may need to manually reload configuration."
        log info "Run: tmux source-file ~/.tmux.conf && ~/.tmux/plugins/tpm/bin/install_plugins"
    else
        # Start a tmux session in the background to install plugins
        log info "Installing tmux plugins automatically"
        tmux new-session -d -s tmux-setup 2>/dev/null || true

        # Source the tmux config and install plugins
        tmux source-file ~/.tmux.conf 2>/dev/null || true

        # Install plugins using TPM
        "$tpm_dir/bin/install_plugins" 2>/dev/null || {
            log warn "Failed to auto-install plugins. You may need to install manually with prefix + I"
        }

        # Kill the temporary session
        tmux kill-session -t tmux-setup 2>/dev/null || true

        log success "Tmux plugins installation completed"
    fi

    log info "Tmux setup completed"
    log info "Your configured plugins:"
    log info "  - tmux-plugins/tpm (Plugin Manager)"
    log info "  - tmux-plugins/tmux-online-status"
    log info "  - tmux-plugins/tmux-battery"
    log info "  - xamut/tmux-weather"
    log info "  - catppuccin/tmux (Theme)"
    log info "  - tmux-plugins/tmux-sensible"
    log info "  - christoomey/vim-tmux-navigator"
    log info ""
    log info "If plugins didn't install automatically, manually run:"
    log info "  1. Start tmux: tmux"
    log info "  2. Press: prefix + I (Ctrl-a + Shift-i)"
}

# Move aside any real file that would block stow (e.g. a ~/.zshrc written by an installer)
backup_conflicts() {
    local package="$1" rel target
    while IFS= read -r rel; do
        rel="${rel#./}"
        [[ "$(basename "$rel")" == README* ]] && continue
        target="$HOME/$rel"
        [[ -e "$target" || -L "$target" ]] || continue
        [[ "$(realpath "$target" 2>/dev/null)" == "$(realpath "$package/$rel")" ]] && continue
        log warn "Backing up existing $target to $target.bak"
        mv "$target" "$target.bak"
    done < <(cd "$package" && find . \( -type f -o -type l \))
}

stow_package() {
    local pkg_name="$1"
    log info "Stowing: $pkg_name"
    backup_conflicts "$SCRIPT_DIR/dotfiles/$pkg_name"
    stow -R -t "$HOME" -d "$SCRIPT_DIR/dotfiles" "$pkg_name" || log warn "Failed to stow $pkg_name"
}

install_dotfiles() {
    log step "Installing dotfiles"

    for package in "$SCRIPT_DIR/dotfiles"/*; do
        [[ -d "$package" ]] && {
            local pkg_name="$(basename "$package")"
            stow_package "$pkg_name"
            # tmux plugins need the config stowed first
            [[ "$pkg_name" == "tmux" ]] && run_step setup_tmux
        }
    done
}

remove_tmux() {
    log step "Removing Tmux configuration"

    local tpm_dir="$HOME/.tmux/plugins"

    # Kill any running tmux sessions
    if pgrep -x tmux >/dev/null; then
        log warn "Tmux is currently running. Please exit all tmux sessions before removal."
        log info "You can run: tmux kill-server"
        return 1
    fi

    # Remove TPM and all plugins
    if [[ -d "$tpm_dir" ]]; then
        log info "Removing TPM and all tmux plugins"
        rm -rf "$tpm_dir"
        log info "Tmux plugins directory removed"
    else
        log info "No tmux plugins directory found"
    fi

    log info "Tmux plugin removal completed"
    log info "Note: Your .tmux.conf file is preserved (managed by stow)"
}

remove_dotfiles() {
    log step "Removing dotfiles"

    for package in "$SCRIPT_DIR/dotfiles"/*; do
        [[ -d "$package" ]] && {
            local pkg_name="$(basename "$package")"
            # Skip packages that need special handling
            if [[ "$pkg_name" == "tmux" ]]; then
                # First remove plugins, then unstow the config
                remove_tmux
                log info "Unstowing: $pkg_name"
                stow -D -t "$HOME" -d "$SCRIPT_DIR/dotfiles" "$pkg_name" 2>/dev/null || true
            else
                log info "Unstowing: $pkg_name"
                stow -D -t "$HOME" -d "$SCRIPT_DIR/dotfiles" "$pkg_name" 2>/dev/null || true
            fi
        }
    done


    log info "Cleaning broken symlinks"
    for dir in "$HOME" "$HOME/.config" "$HOME/.local"; do
        [[ -d "$dir" ]] && find "$dir" -maxdepth 3 -type l ! -exec test -e {} \; -delete 2>/dev/null || true
    done
}

remove_uv() {
    log step "Removing UV"

    if [[ -d "$HOME/.local/bin" ]]; then
        rm -f "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx" 2>/dev/null || true
        log info "UV binaries removed"
    fi

    if command -v uv >/dev/null 2>&1; then
        log info "Cleaning UV cache and Python installations"
        uv cache clean 2>/dev/null || true
        rm -rf "$(uv python dir)" 2>/dev/null || true
        rm -rf "$(uv tool dir)" 2>/dev/null || true
    fi

    log info "UV removal completed"
}

remove_nvm() {
    log step "Removing NVM"

    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"

    if [[ -d "$nvm_dir" ]]; then
        log info "Removing NVM directory: $nvm_dir"
        rm -rf "$nvm_dir"
        log success "NVM removed"
    else
        log info "NVM directory not found"
    fi
}

remove_rust() {
    log step "Removing Rust"

    # Source cargo env to ensure rustup is in PATH if it exists
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

    # Try official uninstall method first
    if command -v rustup >/dev/null 2>&1 || [[ -f "$HOME/.cargo/bin/rustup" ]]; then
        log info "Uninstalling Rust via official rustup uninstaller"
        "$HOME/.cargo/bin/rustup" self uninstall -y 2>/dev/null || {
            log warn "Rustup uninstall command failed, proceeding with manual cleanup"
        }
    else
        log info "rustup not found, proceeding with manual cleanup"
    fi

    # Clean up Rust directories
    if [[ -d "$HOME/.cargo" ]]; then
        log info "Removing ~/.cargo directory"
        rm -rf "$HOME/.cargo"
    fi

    if [[ -d "$HOME/.rustup" ]]; then
        log info "Removing ~/.rustup directory"
        rm -rf "$HOME/.rustup"
    fi

    log info "Rust removal completed"
}

remove_go() {
    log step "Removing Go"

    # Clean up Go directories
    if [[ -d "$HOME/go" ]]; then
        log info "Removing ~/go directory"
        rm -rf "$HOME/go"
    fi

    if [[ -d "$HOME/.go" ]]; then
        log info "Removing ~/.go directory"
        rm -rf "$HOME/.go"
    fi

    log info "Go removal completed (binary will be removed via package manager)"
}

remove_packages() {
    log step "Removing packages"

    case "$PKG_MGR" in
        brew)
            local brewfile="$SCRIPT_DIR/os/macos/packages/Brewfile"
            [[ -f "$brewfile" ]] && {
                while IFS= read -r line; do
                    [[ "$line" =~ ^(brew|cask)[[:space:]]\"(.*)\" ]] && {
                        local type="${BASH_REMATCH[1]}"
                        local package="${BASH_REMATCH[2]}"

                        if [[ "$type" == "cask" ]]; then
                            log info "Removing cask: $package"
                            brew uninstall --cask "$package" 2>/dev/null || true
                        else
                            log info "Removing brew: $package"
                            brew uninstall "$package" 2>/dev/null || true
                        fi
                    }
                done < "$brewfile"
            }
            ;;
        apt)
            local aptfile="$SCRIPT_DIR/os/ubuntu/packages/apt.txt"
            [[ -f "$aptfile" ]] && {
                local packages=()
                mapfile -t packages < <(grep -vE '^\s*(#|$)' "$aptfile")

                # Remove packages except protected ones
                local remove_packages=()
                for pkg in "${packages[@]}"; do
                    [[ "$pkg" != "build-essential" && "$pkg" != "stow" ]] && remove_packages+=("$pkg")
                done

                [[ ${#remove_packages[@]} -gt 0 ]] && {
                    sudo apt-get remove -y "${remove_packages[@]}" 2>/dev/null || true
                }
            }
            ;;
    esac
}

cleanup_system() {
    log step "Cleaning up system"

    case "$PKG_MGR" in
        brew)
            brew cleanup --prune=all 2>/dev/null || true
            ;;
        apt)
            sudo apt-get autoremove -y 2>/dev/null || true
            sudo apt-get autoclean 2>/dev/null || true
            ;;
    esac

    # Clean XDG cache
    [[ -d "$XDG_CACHE_HOME" ]] && rm -rf "$XDG_CACHE_HOME"/* 2>/dev/null || true
}


#=============================================================================
# MAINTENANCE
#=============================================================================

ask_yes_no() {
    local answer
    read -r -p "$1 [y/N] " answer </dev/tty
    [[ "$answer" =~ ^[Yy]$ ]]
}

update_brew() {
    [[ "$PKG_MGR" == "brew" ]] || return 0
    log step "Upgrading Homebrew packages and apps"
    brew update
    # --greedy also upgrades casks that normally update themselves (Chrome, Claude, ...)
    brew upgrade --greedy
}

update_rust() {
    [[ -x "$HOME/.cargo/bin/rustup" ]] || return 0
    log step "Updating Rust"
    "$HOME/.cargo/bin/rustup" update
}

update_uv() {
    local uv="$HOME/.local/bin/uv"
    [[ -x "$uv" ]] || return 0
    log step "Updating uv, Python and uv tools"
    "$uv" self update
    # Picks up a new Python minor release, then patches existing ones
    "$uv" python install --default --preview-features python-install-default
    "$uv" python upgrade
    "$uv" tool upgrade --all
}

update_node() {
    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    [[ -s "$nvm_dir/nvm.sh" ]] || return 0
    log step "Updating Node.js 22 to the latest patch"
    (set +eu; . "$nvm_dir/nvm.sh"; nvm install 22 --reinstall-packages-from=default && nvm alias default 22)
}

update_claude_code() {
    [[ -x "$HOME/.local/bin/claude" ]] || return 0
    log step "Updating Claude Code"
    "$HOME/.local/bin/claude" update
}

update_neovim_plugins() {
    log step "Updating Neovim plugins"
    nvim --headless "+Lazy! sync" +qa
    log info "lazy-lock.json changed if plugins updated; commit it to pin the new versions"
}

update_tmux_plugins() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    [[ -x "$tpm_dir/bin/update_plugins" ]] || return 0
    log step "Updating tmux plugins"
    "$tpm_dir/bin/update_plugins" all
}

list_os_updates() {
    [[ "$OS" == "macos" ]] || return 0
    log step "Checking for macOS updates (not installed automatically)"
    softwareupdate --list || true
}

cleanup_brew() {
    [[ "$PKG_MGR" == "brew" ]] || return 0
    local brewfile="$SCRIPT_DIR/os/macos/packages/Brewfile"
    # Type flags keep this to Homebrew only (no uv/cargo/go extensions)
    local types=(--formulae --casks --taps)

    log step "Looking for Homebrew packages not in the Brewfile"
    local pending
    # Dry run exits non-zero whenever anything is pending; keep only the uninstall lists
    pending="$(brew bundle cleanup "${types[@]}" --file "$brewfile" 2>/dev/null \
        | awk '/^Would uninstall/ {keep=1} /^Would `brew cleanup`/ {keep=0} keep' || true)"
    if [[ -z "$pending" ]]; then
        log info "Nothing installed outside the Brewfile"
    else
        echo "$pending"
        if ask_yes_no "Uninstall these (apps are zapped, including their settings)?"; then
            brew bundle cleanup "${types[@]}" --force --zap --file "$brewfile"
        else
            log info "Skipped. Add anything you want to keep to the Brewfile"
        fi
    fi

    log step "Removing unused dependencies and old downloads"
    brew autoremove
    brew cleanup --prune=all
}

cleanup_caches() {
    log step "Pruning tool caches"
    [[ -x "$HOME/.local/bin/uv" ]] && "$HOME/.local/bin/uv" cache prune
    command -v nvim >/dev/null 2>&1 && nvim --headless "+Lazy! clean" +qa
    [[ -x "$HOME/.tmux/plugins/tpm/bin/clean_plugins" ]] && "$HOME/.tmux/plugins/tpm/bin/clean_plugins"
    return 0
}

# Only links that point into this repo, so nothing else in ~ is touched
cleanup_stale_dotfile_links() {
    log step "Removing dangling dotfile symlinks"
    local link
    while IFS= read -r link; do
        [[ "$(readlink "$link")" == *config/dotfiles/* ]] || continue
        log info "Removing $link"
        rm -f "$link"
    done < <(find "$HOME" "$XDG_CONFIG_HOME" -maxdepth 2 -type l ! -exec test -e {} \; -print 2>/dev/null)
}

#=============================================================================
# COMMANDS
#=============================================================================

setup_claude_code() {
    log step "Setting up Claude Code"

    if [[ -x "$HOME/.local/bin/claude" ]]; then
        log info "Claude Code is already installed"
        return 0
    fi
    # Native installer: lands in ~/.local/bin and auto-updates
    curl -fsSL https://claude.ai/install.sh | bash
}

setup_neovim_plugins() {
    log step "Installing Neovim plugins (pinned to lazy-lock.json)"
    # Language servers are installed by Mason the first time a file is opened
    nvim --headless "+Lazy! restore" +qa || log warn "Neovim plugin install failed, run :Lazy restore manually"
}

apply_macos_defaults() {
    [[ "$OS" == "macos" ]] || return 0
    log step "Applying macOS defaults"
    bash "$SCRIPT_DIR/os/macos/defaults/macos.defaults.sh"
}

cmd_install() {
    banner "Installing Development Environment"

    detect_system
    keep_sudo_alive
    setup_xdg
    install_package_manager
    run_step install_packages
    # Dotfiles go before the language installers so nothing else claims ~/.zshrc
    install_dotfiles
    run_step setup_rust
    run_step setup_go
    run_step setup_uv
    run_step setup_nvm
    run_step setup_claude_code
    run_step setup_neovim_plugins
    run_step apply_macos_defaults

    log success "Installation completed!"
    log info "Restart your Mac so every macOS setting takes effect"
}

cmd_sync() {
    banner "Syncing Brewfile and Dotfiles"

    detect_system
    load_brew_env
    install_packages
    install_dotfiles

    log success "Sync completed! Nothing already installed was upgraded"
}

cmd_update() {
    banner "Updating Everything"

    detect_system
    keep_sudo_alive
    load_brew_env
    run_step update_brew
    run_step install_packages
    run_step update_rust
    run_step update_uv
    run_step update_node
    run_step update_claude_code
    run_step update_neovim_plugins
    run_step update_tmux_plugins
    run_step list_os_updates

    log success "Update completed!"
}

cmd_cleanup() {
    banner "Cleaning Up"

    detect_system
    load_brew_env
    run_step cleanup_brew
    run_step cleanup_caches
    run_step cleanup_stale_dotfile_links

    log success "Cleanup completed!"
}

cmd_remove() {
    banner "Removing Development Environment"

    detect_system
    remove_dotfiles
    remove_rust
    remove_go
    remove_uv
    remove_nvm
    remove_packages
    cleanup_system

    log success "Environment removed!"
    log info "System restored to original state"
}


#=============================================================================
# HELP AND MAIN
#=============================================================================

show_help() {
    cat << EOF

setup.sh - Simple setup script

USAGE:
    ./setup.sh <COMMAND>

COMMANDS:
    install                 Install everything (idempotent, never upgrades)
    sync                    Install only what's new in the Brewfile and re-link dotfiles
    update                  Upgrade EVERYTHING (Homebrew, apps, languages, plugins)
    cleanup                 Remove anything not in the Brewfile (asks first) and prune caches
    remove                  Remove everything, restore original state

EXAMPLES:
    ./setup.sh install
    ./setup.sh sync
    ./setup.sh update
    ./setup.sh cleanup

EOF
}

main() {
    case "${1:-}" in
        install)
            cmd_install
            ;;
        sync)
            cmd_sync
            ;;
        update)
            cmd_update
            ;;
        cleanup)
            cmd_cleanup
            ;;
        remove)
            cmd_remove
            ;;
        --help|-h|help|"")
            show_help
            ;;
        *)
            log error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

bootstrap "$@"

# Ensure we're in the script directory
cd "$SCRIPT_DIR"

# Run main function
main "$@"
