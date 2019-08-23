#!/bin/bash
# A simple script that can be pulled down on a new or reimaged machine to get 
# it bootstrapped quickly

# TODO - intelligent switching of mount script to run based on macOS version
MACOS_VERS=`sw_vers -productVersion`
case "${MACOS_VERS}" in
	10.13* ) MOUNT_SCRIPT_SRC="https://raw.githubusercontent.com/weareenvoy/envoy-utilities/macos-high-sierra/machine-setup/mountenvoy.sh" ;;
	10.14* ) MOUNT_SCRIPT_SRC="https://raw.githubusercontent.com/weareenvoy/envoy-utilities/macos-mojave/machine-setup/mountenvoy.sh" ;;
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
ADOBECC_DMG="${MAC_APP_DIR}/Adobe/CreativeCloud.dmg"

# Control the order of the mounts - notably AdobeCC should be last as they have 
# a sneaky pkg in the dmg which just installs the desktop app installer.. D:
# TODO - pull AdobeCC pkg out of dmg and install in the pkg section
INSTALL_DMGS=( "${CCLEANER_DMG}" "${ALFRED_DMG}" "${CHROME_DMG}" "${SLACK_DMG}" "${SONOS_DMG}" "${ADOBECC_DMG}" )

# These are symlinked to real pkg files - unclear whether it is desirable or 
# sane to install large applications (ie Office365) via pkg from the server 
# directly. Installs over wifi could be subject to inconsistent 
OFFICE365_PKG="${MAC_APP_DIR}/Office365/Office365.pkg"

# Again, we control the order of the pkg installs because reasons
INSTALL_PKGS=( "${OFFICE365_PKG}" )

# Utility functions
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
	# takes a path to a dmg file
	DMGPATH="$1"
	if [ ! -e "${DMGPATH}" ]
	then
		echo "Can't access ${DMGPATH} or it doesn't exist, skipping..."
		return
	fi

	# the DMGPATH is at least a file
	DMG_FILENAME=`basename ${DMGPATH}`
	DMG_APPNAME=`basename ${DMGPATH} | tr '.' ' ' | awk '{print $1}'`
	read -n 1 -p "Mount ${DMG_FILENAME}? [y/n] " INST
	echo
	if [ "${INST}" == "y" ]
	then
		# Open dmg for copying
		open $DMGPATH
		#sleep 1
		read -n 1 -p "Press a key after done using ${DMG_FILENAME}..." OK
		echo
		# All done here, unmount the dmg
		# get the mount point we created by opening the dmg
		#find /Volumes -maxdepth 1 -type d -iname "*${DMG_APPNAME}*" -exec umount -v {} \;
		DEV_ID=`df -l | egrep -i "${DMG_APPNAME}" | awk '{print $1}'`
		if [ -z "${DEV_ID}" ]
		then
			GUESS_DEV_ID=`df -l | tail -n1 | awk '{print $1}'`
			GUESS_MNT_NAME=`df -l | tail -n1 | egrep -o '/Volumes.*$'`
			echo "Didn't find a mounted dmg for ${DMG_APPNAME}..."
			read -n 1 -p "Does '${GUESS_MNT_NAME}' look right? [y/n] " OK
			echo
			if [ "${OK}" == "y" ]
			then
				DEV_ID="${GUESS_DEV_ID}"
			else
				return
			fi
		fi
		# eject dmg
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
echo "We'll install some applications via dmg now..."

# loop through the active dmg installers
for admg in "${INSTALL_DMGS[@]}"
do
	installdmg ${admg}
done

echo
echo "And we'll install a couple applications via pkg..."

# loop through the active pkg installers
for apkg in "${INSTALL_PKGS[@]}"
do
	PKG_FILENAME=`basename ${apkg}`
	PKG_APPNAME=`basename ${apkg} | tr '.' ' ' | awk '{print $1}'`
	echo "Installing ${PKG_FILENAME}..."
	#sudo installer -pkg ${apkg} -target / -verboseR
	# we'll do the pkg installs interactively since that's how we're already 
	# doing the dmg's as well
	open ${apkg}
	#sleep 1
	read -n 1 -p "Press a key when done installing ${PKG_FILENAME}..." OK
	echo
done

# Clean up
echo "Removing temp files..."
rm $LOCAL_SCRIPT_NAME

echo "Done."
