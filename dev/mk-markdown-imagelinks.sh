#!/bin/bash
#Description: Take image files as parameters, generate a thumbnail for each one in thumbs/, and print a markdown link showing the thumbnail and pointing to the image.
#License: MIT http://opensource.org/licenses/MIT
#Source: https://github.com/nodiscc/scriptz
#Usage: run it from the same directory as your markdown file (to make sure the
#relative markdown link is correct)

set -e

THUMBNAIL_SIZE="200"
IMAGES_DIR="_media"

if [ ! -d "$IMAGES_DIR/thumbs" ]
then
	mkdir "$IMAGES_DIR/thumbs"
fi

for IMAGE in $@
do
	if echo "$IMAGE" | grep "_thumb."
	then
		echo "$IMAGE already a thumbnail"; 
	else
		IMAGE_EXTENSION=`echo "$IMAGE" | awk -F "." '{print $NF}'`
		IMAGE_BASENAME=`basename "$IMAGE" "$IMAGE_EXTENSION"`
		convert -thumbnail "$THUMBNAIL_SIZE"x "$IMAGE" "$IMAGES_DIR/thumbs/${IMAGE_BASENAME}_thumb.${IMAGE_EXTENSION}"
		echo "[![](${IMAGES_DIR}/thumbs/${IMAGE_BASENAME}_thumb.${IMAGE_EXTENSION})](${IMAGE})"
	fi
done



