#!/bin/bash
# A simple script that can be pulled down on a new or reimaged machine to get 
# it bootstrapped quickly

# TODO - intelligent switching of mount script to run based on macOS version
MACOS_VERS=`sw_vers -productVersion`
case "${MACOS_VERS}" in
	"10.13*" ) MOUNT_SCRIPT_SRC="https://raw.githubusercontent.com/weareenvoy/envoy-utilities/macos-high-sierra/machine-setup/mountenvoy.sh" ;;
	"10.14*" ) MOUNT_SCRIPT_SRC="https://raw.githubusercontent.com/weareenvoy/envoy-utilities/macos-mojave/machine-setup/mountenvoy.sh" ;;
	* ) MOUNT_SCRIPT_SRC="https://raw.githubusercontent.com/weareenvoy/envoy-utilities/master/machine-setup/mountenvoy.sh" ;;
esac

echo "Using mount script:"
echo ${MOUNT_SCRIPT_SRC}

LOCAL_SCRIPT_NAME=`mktemp -t mountenvoy` || exit 1

# Some config vars
MAC_APP_DIR="/Volumes/IT/Software/Mac"
HOSTNAME_SCRIPT="${MAC_APP_DIR}/setup/inithost.sh"

CYLANCE_SCRIPT_DIR="${MAC_APP_DIR}/Cylance"
CYLANCE_REMOVE_OTHER_AV="remove_av.sh"
CYLANCE_INSTALL_SCRIPT="install.sh"

# These are symlinked to the current dmg
CCLEANER_DMG="${MAC_APP_DIR}/CCleaner.dmg"
ALFRED_DMG="${MAC_APP_DIR}/Alfred.dmg"
CHROME_DMG="${MAC_APP_DIR}/Chrome.dmg"
SLACK_DMG="${MAC_APP_DIR}/Slack.dmg"
SONOS_DMG="${MAC_APP_DIR}/Sonos.dmg"

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

function installdmg () {
	# takes a path to a dmg file and assumes we can access it
	DMGPATH="$1"
	BASENAME=`basename ${DMGPATH}`
	APPNAME=`basename ${DMGPATH} | tr '.' ' ' | awk '{print $1}'`
	read -n 1 -p "Mount ${BASENAME}? [y/n] " INST
	echo
	if [ "${INST}" == "y" ]
	then
		# Open dmg for copying
		open $DMGPATH
		#sleep 1
		read -n 1 -p "Press a key when done with ${BASENAME}..." OK
		echo
		# All done here, unmount the dmg
		# get the mount point we created by opening the dmg
		#find /Volumes -maxdepth 1 -type d -iname "*${APPNAME}*" -exec umount -v {} \;
		DEV_ID=`df -l | egrep -i "${APPNAME}" | awk '{print $1}'`
		hdiutil detach ${DEV_ID}
	fi
}

# Let the invoker know what's happening
echo
echo "**************** Welcome to the ENVOY workstation autoconfig! *****************"
echo
echo "The first password prompt you see will be a sudo prompt, use this machine's"
echo "login password."
echo
echo "The username/password prompts which follow expect YOUR Okta user credentials."
echo "Username format is the user portion of your email - everything before the @"
echo
echo "*******************************************************************************"
echo

# Prompt for readiness 
read -n 1 -p "Press a key to continue..." OK

echo -n "Thanks and enjoy the ride"
sleepdots 5

# Start in home dir
cd

echo
echo "Mounting IT share..."
# Pull down & run the mounting script
curl -s $MOUNT_SCRIPT_SRC > $LOCAL_SCRIPT_NAME
chmod +x $LOCAL_SCRIPT_NAME
$LOCAL_SCRIPT_NAME IT

echo
# Set up the machine's hostname
$HOSTNAME_SCRIPT -v

echo 
# Run scripts in the IT share
$CYLANCE_SCRIPT_DIR/$CYLANCE_REMOVE_OTHER_AV
$CYLANCE_SCRIPT_DIR/$CYLANCE_INSTALL_SCRIPT

echo
echo "We'll install some applications via DMG now..."

installdmg ${CCLEANER_DMG}
installdmg ${ALBERT_DMG}
installdmg ${CHROME_DMG}
installdmg ${SLACK_DMG}
installdmg ${SONOS_DMG}

# Clean up
echo "Removing temp files..."
rm $LOCAL_SCRIPT_NAME

echo "Done."
