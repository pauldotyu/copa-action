#!/bin/sh

image=$1
report=$2
patched_tag=$3
addr=$4

# parse image into image name
image_no_tag=$(echo "$image" | cut -d':' -f1)

# run copa to patch image
if copa patch -i "$image" -r ./data/"$report" -t "$patched_tag" --addr $addr;
then
    patched_image="$image_no_tag:$patched_tag"
    echo "patched-image=$patched_image" >> "$GITHUB_OUTPUT"
else
    echo "Error patching image $image with copa"
    exit 1
fi
