#!/bin/bash
#Description: Echo a random line from a file
#License: WTFPL
#Usage: put it in /etc/update-motd.d/ !

MaxNumLines=$(wc -l /usr/local/share/glados.txt | awk '{print $1}')
LineNum=$(perl -e "print int rand($MaxNumLines)")
sed ${LineNum}"q;d" /usr/local/share/glados.txt