#!/bin/bash
# Diagnose "lost connection to X server" / X session dying after startx.
# That message means the X server (or the whole session) ended — not a TCP "network" issue.
#
# Usage:
#   ./fix_x_lost_connection.sh           # show diagnostics only
#   ./fix_x_lost_connection.sh --minimal # backup ~/.xinitrc and use .xinitrc.minimal (no picom, etc.)

set -euo pipefail

REPO_DIR=$(cd "$(dirname "$0")" && pwd)
MINIMAL="$REPO_DIR/.xinitrc.minimal"

echo "=== X session lost — diagnostics (run on the machine that fails) ==="
echo ""

if [[ ! -f /etc/arch-release ]]; then
    echo "This script targets Arch Linux."
fi

echo "What it means: programs talk to X over a local socket. If Xorg or your WM exits,"
echo "every client prints something like 'lost connection to X server'."
echo ""

# --- Find newest Xorg log under ~/.local/share/xorg or /var/log ---
pick_newest() {
    local dir=$1 newest="" t=0 ts f
    [[ -d "$dir" ]] || return 1
    shopt -s nullglob
    for f in "$dir"/Xorg*.log; do
        ts=$(stat -c %Y "$f" 2>/dev/null) || ts=0
        if (( ts >= t )); then t=$ts; newest=$f; fi
    done
    shopt -u nullglob
    [[ -n "$newest" ]] && { echo "$newest"; return 0; }
    return 1
}

LOG=""
for d in "$HOME/.local/share/xorg" /var/log; do
    if LOG=$(pick_newest "$d"); then
        break
    fi
done

if [[ -n "$LOG" && -f "$LOG" ]]; then
    echo "Xorg log: $LOG"
    if [[ -r "$LOG" ]]; then
        echo "---- (EE) error lines (fatal / serious) ----"
        grep '(EE)' "$LOG" 2>/dev/null || echo "(no (EE) lines — still read tail below)"
        echo ""
        echo "---- last 40 lines ----"
        tail -40 "$LOG"
        echo "--------------------------------------"
    else
        echo "(not readable as this user; try: sudo less \"$LOG\")"
    fi
else
    echo "No Xorg*.log found yet. After a failed startx, look under:"
    echo "  ~/.local/share/xorg/Xorg.0.log"
    echo "Run:  startx 2>&1 | tee ~/xsession-debug.log"
fi

echo ""
echo "---- i3 log (if any) ----"
if [[ -f "$HOME/.config/i3/log" ]]; then
    tail -30 "$HOME/.config/i3/log"
else
    echo "(no ~/.config/i3/log — enable debug in i3 config if needed)"
fi

echo ""
echo "---- quick checks ----"
if [[ -d /tmp/.X11-unix ]]; then
    ls -la /tmp/.X11-unix 2>/dev/null || true
else
    echo "No /tmp/.X11-unix (X not running — expected from SSH/TTY without X)."
fi

echo ""
echo "Common fixes (try in order on the affected PC):"
echo "  1) Use minimal session (disables picom/feh applets — isolates crashes):"
echo "       $REPO_DIR/fix_x_lost_connection.sh --minimal"
echo "  2) Read the (EE) lines above — often GPU driver / modesetting / permissions."
echo "  3) NVIDIA: ensure drivers match kernel; see repo fix_nvidia_firmware.sh if needed."
echo "  4) RAM: OOM killer stops X — check: dmesg | tail -50  (after failure)"
echo "  5) Reinstall X stack: sudo pacman -S xorg-server xorg-xinit xorg-xrandr"
echo ""

if [[ "${1:-}" == "--minimal" ]]; then
    if [[ ! -f "$MINIMAL" ]]; then
        echo "ERROR: missing $MINIMAL (run from arch-i3-setup clone)."
        exit 1
    fi
    if [[ -f "$HOME/.xinitrc" ]]; then
        bak="$HOME/.xinitrc.bak.$(date +%Y%m%d_%H%M%S)"
        cp -a "$HOME/.xinitrc" "$bak"
        echo "Backed up ~/.xinitrc -> $bak"
    fi
    cp -a "$MINIMAL" "$HOME/.xinitrc"
    echo "Installed minimal ~/.xinitrc (i3 + setxkbmap + xsetroot only)."
    echo "Log in on TTY and run:  startx"
fi
