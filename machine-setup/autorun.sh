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

# Start in home dir
cd

# Pull down & run the mounting script
curl -s $MOUNT_SCRIPT_SRC > $LOCAL_SCRIPT_NAME
chmod +x $LOCAL_SCRIPT_NAME
./$LOCAL_SCRIPT_NAME IT

# Set up the machine's hostname
$HOSTNAME_SCRIPT -v

# Run scripts in the IT share
$CYLANCE_SCRIPT_DIR/$CYLANCE_REMOVE_OTHER_AV
$CYLANCE_SCRIPT_DIR/$CYLANCE_INSTALL_SCRIPT

# Open CCleaner dmg for copying
open $CCLEANER_DMG
