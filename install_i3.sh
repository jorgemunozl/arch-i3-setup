#!/bin/bash

# i3 Installation Script for Arch Linux
# This script installs i3 window manager and necessary dependencies

set -e  # Exit on any error

echo "========================================"
echo "i3 Window Manager Installation for Arch"
echo "========================================"

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check if we're on Arch Linux
    if [ ! -f /etc/arch-release ]; then
        echo "❌ This script is designed for Arch Linux only!"
        exit 1
    fi
    
    # Check internet connection
    if ! ping -c 1 archlinux.org &> /dev/null; then
        echo "❌ No internet connection detected!"
        echo "Please check your network connection and try again."
        exit 1
    fi
    
    # Check if pacman is available
    if ! command -v pacman &> /dev/null; then
        echo "❌ pacman package manager not found!"
        exit 1
    fi
    
    # Check if user is in wheel group (sudo access)
    if ! groups | grep -q wheel; then
        echo "❌ User is not in the wheel group (no sudo access)!"
        echo "Add your user to wheel group: sudo usermod -aG wheel $(whoami)"
        exit 1
    fi
    
    echo "✓ All prerequisites met."
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo "This script should NOT be run as root!"
        echo "Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Function to install packages with pacman
install_packages() {
    echo "Updating package database..."
    
    # Try to update package database with multiple attempts
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts: Updating package database..."
        
        if sudo pacman -Syu --noconfirm; then
            echo "✓ Package database updated successfully."
            break
        else
            echo "❌ Failed to update package database (attempt $attempt)"
            
            if [ $attempt -eq $max_attempts ]; then
                echo ""
                echo "🔧 TROUBLESHOOTING PACKAGE DATABASE UPDATE:"
                echo "=========================================="
                echo ""
                echo "Common causes and solutions:"
                echo ""
                echo "1. 📡 Network connectivity issues:"
                echo "   sudo pacman -Syy  # Force refresh package databases"
                echo ""
                echo "2. 🔒 Corrupted package database:"
                echo "   sudo rm /var/lib/pacman/db.lck"
                echo "   sudo pacman -Syy"
                echo ""
                echo "3. 🏃‍♂️ Another pacman instance running:"
                echo "   ps aux | grep pacman"
                echo "   sudo killall pacman"
                echo ""
                echo "4. 📦 Mirror issues:"
                echo "   sudo pacman -S reflector"
                echo "   sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist"
                echo ""
                echo "5. 🔄 Try manual update:"
                echo "   sudo pacman -Syyu"
                echo ""
                echo "After fixing the issue, run the installation script again."
                exit 1
            else
                echo "⏳ Waiting 5 seconds before retry..."
                sleep 5
                ((attempt++))
            fi
        fi
    done
    
    echo "Installing i3 and essential packages..."
    
    # Core packages that MUST be installed
    local core_packages=(
        "i3-wm"
        "i3status" 
        "i3lock"
        "dmenu"
        "xorg-server"
        "xorg-xinit"
        "alacritty"
    )
    
    # Optional packages (installation failure won't stop the script)
    local optional_packages=(
        "xorg-xrandr"
        "xorg-xset"
        "xorg-xsetroot"
        "rofi"
        "feh"
        "picom"
        "nitrogen"
        "thunar"
        "firefox"
        "brightnessctl"
        "pulseaudio"
        "pulseaudio-alsa"
        "pavucontrol"
        "networkmanager"
        "network-manager-applet"
        "bluez"
        "bluez-utils"
        "blueman"
        "git"
        "vim"
        "neofetch"
        "htop"
        "tree"
        "unzip"
        "zip"
        "wget"
        "curl"
        "ttf-dejavu"
        "ttf-liberation"
        "noto-fonts"
        "noto-fonts-emoji"
        "imagemagick"
        "xf86-video-intel"    # Intel graphics
        "xf86-video-amdgpu"   # AMD graphics
        "xf86-video-nouveau"  # Open source NVIDIA
    )
    
    # Install core packages (must succeed)
    echo "Installing core i3 packages..."
    if ! sudo pacman -S --needed --noconfirm "${core_packages[@]}"; then
        echo "❌ Failed to install core packages!"
        echo "This is critical - installation cannot continue."
        exit 1
    fi
    echo "✓ Core packages installed successfully."
    
    # Install optional packages (failures are logged but don't stop installation)
    echo "Installing optional packages..."
    local failed_packages=()
    for package in "${optional_packages[@]}"; do
        if ! sudo pacman -S --needed --noconfirm "$package" 2>/dev/null; then
            failed_packages+=("$package")
            echo "⚠️  Warning: Failed to install $package"
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        echo "⚠️  The following packages failed to install: ${failed_packages[*]}"
        echo "You can install them manually later with: sudo pacman -S ${failed_packages[*]}"
    fi
    
    # Handle NVIDIA graphics specifically
    if lspci | grep -i nvidia > /dev/null; then
        echo "🎮 NVIDIA GPU detected. Handling NVIDIA drivers..."
        echo "Note: If you encounter firmware conflicts, run: ./fix_nvidia_firmware.sh"
        
        # Try to install NVIDIA drivers with overwrite flag for firmware conflicts
        if sudo pacman -S --needed --noconfirm --overwrite='*' nvidia nvidia-utils 2>/dev/null; then
            echo "✓ NVIDIA proprietary drivers installed successfully."
        else
            echo "⚠️  NVIDIA driver installation had issues. You may need to:"
            echo "   1. Run: ./fix_nvidia_firmware.sh"
            echo "   2. Or manually resolve conflicts with: sudo pacman -S --overwrite='*' nvidia nvidia-utils"
        fi
    fi
    
    echo "✓ Package installation completed."
}

# Function to install AUR helper (yay)
install_aur_helper() {
    if ! command -v yay &> /dev/null; then
        echo "Installing yay AUR helper..."
        
        # Check if base-devel is installed
        if ! pacman -Qs base-devel > /dev/null; then
            echo "Installing base-devel for AUR building..."
            sudo pacman -S --needed --noconfirm base-devel
        fi
        
        # Create temporary directory
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        if git clone https://aur.archlinux.org/yay.git; then
            cd yay
            if makepkg -si --noconfirm; then
                echo "✓ yay installed successfully."
            else
                echo "⚠️  Warning: Failed to install yay. You can install AUR packages manually."
            fi
        else
            echo "⚠️  Warning: Failed to clone yay repository."
        fi
        
        # Return to original directory and cleanup
        cd - > /dev/null
        rm -rf "$temp_dir"
    else
        echo "✓ yay is already installed."
    fi
}

# Function to setup dotfiles
setup_dotfiles() {
    echo "Setting up i3 configuration..."
    
    # Create necessary directories
    mkdir -p ~/.config/i3
    mkdir -p ~/.config/i3status
    mkdir -p ~/.config/alacritty
    mkdir -p ~/.config/rofi
    mkdir -p ~/.local/share/applications
    
    # Copy configuration files
    if [ -f "$(pwd)/.config/i3/config" ]; then
        cp "$(pwd)/.config/i3/config" ~/.config/i3/
        echo "✓ i3 config copied."
    else
        echo "⚠️  Warning: i3 config file not found in $(pwd)/.config/i3/config"
    fi
    
    if [ -f "$(pwd)/.config/i3status/config" ]; then
        cp "$(pwd)/.config/i3status/config" ~/.config/i3status/
        echo "✓ i3status config copied."
    else
        echo "⚠️  Warning: i3status config file not found"
    fi
    
    if [ -f "$(pwd)/.config/alacritty/alacritty.yml" ]; then
        cp "$(pwd)/.config/alacritty/alacritty.yml" ~/.config/alacritty/
        echo "✓ Alacritty config copied."
        
        # Also copy legacy format as backup
        if [ -f "$(pwd)/.config/alacritty/alacritty_legacy.yml" ]; then
            cp "$(pwd)/.config/alacritty/alacritty_legacy.yml" ~/.config/alacritty/
            echo "✓ Alacritty legacy config also copied as backup."
        fi
    else
        echo "⚠️  Warning: Alacritty config file not found"
    fi
    
    if [ -f "$(pwd)/.xinitrc" ]; then
        cp "$(pwd)/.xinitrc" ~/
        echo "✓ .xinitrc copied."
    else
        echo "⚠️  Warning: .xinitrc file not found"
    fi
    
    if [ -f "$(pwd)/.bashrc" ]; then
        # Backup existing .bashrc
        if [ -f ~/.bashrc ]; then
            cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
            echo "✓ Existing .bashrc backed up."
        fi
        cp "$(pwd)/.bashrc" ~/
        echo "✓ New .bashrc copied."
    else
        echo "⚠️  Warning: .bashrc file not found"
    fi
}

# Function to enable services
enable_services() {
    echo "Configuring system services..."
    
    # NetworkManager
    if systemctl list-unit-files | grep -q NetworkManager.service; then
        sudo systemctl enable NetworkManager
        if sudo systemctl start NetworkManager; then
            echo "✓ NetworkManager enabled and started."
        else
            echo "⚠️  Warning: NetworkManager failed to start."
        fi
    else
        echo "⚠️  Warning: NetworkManager not found."
    fi
    
    # Bluetooth
    if systemctl list-unit-files | grep -q bluetooth.service; then
        sudo systemctl enable bluetooth
        if sudo systemctl start bluetooth; then
            echo "✓ Bluetooth enabled and started."
        else
            echo "⚠️  Warning: Bluetooth failed to start."
        fi
    else
        echo "⚠️  Warning: Bluetooth service not found."
    fi
    
    echo "✓ Service configuration completed."
}

# Function to setup auto-login to TTY (CLI boot)
setup_cli_boot() {
    echo "Setting up CLI-first boot (auto-login to TTY)..."
    
    # Create systemd override directory
    sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
    
    # Create auto-login configuration
    sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin $(whoami) %I \$TERM
EOF
    
    echo "Auto-login to TTY1 configured for user: $(whoami)"
}

# Main execution
main() {
    echo "🚀 Starting i3 installation process..."
    echo "This will install i3 window manager and configure CLI-first boot."
    echo ""
    
    check_prerequisites
    check_root
    
    echo ""
    echo "📋 Installation Summary:"
    echo "- Install i3 window manager and dependencies"
    echo "- Configure auto-login to TTY1"
    echo "- Set up dotfiles and configurations"
    echo "- Enable essential services"
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
    
    echo ""
    echo "🔄 Installing packages..."
    install_packages
    
    echo ""
    echo "🔧 Installing AUR helper..."
    install_aur_helper
    
    echo ""
    echo "📁 Setting up dotfiles..."
    setup_dotfiles
    
    echo ""
    echo "⚙️  Configuring services..."
    enable_services
    
    echo ""
    echo "🖥️  Setting up CLI boot..."
    setup_cli_boot
    
    echo ""
    echo "========================================"
    echo "✅ Installation completed successfully!"
    echo "========================================"
    echo ""
    echo "📝 Next steps:"
    echo "1. Reboot your system: 'sudo reboot'"
    echo "2. After reboot, you'll auto-login to CLI"
    echo "3. Type 'startx' to start i3 window manager"
    echo "4. Use 'Super+Enter' to open terminal"
    echo "5. Use 'Super+d' to open application launcher"
    echo ""
    echo "⌨️  Key bindings (Super = Windows key):"
    echo "- Super+Enter: Terminal (Alacritty)"
    echo "- Super+d: Application launcher (dmenu)"
    echo "- Super+r: Rofi launcher"
    echo "- Super+Shift+q: Close window"
    echo "- Super+Shift+r: Restart i3"
    echo "- Super+Shift+e: Exit i3"
    echo "- Super+1-9: Switch workspaces"
    echo "- Super+F1: Firefox"
    echo "- Super+F2: File manager"
    echo "- Super+F3: Code editor"
    echo ""
    echo "🎉 Happy tiling!"
}

main "$@"
