#!/bin/bash

# Post-installation configuration script for i3
# Run this after installing i3 to set up additional configurations

set -e

echo "========================================"
echo "i3 Post-Installation Configuration"
echo "========================================"

# Function to create desktop entries
create_desktop_entries() {
    echo "Creating desktop entries..."
    
    # Create Start i3 desktop entry
    cat > ~/.local/share/applications/start-i3.desktop <<EOF
[Desktop Entry]
Name=Start i3
Comment=Start i3 Window Manager
Exec=$HOME/dotfiles/start_i3.sh
Icon=preferences-desktop
Terminal=true
Type=Application
Categories=System;
EOF
    
    echo "Desktop entries created."
}

# Function to setup wallpaper directory
setup_wallpapers() {
    echo "Setting up wallpaper directory..."
    
    mkdir -p ~/Pictures/wallpapers
    
    # Download a default wallpaper if none exists
    if [ ! -f ~/Pictures/wallpaper.jpg ] && [ ! -f ~/Pictures/wallpaper.png ]; then
        echo "Downloading default wallpaper..."
        curl -L -o ~/Pictures/wallpaper.jpg "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920&h=1080&fit=crop" 2>/dev/null || {
            echo "Failed to download wallpaper, creating solid color background"
            convert -size 1920x1080 xc:'#1e1e1e' ~/Pictures/wallpaper.png 2>/dev/null || true
        }
    fi
    
    echo "Wallpaper setup complete."
}

# Function to configure git (if not already configured)
configure_git() {
    if [ -z "$(git config --global user.email)" ]; then
        echo "Configuring Git..."
        echo "Please enter your Git email:"
        read -r git_email
        echo "Please enter your Git name:"
        read -r git_name
        
        git config --global user.email "$git_email"
        git config --global user.name "$git_name"
        echo "Git configured."
    else
        echo "Git already configured."
    fi
}

# Function to create useful scripts
create_scripts() {
    echo "Creating utility scripts..."
    
    mkdir -p ~/scripts
    
    # Screen brightness script
    cat > ~/scripts/brightness.sh <<'EOF'
#!/bin/bash
case "$1" in
    up)   brightnessctl set 10%+ ;;
    down) brightnessctl set 10%- ;;
    *)    echo "Usage: $0 {up|down}" ;;
esac
EOF
    chmod +x ~/scripts/brightness.sh
    
    # Volume control script
    cat > ~/scripts/volume.sh <<'EOF'
#!/bin/bash
case "$1" in
    up)     pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
    down)   pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
    mute)   pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
    *)      echo "Usage: $0 {up|down|mute}" ;;
esac
EOF
    chmod +x ~/scripts/volume.sh
    
    # Screenshot script
    cat > ~/scripts/screenshot.sh <<'EOF'
#!/bin/bash
mkdir -p ~/Pictures/screenshots
case "$1" in
    full)   import ~/Pictures/screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png ;;
    window) import -window root ~/Pictures/screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png ;;
    select) import ~/Pictures/screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png ;;
    *)      import ~/Pictures/screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png ;;
esac
notify-send "Screenshot saved" "Saved to ~/Pictures/screenshots/"
EOF
    chmod +x ~/scripts/screenshot.sh
    
    echo "Utility scripts created in ~/scripts/"
}

# Function to setup systemd user services for better session management
setup_user_services() {
    echo "Setting up user services..."
    
    mkdir -p ~/.config/systemd/user
    
    # Create a service to automatically start some background apps
    cat > ~/.config/systemd/user/desktop-apps.service <<'EOF'
[Unit]
Description=Desktop Applications
After=graphical-session.target

[Service]
Type=forking
ExecStart=/bin/bash -c 'picom -b; sleep 2; nm-applet &'
Restart=on-failure

[Install]
WantedBy=default.target
EOF
    
    # Enable the service
    systemctl --user enable desktop-apps.service
    
    echo "User services configured."
}

# Main execution
main() {
    echo "Running post-installation configuration..."
    
    create_desktop_entries
    setup_wallpapers
    configure_git
    create_scripts
    setup_user_services
    
    echo ""
    echo "========================================"
    echo "Post-installation configuration complete!"
    echo "========================================"
    echo ""
    echo "Additional customizations applied:"
    echo "- Desktop entries created"
    echo "- Wallpaper directory setup"
    echo "- Utility scripts created in ~/scripts/"
    echo "- User services configured"
    echo ""
    echo "You can now:"
    echo "1. Customize your wallpaper in ~/Pictures/"
    echo "2. Use brightness controls: ~/scripts/brightness.sh {up|down}"
    echo "3. Use volume controls: ~/scripts/volume.sh {up|down|mute}"
    echo "4. Take screenshots: ~/scripts/screenshot.sh"
    echo ""
}

main "$@"
