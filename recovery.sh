#!/bin/bash

# Recovery Script for i3 Installation Issues
# Run this if something goes wrong during installation

echo "🚨 i3 Installation Recovery Script"
echo "================================="

echo ""
echo "This script will help recover from common installation issues."
echo ""

# Function to restore .bashrc
restore_bashrc() {
    echo "🔄 Restoring .bashrc..."
    
    # Find the most recent backup
    backup_file=$(find ~ -name ".bashrc.backup.*" -type f 2>/dev/null | sort | tail -1)
    
    if [ -n "$backup_file" ]; then
        cp "$backup_file" ~/.bashrc
        echo "✅ Restored .bashrc from $backup_file"
    else
        echo "⚠️  No .bashrc backup found"
        echo "Creating minimal .bashrc..."
        cat > ~/.bashrc << 'EOF'
# Basic .bashrc
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
export EDITOR=vim
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -la'

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
EOF
        echo "✅ Created minimal .bashrc"
    fi
}

# Function to remove auto-login
remove_autologin() {
    echo "🔄 Removing auto-login configuration..."
    
    if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
        sudo rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf
        sudo rmdir /etc/systemd/system/getty@tty1.service.d 2>/dev/null
        echo "✅ Auto-login configuration removed"
    else
        echo "ℹ️  No auto-login configuration found"
    fi
}

# Function to reset i3 config
reset_i3_config() {
    echo "🔄 Resetting i3 configuration..."
    
    if [ -d ~/.config/i3 ]; then
        mv ~/.config/i3 ~/.config/i3.backup.$(date +%Y%m%d_%H%M%S)
        echo "✅ Backed up existing i3 config"
    fi
    
    mkdir -p ~/.config/i3
    
    # Create minimal i3 config
    cat > ~/.config/i3/config << 'EOF'
# Minimal i3 configuration
set $mod Mod4
font pango:monospace 8
floating_modifier $mod

bindsym $mod+Return exec i3-sensible-terminal
bindsym $mod+Shift+q kill
bindsym $mod+d exec dmenu_run

# Focus
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Move
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Workspaces
bindsym $mod+1 workspace 1
bindsym $mod+2 workspace 2
bindsym $mod+3 workspace 3
bindsym $mod+4 workspace 4
bindsym $mod+5 workspace 5

bindsym $mod+Shift+1 move container to workspace 1
bindsym $mod+Shift+2 move container to workspace 2
bindsym $mod+Shift+3 move container to workspace 3
bindsym $mod+Shift+4 move container to workspace 4
bindsym $mod+Shift+5 move container to workspace 5

bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec "i3-msg exit"

bar {
    status_command i3status
}
EOF
    
    echo "✅ Created minimal i3 configuration"
}

# Function to check system status
check_system() {
    echo "🔍 Checking system status..."
    
    echo ""
    echo "📊 System Information:"
    echo "- OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "- Kernel: $(uname -r)"
    echo "- User: $(whoami)"
    echo "- Groups: $(groups)"
    
    echo ""
    echo "📦 Package Status:"
    packages=("i3-wm" "i3status" "xorg-server" "alacritty")
    for pkg in "${packages[@]}"; do
        if pacman -Qs "$pkg" > /dev/null; then
            echo "✅ $pkg: Installed"
        else
            echo "❌ $pkg: Not installed"
        fi
    done
    
    echo ""
    echo "🖥️  Display Server:"
    if [ -n "$DISPLAY" ]; then
        echo "✅ X11 is running (DISPLAY=$DISPLAY)"
    else
        echo "ℹ️  X11 is not running"
    fi
    
    echo ""
    echo "⚙️  Services:"
    services=("NetworkManager" "bluetooth")
    for service in "${services[@]}"; do
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            echo "✅ $service: Enabled"
        else
            echo "❌ $service: Not enabled"
        fi
    done
}

# Main menu
main_menu() {
    echo ""
    echo "🛠️  Recovery Options:"
    echo "1. Check system status"
    echo "2. Restore .bashrc from backup"
    echo "3. Remove auto-login configuration"
    echo "4. Reset i3 configuration to minimal"
    echo "5. Install missing core packages"
    echo "6. Remove i3 completely"
    echo "7. Exit"
    echo ""
    read -p "Choose an option (1-7): " choice
    
    case $choice in
        1) check_system ;;
        2) restore_bashrc ;;
        3) remove_autologin ;;
        4) reset_i3_config ;;
        5) 
            echo "Installing core packages..."
            sudo pacman -S --needed i3-wm i3status xorg-server xorg-xinit alacritty
            ;;
        6)
            echo "⚠️  This will remove i3 and related packages!"
            read -p "Are you sure? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                sudo pacman -R i3-wm i3status i3lock dmenu
                echo "✅ i3 packages removed"
            fi
            ;;
        7) echo "👋 Goodbye!"; exit 0 ;;
        *) echo "❌ Invalid option"; main_menu ;;
    esac
}

# Run main menu
main_menu

echo ""
echo "🔄 Recovery operation completed!"
echo "You may want to reboot your system if you made significant changes."
