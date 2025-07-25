#!/bin/sh

# .xinitrc - X11 initialization script
# This file is executed when you run 'startx'

# Load user resources and settings
userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# Merge in defaults and keymaps
if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# Start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

# Set keyboard layout (change to your preferred layout)
setxkbmap us

# Start compositor for transparency and effects
picom -b &

# Set wallpaper (create a wallpapers directory)
if [ -f "$HOME/Pictures/wallpaper.jpg" ]; then
    feh --bg-scale "$HOME/Pictures/wallpaper.jpg" &
elif [ -f "$HOME/Pictures/wallpaper.png" ]; then
    feh --bg-scale "$HOME/Pictures/wallpaper.png" &
else
    # Set a solid color background if no wallpaper found
    xsetroot -solid "#1e1e1e"
fi

# Start network manager applet
nm-applet &

# Start bluetooth manager
blueman-applet &

# Disable screen blanking
xset s off
xset -dpms

# Start i3 window manager
exec i3
