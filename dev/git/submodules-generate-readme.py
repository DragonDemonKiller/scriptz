#!/usr/bin/env python

"""
#Description: Run this script in a directory containing git submodules. It will generate a README.md file with links to each submodule URL. If the submodule is a repository on Github, it will append the repo's description to the link.

#Source: 
#License: 

"""


#for subdir in *
import os
import requests
import subprocess
import json
import time
readme_contents = ""

#TODO: login or hit the API limit
#TODO: merge with markdown-describe-scripts.sh, so whe can have a readme with both submodules and simple script files

print "Getting subdirectories..."
dirz = os.listdir('.') #Get list of files #TODO: list only directories

#Store the main repo's remote URL; it will allows us to compare subdirectories' remote URLs to know if they are submodules or not
origin_check = subprocess.Popen("git remote show origin | grep 'Fetch URL:' | awk -F ' ' '{print $3}'", shell=True, env={"LANG": "C"}, stdout=subprocess.PIPE)
origin_url = origin_check.stdout.read()
print "origin_url is %s" % origin_url

#Loop through each subdirectory
for subdir in dirz: #TODO: store the remote url when we are here
    print "Changing dir to %s..." % subdir
    os.chdir(subdir)
    print "Getting origin..."
    repo_check = subprocess.Popen("git remote show origin | grep 'Fetch URL:' | awk -F ' ' '{print $3}'", shell=True, env={"LANG": "C"}, stdout=subprocess.PIPE) #Get remote URL for the subdirectory
    repo_url = repo_check.stdout.read()
    if "https://github.com/" not in repo_url: #Check if the repo is on github
        isgithub = 0
        print "Not a github repo"
    else:
        isgithub = 1
        print "It's a github repo"
    
    
    if isgithub == 1:
        if repo_url == origin_url: #Compare remote URL to the main repo's URL to know if we are in a submodule
            print "We are not in a submodule, moving along."
            pass
        else:
            githubname = repo_url.split('/')[3] + "/" + repo_url.split('/')[4] #Get github's format for repos names (user/repo)
            apiurl = "https://api.github.com/repos/" + githubname.replace("\n","") #Get API info for the repo
            print "Getting API data..."
            apidata = requests.get(apiurl).json()
            description = apidata["description"] #Extract repo description for JSON returned by the API
            print "Generating markdown..."
            markdownline = " * [" + subdir + "](" + subdir + ") - " + description + "(" + repo_url + ")" #Generate markdown
            readme_contents = readme_contents + markdownline
            sleep(1) #Sleep to prevent triggering Github's rate limiting
    
    print "Back to parent dir..."
    os.chdir ('..')

print readme_contents