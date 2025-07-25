# Arch Linux i3 Window Manager Setup

A complete dotfiles configuration for Arch Linux with i3 window manager, designed for a CLI-first experience with fast boot times and minimal resource usage.

## 🚀 Features

- **CLI-First Boot**: System boots directly to command line for faster startup
- **i3 Window Manager**: Lightweight, tiling window manager
- **Auto-login**: Automatic login to TTY1 for immediate access
- **Custom Keybindings**: Optimized shortcuts for productivity
- **Minimal Resource Usage**: Fast and efficient system
- **One-Command Installation**: Automated setup scripts

## 📋 Prerequisites

- Fresh Arch Linux installation
- Internet connection
- User account with sudo privileges
- Git installed (`sudo pacman -S git`)

## 🛠️ Installation

### Step 1: Pre-Installation Check

**⚠️ IMPORTANT: Always run the pre-installation check first!**

```bash
# Using HTTPS (recommended for most users)
git clone https://github.com/jorgemunozl/dotfiles.git
cd dotfiles
./check_prereqs.sh
```

> **Note**: If you have SSH keys configured, you can also use:
> ```bash
> git clone git@github.com:jorgemunozl/dotfiles.git
> ```

This will verify:
- ✅ You're on Arch Linux
- ✅ Internet connection works
- ✅ You have sudo privileges 
- ✅ All configuration files are present
- ✅ Sufficient disk space available

### Step 2: Main Installation

Only proceed if the pre-check passes:

```bash
# Optional: Cache sudo password to minimize prompts
sudo -v

# Run the main installation
./install_i3.sh
```

> **Tip**: `sudo -v` refreshes your sudo timestamp, so you won't be prompted for your password multiple times during installation.

The script will:
- Install i3 window manager and dependencies
- Configure auto-login to TTY1
- Set up essential system services
- Copy configuration files safely

### Step 3: Post-Installation Setup

```bash
./post_install.sh
```

This adds:
- Desktop entries
- Wallpaper configuration
- Utility scripts
- User services

### Step 4: Reboot

```bash
sudo reboot
```

## 🎯 Usage

After reboot, you'll automatically login to the command line interface.

### Starting the GUI

To start the i3 window manager:

```bash
startx
```

Or use the custom script:

```bash
./start_i3.sh
```

### Key Bindings

| Shortcut | Action |
|----------|--------|
| `Super + Enter` | Open terminal |
| `Super + d` | Application launcher (dmenu) |
| `Super + Shift + q` | Close focused window |
| `Super + Shift + r` | Restart i3 |
| `Super + Shift + e` | Exit i3 |
| `Super + 1-9` | Switch to workspace 1-9 |
| `Super + Shift + 1-9` | Move window to workspace 1-9 |
| `Super + h/v` | Split horizontal/vertical |
| `Super + f` | Toggle fullscreen |
| `Super + Space` | Toggle floating window |

### Utility Scripts

Located in `~/scripts/`:

```bash
# Brightness control
~/scripts/brightness.sh up    # Increase brightness
~/scripts/brightness.sh down  # Decrease brightness

# Volume control
~/scripts/volume.sh up        # Increase volume
~/scripts/volume.sh down      # Decrease volume
~/scripts/volume.sh mute      # Toggle mute

# Screenshots
~/scripts/screenshot.sh       # Take screenshot
```

## 📁 Configuration Files

```
dotfiles/
├── .config/
│   ├── i3/
│   │   └── config              # i3 window manager configuration
│   ├── i3status/
│   │   └── config              # Status bar configuration
│   └── alacritty/
│       └── alacritty.yml       # Terminal emulator configuration
├── .xinitrc                    # X11 initialization
├── .bashrc                     # Bash configuration with aliases
├── install_i3.sh              # Main installation script
├── post_install.sh            # Post-installation configuration
├── start_i3.sh                # Script to start i3
└── README.md                   # This file
```

## 🎨 Customization

### Wallpapers

Place your wallpaper in `~/Pictures/` as:
- `wallpaper.jpg` or `wallpaper.png`

### i3 Configuration

Edit `~/.config/i3/config` to customize:
- Key bindings
- Workspace names
- Window rules
- Startup applications

### Terminal

Edit `~/.config/alacritty/alacritty.yml` to customize:
- Colors
- Fonts
- Opacity
- Key bindings

### Aliases

Edit `~/.bashrc` to add custom aliases and functions.

## 🔧 System Services

The installation configures:

- **Auto-login**: Automatic login to TTY1
- **NetworkManager**: Network management
- **Bluetooth**: Bluetooth support
- **User services**: Background applications

## 📊 System Information

Display system info:

```bash
neofetch
```

Monitor system resources:

```bash
htop
```

## 🚨 Troubleshooting & Recovery

### 🔧 Quick Fix Tool

If you're having any pacman or installation issues, use the dedicated troubleshooting tool:

```bash
./fix_pacman.sh
```

This interactive script will:
- ✅ Diagnose common pacman issues
- 🔧 Provide automatic fixes
- 🎯 Guide you through manual solutions
- 🤖 Auto-fix mode for common problems

### 🎮 NVIDIA Fix Tool

For NVIDIA firmware conflicts and graphics issues:

```bash
./fix_nvidia_firmware.sh
```

This interactive script will:
- 🔍 Detect NVIDIA hardware and conflicts
- 🛠️ Resolve firmware filesystem conflicts
- ⚡ Install appropriate drivers (open source or proprietary)
- 🔧 Fix common NVIDIA installation issues

### If Something Goes Wrong

**Recovery Script**: Run if installation fails
```bash
./recovery.sh
```

Options include:
- Check system status
- Restore .bashrc backup
- Remove auto-login
- Reset i3 to minimal config
- Install missing packages
- Complete removal

### Common Issues

**Package database update fails**
```bash
# Error: "Failed to update package database!"
# Try these solutions in order:

# 1. Force refresh package databases
sudo pacman -Syy

# 2. Remove package database lock (if another pacman is stuck)
sudo rm /var/lib/pacman/db.lck
sudo pacman -Syy

# 3. Check for running pacman processes
ps aux | grep pacman
sudo killall pacman  # if any are found

# 4. Update mirrors (if repositories are slow/broken)
sudo pacman -S reflector
sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# 5. Force full system update
sudo pacman -Syyu
```

**NVIDIA firmware conflicts**
```bash
# Error: "linux-firmware-nvidia /usr/lib/firmware/nvidia/... exists in filesystem"
# Use the dedicated NVIDIA fix tool:
./fix_nvidia_firmware.sh

# Or manual fix:
sudo pacman -S --overwrite='*' linux-firmware
sudo pacman -S --overwrite='*' nvidia nvidia-utils
```

**X Server won't start**
```bash
# Check logs
cat /var/log/Xorg.0.log

# Install graphics drivers
sudo pacman -S xf86-video-intel  # Intel
sudo pacman -S xf86-video-amdgpu # AMD
sudo pacman -S nvidia            # NVIDIA
```

**Audio not working**
```bash
sudo pacman -S pulseaudio pulseaudio-alsa
pulseaudio --start
```

**Network issues**
```bash
sudo systemctl status NetworkManager
sudo systemctl restart NetworkManager
```

**Alacritty version compatibility issues**
```bash
# If Alacritty fails to start, try the legacy config
cp ~/.config/alacritty/alacritty_legacy.yml ~/.config/alacritty/alacritty.yml

# Or install a specific Alacritty version
sudo pacman -S alacritty
```

**Rollback Auto-login**
```bash
sudo rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf
```

## 🔄 Updates

To update the system:

```bash
# Update packages
sudo pacman -Syu

# Update AUR packages (if yay is installed)
yay -Syu
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License.

## 👤 Author

**Jorge Muñoz**
- GitHub: [@jorgemunozl](https://github.com/jorgemunozl)
- Email: [your-email@example.com]

## 🙏 Acknowledgments

- [i3 Window Manager](https://i3wm.org/)
- [Arch Linux Community](https://archlinux.org/)
- [Luke Smith's dotfiles](https://github.com/LukeSmithxyz/voidrice) (inspiration)

## 📚 Additional Resources

- [i3 User Guide](https://i3wm.org/docs/userguide.html)
- [Arch Linux Wiki](https://wiki.archlinux.org/)
- [r/unixporn](https://reddit.com/r/unixporn) (for inspiration)

---

**Happy tiling! 🚀**
