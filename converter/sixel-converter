# Go to assets folder where the image is
cd /mnt/storage/git/spoljarevic/.config/fastfetch/assets

# Declare Variables
FILEPATH=/mnt/storage/git/spoljarevic/.config/fastfetch/assets

# Gather information about the file name
echo "What's the Name of the File (Without file type)?"
read FILE_NAME

# Gather information about file type
echo "What's the File Type?"
read FILE_TYPE

# Gather information about the size
echo "What's the Size (Width only)?"
read FILE_WIDTH
FILE_HEIGHT=$(echo "$FILE_WIDTH / 2" | bc -l | awk '{printf "%d", $1}')

# Convert the image to sixel
chafa -s "$FILE_WIDTH"x"$FILE_WIDTH" $FILEPATH/$FILE_NAME.$FILE_TYPE > $FILEPATH/$FILE_NAME.sixel

# Display fastfetch with the image
fastfetch --raw $FILEPATH/$FILE_NAME.sixel --logo-width $FILE_HEIGHT --logo-height $FILE_HEIGHT --logo-padding-top 2 
