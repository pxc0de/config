#!/usr/bin/env bash
# Set up and maintain this Mac from the repo. Every command is safe to re-run.
set -euo pipefail

readonly REPO_URL="https://github.com/pxc0de/config.git"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" && pwd)"
readonly REPO
readonly BIN="$HOME/.local/bin"
readonly TPM="$HOME/.tmux/plugins/tpm"

log() { printf '\033[0;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }

# One failed download shouldn't abort the rest of the run
step() { "$@" || warn "$1 failed, continuing"; }

require_macos() {
    [[ "$(uname -s)" == Darwin ]] || { warn "only macOS is supported"; exit 1; }
}

load_brew() {
    local brew
    for brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [[ -x "$brew" ]] && { eval "$("$brew" shellenv)"; break; }
    done
    return 0
}

keep_sudo_alive() {
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

install_homebrew() {
    if ! command -v brew >/dev/null; then
        log "Installing Homebrew and Xcode Command Line Tools"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        load_brew
    fi
    if ! xcode-select -p >/dev/null 2>&1; then
        log "Installing Xcode Command Line Tools"
        xcode-select --install
        until xcode-select -p >/dev/null 2>&1; do sleep 2; done
    fi
}

brew_bundle() {
    log "Installing anything missing from the Brewfile"
    brew bundle install --no-upgrade --file "$REPO/Brewfile"
}

# Move aside any real file that would block stow (e.g. a ~/.zshrc written by an installer)
backup_conflicts() {
    local package="$1" rel target
    while IFS= read -r rel; do
        rel="${rel#./}"
        target="$HOME/$rel"
        [[ -e "$target" || -L "$target" ]] || continue
        [[ "$(realpath "$target" 2>/dev/null)" == "$(realpath "$package/$rel")" ]] && continue
        warn "backing up $target to $target.bak"
        mv "$target" "$target.bak"
    done < <(cd "$package" && find . \( -type f -o -type l \))
}

link_dotfiles() {
    log "Linking dotfiles"
    # Without a real ~/.config, stow would symlink the whole directory into the first package
    mkdir -p "$HOME/.config"
    local package
    for package in "$REPO"/dotfiles/*/; do
        package="$(basename "$package")"
        backup_conflicts "$REPO/dotfiles/$package"
        stow -R -t "$HOME" -d "$REPO/dotfiles" "$package"
    done
}

install_tmux_plugins() {
    log "Installing tmux plugins"
    [[ -d "$TPM" ]] || git clone https://github.com/tmux-plugins/tpm "$TPM"
    "$TPM/bin/install_plugins"
}

install_rust() {
    [[ -x "$HOME/.cargo/bin/rustup" ]] && return
    log "Installing Rust"
    # The default profile includes rustfmt and clippy; .zshrc puts cargo on PATH
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
}

install_python() {
    log "Installing uv and the latest Python"
    # .zshrc puts ~/.local/bin on PATH, so keep the installer away from it
    [[ -x "$BIN/uv" ]] || curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
    # --default adds python/python3 shims to ~/.local/bin, ahead of /usr/bin/python3
    "$BIN/uv" python install --default --preview-features python-install-default
}

install_node() {
    log "Installing nvm and Node.js 22"
    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    # PROFILE=/dev/null: .zshrc already loads nvm
    [[ -d "$nvm_dir" ]] || curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash
    # nvm trips set -eu
    (set +eu; . "$nvm_dir/nvm.sh"; nvm install 22 && nvm alias default 22)
}

install_claude_code() {
    [[ -x "$BIN/claude" ]] && return
    log "Installing Claude Code"
    # The native installer updates itself
    curl -fsSL https://claude.ai/install.sh | bash
}

install_nvim_plugins() {
    log "Installing Neovim plugins pinned in lazy-lock.json"
    # Mason installs language servers the first time Neovim opens a file
    nvim --headless "+Lazy! restore" +qa
}

apply_macos_defaults() {
    log "Applying macOS defaults"
    bash "$REPO/macos.sh"
}

update_brew() {
    log "Upgrading Homebrew packages and apps"
    brew update
    # --greedy also upgrades casks that normally update themselves (Chrome, Claude, ...)
    brew upgrade --greedy
}

update_rust() {
    [[ -x "$HOME/.cargo/bin/rustup" ]] || return 0
    log "Updating Rust"
    "$HOME/.cargo/bin/rustup" update
}

update_python() {
    [[ -x "$BIN/uv" ]] || return 0
    log "Updating uv, Python and uv tools"
    "$BIN/uv" self update
    # Picks up a new Python minor release, then patches the installed ones
    "$BIN/uv" python install --default --preview-features python-install-default
    "$BIN/uv" python upgrade
    "$BIN/uv" tool upgrade --all
}

update_node() {
    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    [[ -s "$nvm_dir/nvm.sh" ]] || return 0
    log "Updating Node.js 22 to the latest patch"
    (set +eu; . "$nvm_dir/nvm.sh"; nvm install 22 --reinstall-packages-from=default && nvm alias default 22)
}

update_claude_code() {
    [[ -x "$BIN/claude" ]] || return 0
    log "Updating Claude Code"
    "$BIN/claude" update
}

update_nvim_plugins() {
    log "Updating Neovim plugins (commit lazy-lock.json if it changed)"
    nvim --headless "+Lazy! sync" +qa
}

update_tmux_plugins() {
    [[ -x "$TPM/bin/update_plugins" ]] || return 0
    log "Updating tmux plugins"
    "$TPM/bin/update_plugins" all
}

list_macos_updates() {
    log "Available macOS updates (not installed)"
    softwareupdate --list || true
}

cleanup_brew() {
    # Type flags keep this to Homebrew itself (no uv/cargo/go extensions)
    local args=(--formulae --casks --taps --file "$REPO/Brewfile") pending answer
    log "Looking for Homebrew packages not in the Brewfile"
    # The dry run exits non-zero whenever anything is pending; keep only the uninstall lists
    pending="$(brew bundle cleanup "${args[@]}" 2>/dev/null \
        | awk '/^Would uninstall/ {keep=1} /^Would `brew cleanup`/ {keep=0} keep' || true)"
    if [[ -n "$pending" ]]; then
        echo "$pending"
        read -r -p "Uninstall these (apps are zapped, including their settings)? [y/N] " answer </dev/tty
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            brew bundle cleanup "${args[@]}" --force --zap
        else
            log "Skipped. Add anything you want to keep to the Brewfile"
        fi
    fi
    log "Removing unused dependencies and old downloads"
    brew autoremove
    brew cleanup --prune=all
}

cleanup_caches() {
    log "Pruning tool caches and unused plugins"
    [[ ! -x "$BIN/uv" ]] || "$BIN/uv" cache prune
    nvim --headless "+Lazy! clean" +qa
    [[ ! -x "$TPM/bin/clean_plugins" ]] || "$TPM/bin/clean_plugins"
}

# Only links into this repo, so nothing else in ~ is touched
cleanup_dangling_links() {
    log "Removing dangling dotfile links"
    local link
    while IFS= read -r link; do
        [[ "$(readlink "$link")" == *config/dotfiles/* ]] || continue
        log "Removing $link"
        rm -f "$link"
    done < <(find "$HOME" "$HOME/.config" -maxdepth 2 -type l ! -exec test -e {} \; -print 2>/dev/null)
}

cmd_install() {
    keep_sudo_alive
    install_homebrew
    step brew_bundle
    # Link before the language installers so none of them claims ~/.zshrc
    link_dotfiles
    step install_tmux_plugins
    step install_rust
    step install_python
    step install_node
    step install_claude_code
    step install_nvim_plugins
    step apply_macos_defaults
    log "Done. Restart the Mac so every macOS setting takes effect"
}

cmd_sync() {
    brew_bundle
    link_dotfiles
    install_tmux_plugins
}

cmd_update() {
    keep_sudo_alive
    step update_brew
    step brew_bundle
    step update_rust
    step update_python
    step update_node
    step update_claude_code
    step update_nvim_plugins
    step update_tmux_plugins
    step list_macos_updates
}

cmd_cleanup() {
    step cleanup_brew
    step cleanup_caches
    step cleanup_dangling_links
}

usage() {
    cat <<EOF
Usage: ./setup.sh <command>

  install   Set up everything. Never upgrades what is already installed.
  sync      Install what's new in the Brewfile and re-link dotfiles.
  update    Upgrade everything: Homebrew, apps, languages, plugins.
  cleanup   Uninstall what isn't in the Brewfile (asks first), prune caches.
EOF
}

main() {
    require_macos
    load_brew
    case "${1:-}" in
        install | sync | update | cleanup) "cmd_$1" ;;
        "" | help | -h | --help) usage ;;
        *) usage >&2; exit 1 ;;
    esac
}

# Piped from curl: there is no repo yet. Homebrew brings git, then re-run from a clone.
if [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    require_macos
    load_brew
    keep_sudo_alive
    install_homebrew
    [[ -d "$HOME/config/.git" ]] || git clone "$REPO_URL" "$HOME/config"
    exec bash "$HOME/config/setup.sh" "${@:-install}" </dev/tty
fi

main "$@"
