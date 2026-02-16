# Extracts the os wallpapers from the /usr/share/backgrounds and puts them into a local folder under ~/Pictures/wallpaper/os/
#
# Creator of the script: Luca Matteo Spoljarevic
# Licence: MIT
# Originally published on Codeberg

# Creating the directory
mkdir -p ~/Pictures/wallpaper/os

# Coping all the os wallpapers to the dedicated directory
cp /usr/share/backgrounds/* ~/Pictures/wallpaper/os/

# Text output to the terminal
echo "Thank's for using this script, I hope you found it useful"
echo "Here are the wallpapers that are now in your users directory under Pictures/wallpaper/os/"

# Listing the copied wallpapers
ls ~/Pictures/wallpaper/os/
