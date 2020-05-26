#!/bin/bash
# A simple script that can be pulled down on a new or reimaged machine to get 
# it bootstrapped quickly

# TODO - intelligent switching of mount script to run based on macOS version
MACOS_VERS=`sw_vers -productVersion`
case "${MACOS_VERS}" in
	10.13* ) MOUNT_SCRIPT_MACOS_REL="macos-high-sierra" ;;
	10.14* ) MOUNT_SCRIPT_MACOS_REL="macos-mojave" ;;
	10.15* ) MOUNT_SCRIPT_MACOS_REL="macos-catalina" ;;
	* ) MOUNT_SCRIPT_MACOS_REL="master" ;;
esac

MOUNT_SCRIPT_SRC="https://raw.githubusercontent.com/weareenvoy/envoy-utilities/${MOUNT_SCRIPT_MACOS_REL}/machine-setup/mountenvoy.sh"

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
# we get this through managed App Store via VPP now 
#ALFRED_DMG="${MAC_APP_DIR}/Alfred.dmg"
CHROME_DMG="${MAC_APP_DIR}/Chrome.dmg"
# we get this through managed App Store via VPP now 
#SLACK_DMG="${MAC_APP_DIR}/Slack.dmg"
SONOS_DMG="${MAC_APP_DIR}/Sonos.dmg"
ADOBECC_DMG="${MAC_APP_DIR}/Adobe/CreativeCloud.dmg"

# Control the order of the mounts - notably AdobeCC should be last as they have 
# a sneaky pkg in the dmg which just installs the desktop app installer.. D:
# TODO - pull AdobeCC pkg out of dmg and install in the pkg section
INSTALL_DMGS=( "${CCLEANER_DMG}" "${CHROME_DMG}" "${SONOS_DMG}" "${ADOBECC_DMG}" )

# These are symlinked to real pkg files - unclear whether it is desirable or 
# sane to install large applications (ie Office365) via pkg from the server 
# directly. Installs over wifi could be subject to inconsistent behavior
OFFICE365_PKG="${MAC_APP_DIR}/Office365/Office365.pkg"
KEYSHOT_PKG="${MAC_APP_DIR}/Keyshot/Keyshot.pkg"
KEYSHOT_NR_PKG="${MAC_APP_DIR}/Keyshot/Keyshot_NR.pkg"
ZOOM_PKG="${MAC_APP_DIR}/Zoom/Zoom.pkg"
ZOOMROOMS_PKG="${MAC_APP_DIR}/Zoom/ZoomRooms.pkg"

# Again, we control the order of the pkg installs because reasons
INSTALL_PKGS=( "${OFFICE365_PKG}" "${KEYSHOT_PKG}" "${KEYSHOT_NR_PKG}" "${ZOOM_PKG}" "${ZOOMROOMS_PKG}" )

# These are symlinked to zip files - just prompt to copy them to Downloads
# since their contents and unzip behavior may not be known at the time of run
SKETCH_ZIP="${MAC_APP_DIR}/Sketch/Sketch.zip"
PREPROS_ZIP="${MAC_APP_DIR}/Prepros.zip"

# Group the zip files
INSTALL_ZIPS=( "${SKETCH_ZIP}" "${PREPROS_ZIP}" )

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
	read -n 1 -p "Mount ${DMG_FILENAME}? [y/N] " INST
	echo
	if [ "${INST}" == "y" ]
	then
		# Open dmg for copying
		open $DMGPATH
		#sleep 1
		# copy the .app (if found) to /Applications
		#MOUNTPT=`df -l | egrep -i "${DMG_APPNAME}" | awk '{print $NF}'`
		#find ${MOUNTPT} -maxdepth 1 -type d -name '*.app' -exec cp -va {} /Applications \;
		read -n 1 -p "Press a key after installation of ${DMG_FILENAME} is complete..." OK
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
			read -n 1 -p "Does '${GUESS_MNT_NAME}' look right? [y/N] " OK
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

# get sudo at attention so all subsequent calls are auth'd
sudo -v

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
echo

# loop through the active dmg installers
for admg in "${INSTALL_DMGS[@]}"
do
	installdmg ${admg}
done

echo
echo "And we'll install a couple applications via pkg..."
echo

# loop through the active pkg installers
for apkg in "${INSTALL_PKGS[@]}"
do
	PKG_FILENAME=`basename ${apkg}`
	PKG_APPNAME=`basename ${apkg} | tr '.' ' ' | awk '{print $1}'`
	read -n 1 -p "Install ${PKG_APPNAME}? [y/N] " PKGINST
	echo
	if [ "${PKGINST}" != "y" ]
	then
		read -n 1 -p "Copy ${PKG_FILENAME} to Downloads? [y/N] " PKGCOPY
		echo
		if [ "${PKGCOPY}" == "y" ]
		then
			# just copy the pkg - some won't install over the network
			cp -v "${apkg}" ~/Downloads
		fi
		continue
	fi
	echo "Installing ${PKG_FILENAME}..."
	#sudo installer -pkg ${apkg} -target / -verboseR
	# we'll do the pkg installs interactively since that's how we're already 
	# doing the dmg's as well
	open ${apkg}
	#sleep 1
	read -n 1 -p "Press a key when done installing ${PKG_FILENAME}..." OK
	echo
done

echo
echo "Last we'll copy a few application zip files..."
echo

# loop through the active pkg installers
# loop through zip files
for azip in "${INSTALL_ZIPS[@]}"
do
	ZIP_FILENAME=`basename ${azip}`
	#ZIP_APPNAME=`basename ${azip} | tr '.' ' ' | awk '{print $1}'`
	read -n 1 -p "Copy ${ZIP_FILENAME} to Downloads? [y/N] " ZIPCOPY
	echo
	if [ "${ZIPCOPY}" != "y" ]
	then
		continue
	fi
	# just copy the zip - contents too unpredictable to install here
	cp -v "${azip}" ~/Downloads
done

# Clean up
echo "Removing temp files..."
rm $LOCAL_SCRIPT_NAME

echo "Done."
