#!/bin/bash
# A simple script that can be pulled down on a new or reimaged machine to get 
# it bootstrapped quickly

MOUNT_SCRIPT_SRC="https://raw.githubusercontent.com/alex-envoy/envoy-utilities/master/machine-setup/mountenvoy.sh"
LOCAL_SCRIPT_NAME="mountenvoy.sh"

HOSTNAME_SCRIPT="/Volumes/IT/Software/Mac/setup/inithost.sh"
CYLANCE_SCRIPT_DIR="/Volumes/IT/Software/Mac/Cylance"
CYLANCE_REMOVE_OTHER_AV="remove_av.sh"
CYLANCE_INSTALL_SCRIPT="install.sh"

CCLEANER_DMG="/Volumes/IT/Software/Mac/CCleaner_MacSetup115.dmg"

function sleepdots () {
	# takes an int, sleeps for that many seconds and prints a dot as progress
	if [ -z "$1" ]
	then
		DOTS=1
	else
		DOTS="$1"
	fi

	while [ "$DOTS" -gt 0 ]
	do
		((DOTS--))
		echo -n "."
		sleep 1
	done
	echo ""
}

# Start in home dir
cd

# Let the user know what's happening
echo "*** Welcome to the ENVOY workstation autoconfig! ***"
echo
echo "The first password prompt you see will be a sudo prompt, use this machine's"
echo "login password."
echo
echo "The username/password prompts which follows expect YOUR Okta user credentials."
echo "Username format is the user portion of your email - everything before the @"
echo
echo -n "Thanks and enjoy the ride"

sleepdots 5

echo
echo "Mounting IT share..."
# Pull down & run the mounting script
curl -s $MOUNT_SCRIPT_SRC > $LOCAL_SCRIPT_NAME
chmod +x $LOCAL_SCRIPT_NAME
./$LOCAL_SCRIPT_NAME IT

echo
# Set up the machine's hostname
$HOSTNAME_SCRIPT -v

echo 
# Run scripts in the IT share
$CYLANCE_SCRIPT_DIR/$CYLANCE_REMOVE_OTHER_AV
$CYLANCE_SCRIPT_DIR/$CYLANCE_INSTALL_SCRIPT

echo
# Open CCleaner dmg for copying
open $CCLEANER_DMG

echo "Done."
