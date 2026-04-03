#!/bin/bash
# Fix "command not found" / missing xinitrc when running startx.
#
# Common causes on Arch:
#   - xorg-xinit not installed (no /etc/X11/xinit/xinitrc)
#   - References to /etc/x11/... (lowercase) — invalid on case-sensitive filesystems
#
# Run on the machine that shows the error:  bash fix_startx.sh

set -euo pipefail

echo "=== fix_startx: repair X / startx setup ==="
echo ""

if [[ ! -f /etc/arch-release ]]; then
    echo "This script is for Arch Linux."
    exit 1
fi

if [[ ${EUID:-0} -eq 0 ]]; then
    echo "Run as a normal user (the script will use sudo where needed)."
    exit 1
fi

echo "[1/4] Installing xorg-xinit and xorg-server if missing..."
sudo pacman -S --needed --noconfirm xorg-xinit xorg-server

XINIT_SYS=/etc/X11/xinit/xinitrc
if [[ ! -f "$XINIT_SYS" ]]; then
    echo "ERROR: $XINIT_SYS still missing after install. Try: sudo pacman -S xorg-xinit"
    exit 1
fi
echo "  OK: system xinitrc present ($XINIT_SYS)"

echo ""
echo "[2/4] Compatibility symlink /etc/x11 -> /etc/X11 (fixes lowercase path typos)..."
if [[ -e /etc/x11 ]]; then
    if [[ -L /etc/x11 ]]; then
        echo "  OK: /etc/x11 already exists -> $(readlink -f /etc/x11)"
    else
        echo "  SKIP: /etc/x11 exists and is not a symlink; not changing it."
    fi
else
    sudo ln -s /etc/X11 /etc/x11
    echo "  Created: /etc/x11 -> /etc/X11"
fi

echo ""
echo "[3/4] Fixing ~/.xinitrc if it uses /etc/x11/ (lowercase)..."
if [[ -f "$HOME/.xinitrc" ]]; then
    if grep -qF '/etc/x11' "$HOME/.xinitrc" 2>/dev/null; then
        cp -a "$HOME/.xinitrc" "$HOME/.xinitrc.bak.$(date +%Y%m%d_%H%M%S)"
        sed -i 's|/etc/x11|/etc/X11|g' "$HOME/.xinitrc"
        echo "  Patched ~/.xinitrc (backup created alongside)."
    else
        echo "  No lowercase /etc/x11 paths in ~/.xinitrc."
    fi
else
    echo "  No ~/.xinitrc — startx will use the system default unless you add one."
    if [[ -f "$(dirname "$0")/.xinitrc" ]]; then
        echo "  Tip: copy from this repo: cp \"$(dirname "$0")/.xinitrc\" ~/.xinitrc"
    fi
fi

echo ""
echo "[4/4] Quick checks..."
missing=0
for need in startx xinit Xorg; do
    if command -v "$need" &>/dev/null || [[ -x "/usr/bin/$need" ]]; then
        echo "  OK: $need"
    else
        echo "  MISSING: $need"
        missing=1
    fi
done

echo ""
if [[ "$missing" -eq 0 ]]; then
    echo "Done. Log in on a TTY and run:  startx"
    echo ""
    echo "If startx still fails, check:"
    echo "  - Remove a broken startx alias: unalias startx  (then try again)"
    echo "  - Or use: /usr/bin/startx"
    echo "  - Minimal session test: cp \"$(dirname "$0")/.xinitrc.minimal\" ~/.xinitrc"
else
    echo "Some X binaries are still missing; reinstall: sudo pacman -S xorg-server xorg-xinit"
    exit 1
fi
