#!/bin/bash

# Automagically pull the latest version of the Keyshot network rendering .pkg
# down to the local machine and install it
#

NR_DOWNLOAD_URL="https://www.keyshot.com/download/345998/"

if [ -z "${USER}" ]
then
	USER=`whoami`
fi

# pull pkg file - make sure it's a .pkg first
IS_PKG=`curl -sI "${NR_DOWNLOAD_URL}" | egrep -i '^location' | egrep -ci '\.pkg'`
FILENAME=`curl -sI "${NR_DOWNLOAD_URL}" | egrep -i '^location' | awk -F "/" '{print $NF}' | tr -d "[:space:]"`
EXT=`echo -n $FILENAME | awk -F "." '{print $NF}'`

# operate in Downloads
cd ~/Downloads

# do stuff with it
case "$EXT" in
	pkg )
		# preemptively prompt for sudo so we can get that out of the way
		echo "Please provide the login password to sudo..."
		echo "Username: ${USER}"
		sudo -v

		# get that thing and save it
		echo "Pulling file ${FILENAME}..."
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
