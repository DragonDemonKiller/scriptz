#!/usr/bin/python
'''
#Description: get bookmarks tag from a netscape-style bookmarks.html export (Delicious, Shaarli...) and post them to Facebook. Can post only links matching a specific tag, at a defined interval. Allows setting number of link to post.
#License: MIT (http://opensource.org/licenses/MIT)
#Source: https://github.com/nodiscc/scriptz
#Dependencies: python-bs4, fbcmd
'''

import os
from bs4 import BeautifulSoup
from subprocess import call
import time
from time import strftime
import sys
import re

try:
    scriptname = sys.argv[0]
    usertag = sys.argv[1]
    bookmarksfilename = sys.argv[2]
    sleeptime = float(sys.argv[3])
    maxcount = int(sys.argv[4])
except (IndexError, ValueError):
    print '''USAGE: %s TAG BOOKMARKS_FILE INTERVAL NUMBER_OF_LINKS
        TAG:             post links tagged TAG
        BOOKMARKS_FILE:  /path/to/bookmarks.html
        INTERVAL:        time to wait between posts
        NUMBER_OF_LINKS: post only N link''' % scriptname
    exit(1)

#Get params from user input (deprecated)
#usertag = raw_input('What tag do you want to share? (music, video...): ')
#bookmarksfilename = raw_input('Enter the bookmarks.html filename you want to read: ')
#sleeptime = float(raw_input('Time to wait between each post? (in seconds): '))
#maxcount = int(raw_input('How many links do you want to post? '))

bookmarksfile = open(bookmarksfilename)
rawdata = bookmarksfile.read()
data = BeautifulSoup(rawdata)
links = data.find_all('a')


posteditems = ""
count = 0
expectedtime = maxcount * sleeptime

print '[facebook auto poster] Posting links about %s... This will take %s seconds' % (usertag, expectedtime)
print ""

for item in links:
        if usertag in item.get('tags') and count < maxcount:
            outitem = item.contents[0]
            print '[%s] Posting %s ...' % (strftime("%H:%M:%S"), outitem)
            call(["fbcmd", "FEEDLINK", item.get('href')])
            count = count + 1
            posteditems = posteditems + "\n" + item.get('href')
            print '%s items posted! Waiting for %s seconds ...' % (count, sleeptime)
            time.sleep(int(sleeptime))
        else:
            pass

print '''
These %s links have been posted:''' % count
print posteditems
postedfilename = "posted.txt"
posted = open(postedfilename, "a")
posted.write(posteditems)
#TODO: delete posted items frrom bookmarks file after run: sed -i 's/\&amp\;/\&/g' m.html; for i in `cat posted.txt`; do sed -i "s|.*\"$i\".*||g" m.html; done; sed -i '/^$/d' m.html