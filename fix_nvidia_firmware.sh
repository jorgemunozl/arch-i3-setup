#!/bin/bash

# NVIDIA Firmware Conflict Fix Script
# Resolves "exists in filesystem" errors when installing NVIDIA packages

echo "🔧 NVIDIA Firmware Conflict Resolver"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to run command and show result
run_fix() {
    local description="$1"
    local command="$2"
    
    echo -e "${BLUE}🔄 $description${NC}"
    echo "Command: $command"
    echo ""
    
    if eval "$command"; then
        echo -e "${GREEN}✅ Success!${NC}"
    else
        echo -e "${RED}❌ Failed!${NC}"
    fi
    echo ""
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}❌ Don't run this script as root! Use your regular user account.${NC}"
   exit 1
fi

echo -e "${YELLOW}⚠️  NVIDIA Firmware Conflict Detected${NC}"
echo ""
echo "This script will resolve the conflict between:"
echo "- linux-firmware package"
echo "- NVIDIA proprietary drivers"
echo ""
echo "The conflict occurs because both packages try to install"
echo "the same firmware files in /usr/lib/firmware/nvidia/"
echo ""

# Check current NVIDIA status
echo -e "${BLUE}📊 Checking Current NVIDIA Status${NC}"
echo "=================================="
echo ""

# Check if NVIDIA hardware is present
if lspci | grep -i nvidia > /dev/null; then
    echo -e "${GREEN}✅ NVIDIA GPU detected:${NC}"
    lspci | grep -i nvidia
    echo ""
else
    echo -e "${YELLOW}⚠️  No NVIDIA GPU detected${NC}"
    echo "You may not need NVIDIA drivers on this system."
    echo ""
fi

# Check installed NVIDIA packages
echo -e "${BLUE}📦 Installed NVIDIA packages:${NC}"
pacman -Q | grep -i nvidia || echo "No NVIDIA packages installed"
echo ""

# Check conflicting files
echo -e "${BLUE}🔍 Checking for conflicting files:${NC}"
if [ -d "/usr/lib/firmware/nvidia" ]; then
    echo "Files in /usr/lib/firmware/nvidia/:"
    ls -la /usr/lib/firmware/nvidia/ | head -10
    echo ""
else
    echo "No conflicting firmware directory found"
    echo ""
fi

# Menu for fixes
show_menu() {
    echo -e "${BLUE}🛠️  Available Fixes:${NC}"
    echo "==================="
    echo "1. Remove conflicting firmware files"
    echo "2. Force reinstall linux-firmware"
    echo "3. Install NVIDIA drivers (open source)"
    echo "4. Install NVIDIA drivers (proprietary)"
    echo "5. Remove all NVIDIA packages"
    echo "6. Auto-fix (recommended)"
    echo "7. Check system status"
    echo "8. Exit"
    echo ""
}

# Auto-fix function
auto_fix() {
    echo -e "${BLUE}🤖 Running automatic NVIDIA firmware fix...${NC}"
    echo ""
    
    # Remove conflicting files manually
    if [ -d "/usr/lib/firmware/nvidia" ]; then
        echo -e "${YELLOW}⚠️  Removing conflicting firmware files...${NC}"
        run_fix "Backing up existing NVIDIA firmware" "sudo cp -r /usr/lib/firmware/nvidia /usr/lib/firmware/nvidia.backup.$(date +%Y%m%d_%H%M%S)"
        run_fix "Removing conflicting firmware directory" "sudo rm -rf /usr/lib/firmware/nvidia"
    fi
    
    # Force reinstall linux-firmware
    run_fix "Reinstalling linux-firmware package" "sudo pacman -S --overwrite='*' linux-firmware"
    
    # Install appropriate NVIDIA drivers
    echo -e "${BLUE}💭 Choosing NVIDIA driver...${NC}"
    if lspci | grep -i nvidia | grep -i geforce > /dev/null; then
        echo "GeForce GPU detected - installing proprietary drivers"
        run_fix "Installing NVIDIA proprietary drivers" "sudo pacman -S --overwrite='*' nvidia nvidia-utils"
    else
        echo "Installing open source drivers (safe choice)"
        run_fix "Installing open source NVIDIA drivers" "sudo pacman -S --overwrite='*' xf86-video-nouveau"
    fi
    
    echo -e "${GREEN}🎉 Auto-fix completed!${NC}"
    echo "Reboot your system to apply changes."
}

# Main loop
main() {
    while true; do
        show_menu
        read -p "Choose an option (1-8): " choice
        echo ""
        
        case $choice in
            1)
                echo -e "${YELLOW}⚠️  This will remove conflicting firmware files${NC}"
                read -p "Continue? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    run_fix "Backing up NVIDIA firmware" "sudo cp -r /usr/lib/firmware/nvidia /usr/lib/firmware/nvidia.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo 'No backup needed'"
                    run_fix "Removing conflicting firmware" "sudo rm -rf /usr/lib/firmware/nvidia"
                fi
                ;;
            2)
                run_fix "Force reinstalling linux-firmware" "sudo pacman -S --overwrite='*' linux-firmware"
                ;;
            3)
                run_fix "Installing open source NVIDIA drivers" "sudo pacman -S --overwrite='*' xf86-video-nouveau"
                ;;
            4)
                echo -e "${YELLOW}⚠️  This will install proprietary NVIDIA drivers${NC}"
                read -p "Continue? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    run_fix "Installing NVIDIA proprietary drivers" "sudo pacman -S --overwrite='*' nvidia nvidia-utils"
                fi
                ;;
            5)
                echo -e "${YELLOW}⚠️  This will remove ALL NVIDIA packages${NC}"
                read -p "Continue? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    run_fix "Removing NVIDIA packages" "sudo pacman -Rns $(pacman -Q | grep nvidia | awk '{print $1}' | tr '\n' ' ') 2>/dev/null || echo 'No NVIDIA packages to remove'"
                fi
                ;;
            6)
                auto_fix
                ;;
            7)
                echo -e "${BLUE}📊 System Status${NC}"
                echo "GPU Information:"
                lspci | grep -i vga
                echo ""
                echo "NVIDIA packages:"
                pacman -Q | grep nvidia || echo "None installed"
                echo ""
                echo "Graphics drivers:"
                pacman -Q | grep -E "(nvidia|nouveau|mesa)" || echo "None found"
                ;;
            8)
                echo "👋 Goodbye!"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid option${NC}"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        echo ""
    done
}

# Run main function
main
