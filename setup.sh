#!/usr/bin/env bash

set -euo pipefail

#=============================================================================
# CONFIGURATION
#=============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

install_package_manager() {
    log step "Setting up package manager"
    case "$PKG_MGR" in
        brew)
            command -v brew >/dev/null 2>&1 || {
                log step "Installing Homebrew"
                NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
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
                brew bundle --file "$brewfile"
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
        curl -LsSf https://astral.sh/uv/install.sh | sh || {
            log warn "Failed to install UV"
            return 1
        }
    fi

    if command -v uv >/dev/null 2>&1; then
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
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash || {
            log warn "Failed to install NVM"
            return 1
        }
    fi

    # Source NVM for this session
    [[ -s "$nvm_dir/nvm.sh" ]] && . "$nvm_dir/nvm.sh"

    if command -v nvm >/dev/null 2>&1 || [[ -s "$nvm_dir/nvm.sh" ]]; then
        log info "Installing Node.js v22 via NVM"
        "$nvm_dir/nvm.sh" "install" "22" || {
            log warn "Failed to install Node.js via NVM"
        }
        log success "NVM setup completed"
    fi
}

setup_vscode() {
    log step "Setting up VSCode configuration"

    local vscode_source_dir="$SCRIPT_DIR/dotfiles/vscode"
    local vscode_target_dir=""

    case "$OS" in
        macos)
            vscode_target_dir="$HOME/Library/Application Support/Code/User"
            ;;
        ubuntu)
            vscode_target_dir="$HOME/.config/Code/User"
            ;;
        *)
            log warn "VSCode setup not supported for OS: $OS"
            return 0
            ;;
    esac

    # Create target directory if it doesn't exist
    [[ ! -d "$vscode_target_dir" ]] && mkdir -p "$vscode_target_dir"

    # Create symlinks for VSCode configuration files
    for config_file in "$vscode_source_dir"/*.json; do
        [[ -f "$config_file" ]] && {
            local filename="$(basename "$config_file")"
            local target_file="$vscode_target_dir/$filename"

            # Remove existing file/symlink if it exists
            [[ -e "$target_file" || -L "$target_file" ]] && rm -f "$target_file"

            # Create symlink
            ln -s "$config_file" "$target_file"
            log info "VSCode: Symlinked $filename"
        }
    done

    # Install VSCode extensions if extensions.txt exists and code command is available
    local extensions_file="$vscode_source_dir/extensions.txt"
    if [[ -f "$extensions_file" ]] && command -v code >/dev/null 2>&1; then
        log step "Installing VSCode extensions"
        while IFS= read -r extension; do
            # Skip empty lines and comments
            [[ -z "$extension" || "$extension" =~ ^[[:space:]]*# ]] && continue

            log info "Installing VSCode extension: $extension"
            local output
            output=$(code --install-extension "$extension" 2>&1)
            local exit_code=$?

            if [[ $exit_code -eq 0 ]]; then
                if [[ "$output" == *"is already installed"* ]]; then
                    log info "VSCode extension $extension is already installed"
                else
                    log success "VSCode extension $extension installed successfully"
                fi
            else
                log warn "Failed to install VSCode extension: $extension"
                log warn "Error: $output"
            fi
        done < "$extensions_file"
        log info "VSCode extensions installation completed"
    elif [[ -f "$extensions_file" ]] && ! command -v code >/dev/null 2>&1; then
        log warn "VSCode CLI not found. Extensions not installed. Install VSCode and ensure 'code' command is in PATH."
    fi

    log info "VSCode configuration setup completed for $OS"
}

setup_cursor() {
    log step "Setting up Cursor configuration"

    local vscode_source_dir="$SCRIPT_DIR/dotfiles/vscode"
    local cursor_target_dir=""

    case "$OS" in
        macos)
            cursor_target_dir="$HOME/Library/Application Support/Cursor/User"
            ;;
        ubuntu)
            cursor_target_dir="$HOME/.config/Cursor/User"
            ;;
        *)
            log warn "Cursor setup not supported for OS: $OS"
            return 0
            ;;
    esac

    # Create target directory if it doesn't exist
    [[ ! -d "$cursor_target_dir" ]] && mkdir -p "$cursor_target_dir"

    # Create symlinks for Cursor configuration files (reusing VSCode configs)
    for config_file in "$vscode_source_dir"/*.json; do
        [[ -f "$config_file" ]] && {
            local filename="$(basename "$config_file")"
            local target_file="$cursor_target_dir/$filename"

            # Remove existing file/symlink if it exists
            [[ -e "$target_file" || -L "$target_file" ]] && rm -f "$target_file"

            # Create symlink
            ln -s "$config_file" "$target_file"
            log info "Cursor: Symlinked $filename"
        }
    done

    # Install Cursor extensions if extensions.txt exists and cursor command is available
    local extensions_file="$vscode_source_dir/extensions.txt"
    if [[ -f "$extensions_file" ]] && command -v cursor >/dev/null 2>&1; then
        log step "Installing Cursor extensions"
        while IFS= read -r extension; do
            # Skip empty lines and comments
            [[ -z "$extension" || "$extension" =~ ^[[:space:]]*# ]] && continue

            log info "Installing Cursor extension: $extension"
            local output
            output=$(cursor --install-extension "$extension" 2>&1)
            local exit_code=$?

            if [[ $exit_code -eq 0 ]]; then
                if [[ "$output" == *"is already installed"* ]]; then
                    log info "Cursor extension $extension is already installed"
                else
                    log success "Cursor extension $extension installed successfully"
                fi
            else
                log warn "Failed to install Cursor extension: $extension"
                log warn "Error: $output"
            fi
        done < "$extensions_file"
        log info "Cursor extensions installation completed"
    elif [[ -f "$extensions_file" ]] && ! command -v cursor >/dev/null 2>&1; then
        log warn "Cursor CLI not found. Extensions not installed. Install Cursor and ensure 'cursor' command is in PATH."
        log info "To install Cursor CLI: Open Cursor -> Command Palette -> 'Install cursor to shell'"
    fi

    log info "Cursor configuration setup completed for $OS"
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

install_dotfiles() {
    log step "Installing dotfiles"

    for package in "$SCRIPT_DIR/dotfiles"/*; do
        [[ -d "$package" ]] && {
            local pkg_name="$(basename "$package")"
            # Skip packages that need special handling
            if [[ "$pkg_name" == "vscode" ]]; then
                setup_vscode
                setup_cursor
            elif [[ "$pkg_name" == "tmux" ]]; then
                # First stow the tmux config, then setup plugins
                log info "Stowing: $pkg_name"
                stow -R -t "$HOME" -d "$SCRIPT_DIR/dotfiles" "$pkg_name" 2>/dev/null || true
                setup_tmux
            else
                log info "Stowing: $pkg_name"
                stow -R -t "$HOME" -d "$SCRIPT_DIR/dotfiles" "$pkg_name" 2>/dev/null || true
            fi
        }
    done
}

remove_vscode() {
    log step "Removing VSCode configuration"

    local vscode_target_dir=""

    case "$OS" in
        macos)
            vscode_target_dir="$HOME/Library/Application Support/Code/User"
            ;;
        ubuntu)
            vscode_target_dir="$HOME/.config/Code/User"
            ;;
        *)
            log warn "VSCode removal not supported for OS: $OS"
            return 0
            ;;
    esac

    # Remove VSCode configuration symlinks
    if [[ -d "$vscode_target_dir" ]]; then
        for config_file in "$vscode_target_dir"/*.json; do
            [[ -L "$config_file" ]] && {
                local filename="$(basename "$config_file")"
                rm -f "$config_file"
                log info "VSCode: Removed symlink $filename"
            }
        done
        log info "VSCode configuration symlinks removed"
    fi
}

remove_cursor() {
    log step "Removing Cursor configuration"

    local cursor_target_dir=""

    case "$OS" in
        macos)
            cursor_target_dir="$HOME/Library/Application Support/Cursor/User"
            ;;
        ubuntu)
            cursor_target_dir="$HOME/.config/Cursor/User"
            ;;
        *)
            log warn "Cursor removal not supported for OS: $OS"
            return 0
            ;;
    esac

    # Remove Cursor configuration symlinks
    if [[ -d "$cursor_target_dir" ]]; then
        for config_file in "$cursor_target_dir"/*.json; do
            [[ -L "$config_file" ]] && {
                local filename="$(basename "$config_file")"
                rm -f "$config_file"
                log info "Cursor: Removed symlink $filename"
            }
        done
        log info "Cursor configuration symlinks removed"
    fi
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
            if [[ "$pkg_name" == "vscode" ]]; then
                remove_vscode
                remove_cursor
            elif [[ "$pkg_name" == "tmux" ]]; then
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
# COMMANDS
#=============================================================================

cmd_install() {
    banner "Installing Development Environment"

    detect_system
    setup_xdg
    install_package_manager
    install_packages
    setup_rust
    setup_go
    setup_uv
    setup_nvm
    install_dotfiles

    log success "Installation completed!"
    log info "Restart your shell: exec \$SHELL"
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
    install                 Install everything (idempotent)
    remove                  Remove everything, restore original state

EXAMPLES:
    ./setup.sh install
    ./setup.sh remove

EOF
}

main() {
    case "${1:-}" in
        install)
            cmd_install
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

# Ensure we're in the script directory
cd "$SCRIPT_DIR"

# Run main function
main "$@"
