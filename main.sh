#!/bin/bash

# Balatro Linux Modding Setup Script
# Sets up Steamodded and Lovely Injector for Balatro modding

set -e  # Exit on error

STEAM_MODDED="https://github.com/Steamodded/smods/releases/latest"
LOVELY="https://github.com/ethangreen-dev/lovely-injector/releases/latest"
BALATRO_PATH=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/balatro_modding_$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cleanup function
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Check if required tools are installed
check_dependencies() {
    local missing_deps=()
    
    command -v curl >/dev/null 2>&1 || missing_deps+=("curl")
    command -v jq >/dev/null 2>&1 || missing_deps+=("jq")
    command -v unzip >/dev/null 2>&1 || missing_deps+=("unzip")
    
    if [[ ${#missing_deps[@]} -ne 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install them using your package manager:"
        log_info "Ubuntu/Debian: sudo apt install ${missing_deps[*]}"
        log_info "Fedora: sudo dnf install ${missing_deps[*]}"
        log_info "Arch: sudo pacman -S ${missing_deps[*]}"
        exit 1
    fi
}

# Prompt the user for their preference
prompt_user() {
    echo
    log_info "Balatro Linux Modding Setup"
    echo "=========================================="
    echo
    echo "Choose an option:"
    echo "1) Auto-download Steamodded and Lovely Injector (recommended)"
    echo "2) I have the mod files already and want to provide paths"
    echo "3) Exit"
    echo
    
    while true; do
        read -p "Enter your choice (1-3): " choice
        case $choice in
            1)
                return 0
                ;;
            2)
                return 1
                ;;
            3)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_warning "Invalid choice. Please enter 1, 2, or 3."
                ;;
        esac
    done
}

# Download required modding tools
download_req() {
    log_info "Creating temporary directory..."
    mkdir -p "$TEMP_DIR"
    
    log_info "Fetching latest releases..."
    
    # Get Lovely Injector latest release (Windows version for Wine/Proton)
    log_info "Downloading Lovely Injector (Windows version for Wine/Proton)..."
    local lovely_url=$(curl -s "https://api.github.com/repos/ethangreen-dev/lovely-injector/releases/latest" | jq -r '.assets[] | select(.name | test("lovely-x86_64-pc-windows-msvc\\.zip$")) | .browser_download_url')
    
    if [[ -z "$lovely_url" ]]; then
        log_error "Failed to get Lovely Injector Windows download URL"
        return 1
    fi
    
    curl -L -o "$TEMP_DIR/lovely.zip" "$lovely_url"
    log_success "Lovely Injector downloaded"
    
    # Get Steamodded latest release
    log_info "Downloading Steamodded..."
    local steamodded_url=$(curl -s "https://api.github.com/repos/Steamodded/smods/releases/latest" | jq -r '.zipball_url')
    
    if [[ -z "$steamodded_url" ]]; then
        log_error "Failed to get Steamodded download URL"
        return 1
    fi
    
    curl -L -o "$TEMP_DIR/steamodded.zip" "$steamodded_url"
    log_success "Steamodded downloaded"
    
    # Extract files
    log_info "Extracting files..."
    unzip -q "$TEMP_DIR/lovely.zip" -d "$TEMP_DIR/lovely/"
    unzip -q "$TEMP_DIR/steamodded.zip" -d "$TEMP_DIR/steamodded/"
    
    log_success "Files extracted successfully"
}

# Get user-provided mod file paths
get_user_files() {
    echo
    log_info "Please provide the paths to your mod files:"
    
    while true; do
        read -p "Path to Steamodded zip file: " steamodded_path
        if [[ -f "$steamodded_path" && "$steamodded_path" == *.zip ]]; then
            break
        else
            log_warning "File not found or not a zip file. Please try again."
        fi
    done
    
    while true; do
        read -p "Path to Lovely Injector zip file: " lovely_path
        if [[ -f "$lovely_path" && "$lovely_path" == *.zip ]]; then
            break
        else
            log_warning "File not found or not a zip file. Please try again."
        fi
    done
    
    # Extract user-provided files
    log_info "Extracting provided files..."
    mkdir -p "$TEMP_DIR"
    unzip -q "$steamodded_path" -d "$TEMP_DIR/steamodded/"
    unzip -q "$lovely_path" -d "$TEMP_DIR/lovely/"
    
    log_success "User files extracted successfully"
}

# Find Balatro installation and save directory
find_gaben() {
    log_info "Searching for Balatro installation..."
    
    local game_search_paths=(
        # Regular Steam
        "$HOME/.steam/steam/steamapps/common/Balatro"
        "$HOME/.local/share/Steam/steamapps/common/Balatro"
        
        # Flatpak Steam
        "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/steamapps/common/Balatro"
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Balatro"
        
        # Snap Steam
        "$HOME/snap/steam/common/.steam/steam/steamapps/common/Balatro"
        "$HOME/snap/steam/common/.local/share/Steam/steamapps/common/Balatro"
        
        # System-wide Steam installations
        "/usr/share/steam/steamapps/common/Balatro"
        "/opt/steam/steamapps/common/Balatro"
    )
    
    # Search in common paths
    for path in "${game_search_paths[@]}"; do
        if [[ -d "$path" && -f "$path/Balatro.exe" ]]; then
            BALATRO_PATH="$path"
            log_success "Found Balatro game directory at: $BALATRO_PATH"
            break
        fi
    done
    
    # If not found, ask user
    if [[ -z "$BALATRO_PATH" ]]; then
        log_warning "Balatro not found in common locations."
        echo
        echo "Please help locate your Balatro installation:"
        echo "Look for a folder containing 'Balatro.exe'"
        echo
        
        while true; do
            read -p "Enter the full path to your Balatro folder: " user_path
            
            if [[ -d "$user_path" && -f "$user_path/Balatro.exe" ]]; then
                BALATRO_PATH="$user_path"
                log_success "Balatro found at: $BALATRO_PATH"
                break
            else
                log_warning "Invalid path or Balatro.exe not found. Please try again."
                echo "Example: /home/username/.steam/steam/steamapps/common/Balatro"
            fi
        done
    fi
    
    # Determine the save directory (Wine/Proton paths for Linux)
    determine_save_directory
}

# Determine Balatro save directory based on Steam installation type
determine_save_directory() {
    log_info "Determining Balatro save directory..."
    
    local save_search_paths=(
        # Regular Steam (Wine/Proton)
        "$HOME/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro"
        
        # Flatpak Steam
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro"
        
        # Snap Steam
        "$HOME/snap/steam/common/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro"
    )
    
    # Try to find existing save directory
    for path in "${save_search_paths[@]}"; do
        if [[ -d "$path" ]]; then
            BALATRO_SAVE_PATH="$path"
            log_success "Found Balatro save directory at: $BALATRO_SAVE_PATH"
            return 0
        fi
    done
    
    # If not found, determine based on game path
    if [[ "$BALATRO_PATH" == *".var/app/com.valvesoftware.Steam"* ]]; then
        # Flatpak Steam
        BALATRO_SAVE_PATH="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro"
    elif [[ "$BALATRO_PATH" == *"snap/steam"* ]]; then
        # Snap Steam
        BALATRO_SAVE_PATH="$HOME/snap/steam/common/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro"
    else
        # Regular Steam
        BALATRO_SAVE_PATH="$HOME/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro"
    fi
    
    log_info "Will use save directory: $BALATRO_SAVE_PATH"
}

# Install the mods
install_mods() {
    log_info "Installing mods..."
    
    # Step 1: Install Lovely Injector (version.dll to game directory)
    log_info "Installing Lovely Injector..."
    
    # Find version.dll in the extracted lovely files
    local version_dll=$(find "$TEMP_DIR/lovely" -name "version.dll" | head -1)
    
    if [[ -z "$version_dll" ]]; then
        log_error "version.dll not found in Lovely Injector archive"
        return 1
    fi
    
    # Copy version.dll to game directory
    cp "$version_dll" "$BALATRO_PATH/"
    log_success "Installed version.dll to game directory"
    
    # Step 2: Install Steamodded (to save directory/Mods)
    log_info "Installing Steamodded..."
    
    # Create save directory and Mods folder if they don't exist
    mkdir -p "$BALATRO_SAVE_PATH/Mods"
    
    # Find the interior Steamodded folder (should be the main mod folder)
    local steamodded_main_dir=$(find "$TEMP_DIR/steamodded" -type d -name "Steamodded-*" | head -1)
    
    if [[ -z "$steamodded_main_dir" ]]; then
        # Fallback: look for any directory with lua files
        steamodded_main_dir=$(find "$TEMP_DIR/steamodded" -name "*.lua" -exec dirname {} \; | head -1)
    fi
    
    if [[ -z "$steamodded_main_dir" ]]; then
        log_error "Steamodded main directory not found"
        return 1
    fi
    
    # Remove any existing Steamodded installation
    if [[ -d "$BALATRO_SAVE_PATH/Mods/Steamodded" ]]; then
        log_info "Removing existing Steamodded installation..."
        rm -rf "$BALATRO_SAVE_PATH/Mods/Steamodded"
    fi
    
    # Copy the entire Steamodded directory to Mods folder
    cp -r "$steamodded_main_dir" "$BALATRO_SAVE_PATH/Mods/Steamodded"
    log_success "Installed Steamodded to Mods directory"
    
    # Step 3: Check if we need to set launch options
    check_launch_options
    
    log_success "Mods installed successfully!"
}

# Check and inform about Steam launch options
check_launch_options() {
    log_info "Checking Steam launch options..."
    
    echo
    log_warning "IMPORTANT: Steam Launch Options Required!"
    echo "=========================================="
    echo
    log_info "You MUST set the following launch options for Balatro in Steam:"
    echo
    echo "    WINEDLLOVERRIDES=\"version=n,b\" %command%"
    echo
    log_info "To set launch options:"
    log_info "1. Right-click Balatro in your Steam library"
    log_info "2. Select 'Properties...'"
    log_info "3. In the 'Launch Options' field, paste the above command"
    log_info "4. Close the Properties window"
    echo
    log_warning "The mods will NOT work without these launch options!"
    echo
    
    read -p "Press Enter when you have set the launch options (or press Ctrl+C to exit)..."
}

# Main execution
main() {
    echo
    log_info "Starting Balatro Linux Modding Setup..."
    
    # Check dependencies
    check_dependencies
    
    # Find Balatro installation
    find_gaben
    
    # Prompt user for choice
    if prompt_user; then
        # User chose to download
        download_req || {
            log_error "Failed to download required files"
            exit 1
        }
    else
        # User has their own files
        get_user_files
    fi
    
    # Install the mods
    install_mods
    
    echo
    log_success "=========================================="
    log_success "Balatro modding setup complete!"
    log_success "=========================================="
    echo
    log_info "Installation Summary:"
    log_info "  • Game Directory: $BALATRO_PATH"
    log_info "  • Save Directory: $BALATRO_SAVE_PATH"
    log_info "  • Lovely Injector: version.dll installed in game directory"
    log_info "  • Steamodded: Installed in $BALATRO_SAVE_PATH/Mods/"
    echo
    log_warning "REMEMBER: Launch options must be set in Steam!"
    log_info "Launch Options: WINEDLLOVERRIDES=\"version=n,b\" %command%"
    echo
    log_info "To add more mods:"
    log_info "  1. Download .lua mod files or mod folders"
    log_info "  2. Place them in: $BALATRO_SAVE_PATH/Mods/"
    log_info "  3. Launch Balatro through Steam"
    echo
    log_info "Troubleshooting:"
    log_info "  • If mods don't load, verify Steam launch options are set"
    log_info "  • Check that Balatro is running through Steam (not directly)"
    log_info "  • Make sure you're using Proton/Wine (Windows version of the game)"
    echo
    log_success "Happy modding!"
}

# Run main function
main "$@"
