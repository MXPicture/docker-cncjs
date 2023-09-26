#!/bin/bash
# get last cncjs/cncjs version
ARCHIVE_URL=$(git ls-remote --tags https://github.com/cncjs/cncjs | cut -f 2 | cut -d "/" -f 3 | awk -F'[v]' '/^v[0-9]+\.[0-9]+\.[0-9]+$/ {print $2}' | awk -F'[/.]' '{print $1+1000 "." $2+1000 "." $3+1000}' | sort -r | awk -F'[/.]' '{print "https://github.com/cncjs/cncjs/archive/refs/tags/v" $1-1000 "." $2-1000 "." $3-1000 ".tar.gz"}' | head -n 1)
# wget -O cncjs.tar.gz "${ARCHIVE_URL}"
# mkdir cncjs_tmp # Create tmp directory
# tar -xvzf cncjs.tar.gz --directory cncjs_tmp # Extract
# find cncjs_tmp -type d -maxdepth 1 -depth 1 -exec mv -f -i {} cncjs/ \; # Move content to cncjs
# rmdir cncjs_tmp # Remove tmp directory
# rm cncjs.tar.gz # Remove archive