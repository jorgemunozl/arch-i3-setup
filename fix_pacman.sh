#!/bin/bash

# Pacman Troubleshooting Script
# Run this if you're having package manager issues

echo "🔧 Pacman Troubleshooting Tool"
echo "=============================="
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

# Function to check system state
check_pacman_state() {
    echo -e "${BLUE}📊 Checking Pacman State${NC}"
    echo "========================"
    echo ""
    
    # Check if pacman is running
    if pgrep pacman > /dev/null; then
        echo -e "${YELLOW}⚠️  Pacman processes are running:${NC}"
        ps aux | grep pacman | grep -v grep
        echo ""
        echo "Kill them with: sudo killall pacman"
        echo ""
    else
        echo -e "${GREEN}✅ No pacman processes running${NC}"
    fi
    
    # Check for lock file
    if [ -f /var/lib/pacman/db.lck ]; then
        echo -e "${YELLOW}⚠️  Pacman database is locked${NC}"
        ls -la /var/lib/pacman/db.lck
        echo ""
        echo "Remove with: sudo rm /var/lib/pacman/db.lck"
        echo ""
    else
        echo -e "${GREEN}✅ No pacman lock file${NC}"
    fi
    
    # Check network connectivity to Arch mirrors (HTTPS + IPv4 ICMP; plain ping is unreliable)
    echo -e "${BLUE}🌐 Testing connectivity to Arch Linux mirrors...${NC}"
    if {
        { command -v curl &>/dev/null && curl -fsS --max-time 8 --connect-timeout 5 -o /dev/null "https://archlinux.org/" 2>/dev/null; } ||
        { command -v wget &>/dev/null && wget -q --timeout=8 --tries=1 -O /dev/null "https://archlinux.org/" 2>/dev/null; } ||
        ping -c 1 -W 3 -4 archlinux.org &>/dev/null ||
        ping -c 1 -W 3 -4 google.com &>/dev/null
    }; then
        echo -e "${GREEN}✅ Can reach archlinux.org${NC}"
    else
        echo -e "${RED}❌ Cannot reach archlinux.org${NC}"
    fi
    echo ""
}

# Menu function
show_menu() {
    echo -e "${BLUE}🛠️  Available Fixes:${NC}"
    echo "==================="
    echo "1. Check pacman state"
    echo "2. Kill all pacman processes"
    echo "3. Remove pacman lock file"
    echo "4. Force refresh package databases"
    echo "5. Update mirror list"
    echo "6. Full system update"
    echo "7. Reset pacman configuration"
    echo "8. Fix all common issues (auto)"
    echo "9. Exit"
    echo ""
}

# Auto-fix function
auto_fix() {
    echo -e "${BLUE}🤖 Running automatic fixes...${NC}"
    echo ""
    
    # Kill pacman processes
    if pgrep pacman > /dev/null; then
        run_fix "Killing pacman processes" "sudo killall pacman"
    fi
    
    # Remove lock file
    if [ -f /var/lib/pacman/db.lck ]; then
        run_fix "Removing pacman lock file" "sudo rm /var/lib/pacman/db.lck"
    fi
    
    # Force refresh databases
    run_fix "Force refreshing package databases" "sudo pacman -Syy"
    
    # Test with a simple query
    run_fix "Testing pacman functionality" "pacman -Q pacman"
    
    echo -e "${GREEN}🎉 Auto-fix completed!${NC}"
    echo "Try running your installation script again."
}

# Main loop
main() {
    while true; do
        show_menu
        read -p "Choose an option (1-9): " choice
        echo ""
        
        case $choice in
            1)
                check_pacman_state
                ;;
            2)
                run_fix "Killing all pacman processes" "sudo killall pacman"
                ;;
            3)
                run_fix "Removing pacman lock file" "sudo rm -f /var/lib/pacman/db.lck"
                ;;
            4)
                run_fix "Force refreshing package databases" "sudo pacman -Syy"
                ;;
            5)
                echo -e "${YELLOW}⚠️  This will install reflector and update mirrors${NC}"
                read -p "Continue? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    run_fix "Installing reflector" "sudo pacman -S --noconfirm reflector"
                    run_fix "Updating mirror list" "sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist"
                fi
                ;;
            6)
                run_fix "Full system update" "sudo pacman -Syyu"
                ;;
            7)
                echo -e "${YELLOW}⚠️  This will reset pacman keys and configuration${NC}"
                read -p "Continue? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    run_fix "Initializing pacman keyring" "sudo pacman-key --init"
                    run_fix "Populating pacman keyring" "sudo pacman-key --populate archlinux"
                fi
                ;;
            8)
                auto_fix
                ;;
            9)
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
