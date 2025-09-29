#!/usr/bin/env bash

#=============================================================================
# FINDER SETTINGS
#=============================================================================

# Show hidden files and folders (dotfiles, .git, etc.)
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar at bottom of Finder windows for easier navigation
defaults write com.apple.finder ShowPathbar -bool true

#=============================================================================
# DOCK SETTINGS  
#=============================================================================

# Auto-hide the Dock to save screen space
defaults write com.apple.dock autohide -bool true

# Set Dock icon size to 48 pixels (medium size)
defaults write com.apple.dock tilesize -int 48

# Position Dock on the left side of screen (more vertical space for code)
defaults write com.apple.dock orientation -string "right"

# Disable Dock magnification effect when hovering
defaults write com.apple.dock magnification -bool false

# Minimize windows into their application icon instead of right side of Dock
defaults write com.apple.dock minimize-to-application -bool true

# Remove auto-hide delay - Dock appears instantly when mousing to edge
defaults write com.apple.dock autohide-delay -float 0

# Speed up Dock hide/show animation (remove slow animation)
defaults write com.apple.dock autohide-time-modifier -float 0

# Hide recent applications section in Dock (cleaner appearance)
defaults write com.apple.dock show-recents -bool false

# Show indicators for open applications (small dots under icons)
defaults write com.apple.dock show-process-indicators -bool true

#=============================================================================
# KEYBOARD & INPUT SETTINGS
#=============================================================================

# Set very fast key repeat rate (2 = fastest, 15ms between repeats)
defaults write NSGlobalDomain KeyRepeat -int 2

# Set short delay before key repeat starts (15 = ~225ms)
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for accent characters (enables key repeat for vim)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Enable full keyboard access for all controls (Tab through all UI elements)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

#=============================================================================
# GLOBAL UI SETTINGS
#=============================================================================

# Always show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Always show scroll bars (helpful for large files/documents)
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

# Page scrolling behavior - jump to clicked spot instead of next page
defaults write NSGlobalDomain AppleScrollerPagingBehavior -bool true

# Set highlight color to green (RGB: 0.65, 0.85, 0.58) - customize as needed
defaults write NSGlobalDomain AppleHighlightColor -string "0.650980 0.850980 0.580392"

# Light font smoothing for better text clarity on external monitors
defaults write NSGlobalDomain AppleFontSmoothing -int 1

# Font anti-aliasing threshold - improves text rendering for small fonts
defaults write NSGlobalDomain AppleAntiAliasingThreshold -int 1

#=============================================================================
# PRODUCTIVITY & DEVELOPMENT SETTINGS
#=============================================================================

# Disable automatic spelling correction
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart quotes and dashes (use straight quotes in code)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution (typing two spaces)
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Speed up window resize animations
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Expand save panel by default (show full file browser)
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

#=============================================================================
# FINDER ADVANCED SETTINGS
#=============================================================================

# Show status bar in Finder (shows file count, available space)
defaults write com.apple.finder ShowStatusBar -bool true

# Use column view by default in new Finder windows
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Search current folder by default (instead of entire Mac)
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable warning when changing file extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Show the ~/Library folder
chflags nohidden ~/Library

# Show absolute path in Finder title bar
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Enable spring loading for directories (drag files onto folders to open them)
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Reduce spring loading delay
defaults write NSGlobalDomain com.apple.springing.delay -float 0

#=============================================================================
# SCREENSHOT SETTINGS
#=============================================================================

# Save screenshots to Desktop/Screenshots folder
mkdir -p "${HOME}/Desktop/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Desktop/Screenshots"

# Save screenshots in PNG format (highest quality)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Enable subpixel font rendering on non-Apple LCDs
defaults write NSGlobalDomain AppleFontSmoothing -int 2

#=============================================================================
# TRACKPAD & MOUSE SETTINGS
#=============================================================================

# Enable tap to click for trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Set trackpad speed to fast
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3

# Enable three-finger drag
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

#=============================================================================
# MENU BAR & CONTROL CENTER
#=============================================================================

# Show battery percentage in menu bar
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

# Show date and time in menu bar with seconds
defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d  h:mm:ss a"

# Flash time separators (blinking colon in clock)
defaults write com.apple.menuextra.clock FlashDateSeparators -bool true

#=============================================================================
# ACTIVITY MONITOR SETTINGS
#=============================================================================

# Show main window when Activity Monitor is launched
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0


#=============================================================================
# RESTART REQUIRED SERVICES
#=============================================================================

echo "Restarting affected applications..."

# Restart Finder to apply changes
killall "Finder" > /dev/null 2>&1

# Restart Dock to apply changes  
killall "Dock" > /dev/null 2>&1

# Restart SystemUIServer to apply menu bar changes
killall "SystemUIServer" > /dev/null 2>&1

echo "macOS customization complete! Some changes may require a logout/restart to take effect."




