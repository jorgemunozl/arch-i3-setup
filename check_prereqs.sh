#!/bin/bash

# Pre-installation Check Script
# Run this before the main installation to verify everything is ready

echo "🔍 Arch Linux i3 Pre-Installation Check"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_passed=0
check_failed=0
warnings=0

# Function to print check results
print_check() {
    if [ "$2" = "PASS" ]; then
        echo -e "✅ ${GREEN}PASS${NC}: $1"
        ((check_passed++))
    elif [ "$2" = "FAIL" ]; then
        echo -e "❌ ${RED}FAIL${NC}: $1"
        ((check_failed++))
    elif [ "$2" = "WARN" ]; then
        echo -e "⚠️  ${YELLOW}WARN${NC}: $1"
        ((warnings++))
    fi
}

echo ""
echo "🔍 System Checks:"

# Check if Arch Linux
if [ -f /etc/arch-release ]; then
    print_check "Running on Arch Linux" "PASS"
else
    print_check "Not running on Arch Linux" "FAIL"
fi

# Check internet connection
if ping -c 1 google.com &> /dev/null; then
    print_check "Internet connection available" "PASS"
else
    print_check "No internet connection" "FAIL"
fi

# Check if user has sudo access
if sudo -n true 2>/dev/null; then
    print_check "Sudo access available (cached)" "PASS"
elif groups | grep -q wheel; then
    print_check "User in wheel group (sudo access)" "PASS"
else
    print_check "No sudo access detected" "FAIL"
fi

# Check pacman
if command -v pacman &> /dev/null; then
    print_check "Pacman package manager available" "PASS"
    
    # Check if pacman database is locked
    if [ -f /var/lib/pacman/db.lck ]; then
        print_check "Pacman database lock file exists (may indicate stuck process)" "WARN"
        echo "   💡 Solution: sudo rm /var/lib/pacman/db.lck"
    fi
    
    # Test pacman database access
    if sudo pacman -Sy --noconfirm &>/dev/null; then
        print_check "Pacman database accessible" "PASS"
    else
        print_check "Pacman database issues detected" "WARN"
        echo "   💡 Try: sudo pacman -Syy"
    fi
else
    print_check "Pacman not found" "FAIL"
fi

# Check git
if command -v git &> /dev/null; then
    print_check "Git is installed" "PASS"
else
    print_check "Git not installed" "WARN"
fi

# Check if X11 is already configured
if [ -d /etc/X11 ]; then
    print_check "X11 directory exists" "PASS"
else
    print_check "X11 directory not found" "WARN"
fi

# Check available disk space (need at least 2GB)
available_space=$(df / | awk 'NR==2 {print $4}')
if [ "$available_space" -gt 2097152 ]; then # 2GB in KB
    print_check "Sufficient disk space available" "PASS"
else
    print_check "Low disk space (need at least 2GB free)" "WARN"
fi

echo ""
echo "📁 Configuration File Checks:"

# Check if dotfiles exist
config_files=(
    ".config/i3/config"
    ".config/i3status/config"
    ".config/alacritty/alacritty.yml"
    ".xinitrc"
    "install_i3.sh"
    "post_install.sh"
)

for file in "${config_files[@]}"; do
    if [ -f "$file" ]; then
        print_check "Found $file" "PASS"
    else
        print_check "Missing $file" "FAIL"
    fi
done

echo ""
echo "📊 Summary:"
echo "=========="
echo -e "✅ Passed: ${GREEN}$check_passed${NC}"
echo -e "❌ Failed: ${RED}$check_failed${NC}"
echo -e "⚠️  Warnings: ${YELLOW}$warnings${NC}"

echo ""
if [ $check_failed -eq 0 ]; then
    echo -e "${GREEN}🎉 All critical checks passed!${NC}"
    echo "You can proceed with the installation by running:"
    echo "  ./install_i3.sh"
    exit 0
else
    echo -e "${RED}❌ Critical issues found!${NC}"
    echo "Please fix the failed checks before running the installation."
    exit 1
fi
