#!/bin/bash

# Automagically pull the latest version of the Keyshot network rendering .pkg
# down to the local machine and install it
#
# The download link no longer performs a redirect with the file name in the 
# location header, so we'll have to make some assumptions

NR_DOWNLOAD_URL="https://www.keyshot.com/download/345998/"

if [ -z "${USER}" ]
then
	USER=`whoami`
fi

# pull pkg file - assume it's a pkg since there's no indication now
FILENAME="keyshot_network_rendering_mac64_9.`date +%Y%m%d%H%M`.pkg"
EXT="pkg"

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

# ask admin if they want to open the thing we just downloaded
read -n1 -p "Install from ${FILENAME}? [y|N] " yesno
if [[ "${yesno}" == "y" || "${yesno}" == "Y" ]]
then
	open ${FILENAME}
fi

echo "Done."
