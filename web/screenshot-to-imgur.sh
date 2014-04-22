#!/bin/bash
# Description: Select a region of your screen, which will be captured, and uploaded to https://imgur.com/. The URL will then be injected into your clipboard.
# Dependencies: scrot, xclip, libnotify-bin, curl, grep
# Source: http://sirupsen.com/a-simple-imgur-bash-screenshot-utility
# Source: https://github.com/nodiscc/scriptz
# License: MIT (http://opensource.org/licenses/MIT)

function uploadImage {
  curl -s -F "image=@$1" -F "key=486690f872c678126a2c09a9e196ce1b" http://imgur.com/api/upload.xml | grep -E -o "<original_image>(.)*</original_image>" | grep -E -o "http://i.imgur.com/[^<]*"
}

capturefile="/tmp/screenshot_`date +%s`.png"
scrot -s "$capturefile" 
uploadImage "$capturefile" | xclip -selection c
rm "$capturefile"
notify-send -i gnome-screenshot "Screenshot done" "Image uploaded to `xclip -selection c -o`, address copied to clipboard"
