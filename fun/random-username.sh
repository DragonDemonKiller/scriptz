#!/bin/bash
#Description: get a list of random usernames from reddit.com
#Source: http://www.reddit.com/r/commandline/comments/1xcz5h/i_amuse_myself_with_random_reddit_user_names_when/

curl -L www.reddit.com/r/random/ | \
grep -o -e 'reddit.com/user/[_a-zA-Z0-9-]*' | \
cut -d / -f 3 | \
sort -u