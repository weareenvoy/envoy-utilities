#!/bin/bash
# mount the specified share on afp://local.weareenvoy.com interactively

SERVER="afp://local.weareenvoy.com"
SHARE="$1"
MOUNTPT="/Volumes/$SHARE"

# first we need to set up the mount point
if [ -d "$MOUNTPT" ]
then
	echo "Mount point $MOUNTPT already exists, checking for mounted file system..."
	MOUNTED=`df | egrep -c "$MOUNTPT"`
	if [[ "$MOUNTED" != 0 ]]
	then
		echo "There seems to be a filesystem already mounted on $MOUNTPT:"
		df | egrep -i "$MOUNTPT"
		echo "Exiting successfully..."
		exit 0
	else
		echo "Found directory at ${MOUNTPT} but no filesystem is mounted there, exiting..."
		echo 1
	fi
	chmod 700 $MOUNTPT
else
	sudo mkdir -m 700 $MOUNTPT
	sudo chown $USER:staff $MOUNTPT
fi

mount_afp -i $SERVER/$SHARE $MOUNTPT

df | egrep "$MOUNTPT"
echo "Done."
