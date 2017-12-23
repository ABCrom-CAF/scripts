#!/bin/bash

# Setup compiler stuff
export USE_CCACHE=1
/usr/bin/ccache -M 50G

# Colorize and add text parameters
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
cya=$(tput setaf 6)             #  cyan
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgrn=${txtbld}$(tput setaf 2) #  green
bldblu=${txtbld}$(tput setaf 4) #  blue
bldcya=${txtbld}$(tput setaf 6) #  cyan
txtrst=$(tput sgr0)             # Reset

DEVICE="$1"
LOG="$2"
GDRIVE="$3"

# Time of build startup
res1=$(date +%s.%N)

# Setup environment
echo -e "${bldblu}Setting up build environment ${txtrst}"
. build/envsetup.sh

# Set the device
echo -e "Setting the device... ${txtrst}"
breakfast "$DEVICE-userdebug"

# Start compilation with or without log
if [ "$LOG" == "log" ]
then
    echo -e "${bldblu}Starting build kernel for $DEVICE and saving a build log file ${txtrst}"
    mka bootimage 2>&1 | tee buildkernel.log;
else
   echo -e "${bldblu}Starting build kernel for $DEVICE without saving a build log file ${txtrst}"
   mka bootimage;
fi

# Google Drive upload
if [ "$GDRIVE" == "gdrive" ]
then
   echo -e "${bldblu}Uploading bootimage to Google Drive ${txtrst}"
   gdrive upload $BUILD_PATH/boot.img;
fi

# Get elapsed time
res2=$(date +%s.%N)
echo "${bldgrn}Total time elapsed: ${txtrst}${grn}$(echo "($res2 - $res1) / 60"|bc ) minutes ($(echo "$res2 - $res1"|bc ) seconds) ${txtrst}"

#kill java if it's hanging on
pkill java
