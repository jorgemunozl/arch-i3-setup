#!/bin/bash

# Script to start i3 window manager
# Usage: ./start_i3.sh or just 'startx'

echo "Starting i3 window manager..."
echo "Welcome to your minimal desktop environment!"
echo ""
echo "Quick shortcuts:"
echo "- Super+Enter: Open terminal"
echo "- Super+d: Application launcher"
echo "- Super+Shift+q: Close window"
echo "- Super+Shift+r: Restart i3"
echo "- Super+Shift+e: Exit i3"
echo ""

# Start X server with i3
exec startx