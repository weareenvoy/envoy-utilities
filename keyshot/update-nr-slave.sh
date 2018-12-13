#!/bin/bash

# Automagically pull the latest version of the Keyshot network rendering .pkg
# down to the local machine and install it
#

NR_DOWNLOAD_URL="https://www.keyshot.com/?ddownload=339273"


# pull pkg file - make sure it's a .pkg first
IS_PKG=`curl -sI "${NR_DOWNLOAD_URL}" | egrep -i '^location' | egrep -i '\.pkg'`
EXT=`curl -sI "${NR_DOWNLOAD_URL}" | egrep -i '^location' | awk -F "." '{print $NF}'`

# operate in Downloads
cd ~/Downloads

# do stuff with it
case "$EXT" in
	"pkg" )
		# get that thing and save it
		echo "Pulling file..."
		FILENAME=`curl -sI "${NR_DOWNLOAD_URL}" | egrep -i '^location' | awk -F "/" '{print $NF}'`
		curl -sL "${NR_DOWNLOAD_URL}" > $FILENAME
		# install it
		echo "Installing from $FILENAME"
		sudo installer -pkg $FILENAME -target /
		;;
	* )
		# didn't get something we can use
		echo "Got file with extension $EXT in request, exiting..."
		exit 1
		;;
esac

echo "Done."
