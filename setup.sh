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
            log info "Symlinked: $filename"
        }
    done
    
    # Install VSCode extensions if extensions.txt exists and code command is available
    local extensions_file="$vscode_source_dir/extensions.txt"
    if [[ -f "$extensions_file" ]] && command -v code >/dev/null 2>&1; then
        log step "Installing VSCode extensions"
        while IFS= read -r extension; do
            # Skip empty lines and comments
            [[ -z "$extension" || "$extension" =~ ^[[:space:]]*# ]] && continue
            
            log info "Installing extension: $extension"
            local output
            output=$(code --install-extension "$extension" 2>&1)
            local exit_code=$?
            
            if [[ $exit_code -eq 0 ]]; then
                if [[ "$output" == *"is already installed"* ]]; then
                    log info "Extension $extension is already installed"
                else
                    log success "Extension $extension installed successfully"
                fi
            else
                log warn "Failed to install extension: $extension"
                log warn "Error: $output"
            fi
        done < "$extensions_file"
        log info "VSCode extensions installation completed"
    elif [[ -f "$extensions_file" ]] && ! command -v code >/dev/null 2>&1; then
        log warn "VSCode CLI not found. Extensions not installed. Install VSCode and ensure 'code' command is in PATH."
    fi
    
    log info "VSCode configuration setup completed for $OS"
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
                log info "Removed symlink: $filename"
            }
        done
        log info "VSCode configuration symlinks removed"
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
    install_dotfiles
    
    log success "Installation completed!"
    log info "Restart your shell: exec \$SHELL"
}

cmd_remove() {
    banner "Removing Development Environment"
    
    detect_system
    remove_dotfiles
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