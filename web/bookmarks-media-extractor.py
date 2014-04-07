#!/usr/bin/python
import os
from bs4 import BeautifulSoup
from subprocess import call

bookmarksfilename = 'bookmarks_all_20140303_003115.html'
usertag = "music"
#TODO: pass bookmarks filename from argv
#TODO: detect if bookmarks filename has correct format
#TODO: support plain text (not html) lists
#TODO: stream action: just play each element in mplayer using youtube-dl (do not download, play only)
#TODO: mkplaylist action: same as stream, but just output the media urls to an .m3u file
#TODO: markdown action: just send the relevant links to a nice markdown file, and convert it to HTML also
#TODO: fetch raw webpages for some predefined tags, see https://superuser.com/questions/55040/save-a-single-web-page-with-background-images-with-wget
bookmarksfile = open(bookmarksfilename)
rawdata = bookmarksfile.read()
data = BeautifulSoup(rawdata)
links = data.find_all('a')
#TODO: change working directory from argv --- os.chdir(path)
#TODO: get tags from argv
#TODO: if tag is specified, mkdir workdir/tag, change dir to it
print '[html extractor] Getting %s files...' % usertag
os.chdir(usertag)
for item in links:
    if usertag in item.get('tags') and 'nodl' not in item.get('tags'):
        outitem = " * [" + item.contents[0] + "](" + item.get('href') + ")" + " `@" + item.get('tags') + "`"
        print outitem #TODO: print to outfile
        #call(["youtube-dl", "--extract-audio", "--audio-quality", "0", item.get('href')])
        call(["youtube-dl", item.get('href')])
#    print item.get('tags')
