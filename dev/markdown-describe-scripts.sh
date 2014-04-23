#!/bin/bash
#Description: Generate a markdown-formatted list of all scripts in a directory, along with their descriptions
#Source: https://github.com/nodiscc/scriptz
#License: http://opensource.org/licenses/MIT 

#Lines with descriptions have to start with "#Description: "

for i in *
do
	md_desc=$(grep "^#Description" "$i" 2>/dev/null | cut -d " " -f 1 --complement)
	echo " * [$i]($i) - $md_desc"
done