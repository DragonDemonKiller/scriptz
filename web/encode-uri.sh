#!/bin/bash
#Description: This command line percent-encodes strings, even binary data.
#License: CC-BY-SA (https://creativecommons.org/licenses/by-sa/3.0/)
#Source: https://andy.wordpress.com/2008/09/17/urlencode-in-bash-with-perl/

ENCODED=$(echo -n "$@" | \
perl -pe's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg');
echo $ENCODED
