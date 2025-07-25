#!/bin/bash
# Load keybindings from text files

# Function to apply settings from a file
apply_settings() {
  local file=$1
  if [ -f "$file" ]; then
    while read -r schema key value; do
      # Skip empty or invalid lines
      if [ -n "$schema" ] && [ -n "$key" ]; then
        gsettings set "$schema" "$key" "$value"
      fi
    done < "$file"
    echo "Applied settings from $file"
  else
    echo "Warning: $file not found."
  fi
}

# Apply all the keybinding settings
apply_settings "gnome_desktop_wm_keybindings.txt"
apply_settings "media_keys_keybindings.txt"
apply_settings "custom_keybindings.txt"
apply_settings "power_keybindings.txt"
apply_settings "mutter_keybindings.txt"
apply_settings "shell_keybindings.txt"

echo "Keybinding restoration complete."
