#!/bin/bash
#fetches a webpage and converts it to markdown
#TODO: add the original URL to the header, see man pandoc, TEMPLATES section
#TODO: name the file after the page's title
URL="$1"
OUTFILE="$2"
USAGE="USAGE: `basename $0` page_url output_file"

if [ "$1" = "" -o "$2" = "" ]
	then echo "$USAGE"
	exit 1
fi

pandoc -f html -t markdown "$URL" > "$OUTFILE"
