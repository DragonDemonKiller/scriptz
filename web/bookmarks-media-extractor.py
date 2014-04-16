#!/usr/bin/python
import os
from bs4 import BeautifulSoup
from subprocess import call

usertag = raw_input('Enter the tag you want to download media for (music, video...): ')

bookmarksfilename = raw_input('Enter the bookmarks.html filename you want to read: ')

#TODO: detect if bookmarks filename has correct format
#TODO: support plain text (not html) lists
#TODO: stream action: just play each element in mplayer using youtube-dl (do not download, play only)
#TODO: mkplaylist action: same as stream, but just output the media urls to an .m3u file
#TODO: markdown action: just send the relevant links to a nice markdown file, and convert it to HTML also
#TODO: fetch raw webpages for some predefined tags, see https://superuser.com/questions/55040/save-a-single-web-page-with-background-images-with-wget
#TODO: for tag 'images', download images embedded in pages (use patterns like wp-contents/uploads/*.jpg, i.imgur.com/*.jpg)
bookmarksfile = open(bookmarksfilename)
rawdata = bookmarksfile.read()
data = BeautifulSoup(rawdata)
links = data.find_all('a')
#TODO: change working directory from argv --- os.chdir(path)
#TODO: if tag is specified, mkdir workdir/tag, change dir to it
print '[html extractor] Getting %s files...' % usertag
os.chdir(usertag)
for item in links:
    if usertag in item.get('tags') and 'nodl' not in item.get('tags'):
        outitem = " * [" + item.contents[0] + "](" + item.get('href') + ")" + " `@" + item.get('tags') + "`"
        print outitem #TODO: print to outfile
        #TODO: add a command line switch to extract audio
        #TODO: add a command line switch to use mp3 output (best by default)
        #call(["youtube-dl", "--extract-audio", "--audio-quality", "0", item.get('href')])
        call(["youtube-dl", "--add-metadata", item.get('href')])
        #TODO: output a file containing URLs for which youtube-dl failed
#    print item.get('tags')
