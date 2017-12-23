#!/bin/bash

# Setup compiler stuff
export USE_CCACHE=1
/usr/bin/ccache -M 50G
out/host/linux-x86/bin/jack-admin kill-server
export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4000m"
out/host/linux-x86/bin/jack-admin start-server

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
SYNC="$2"
CLEAN="$3"
LOG="$4"
APK="$5"
GDRIVE="$6"

ROOT_PATH=$PWD
BUILD_PATH="$ROOT_PATH/out/target/product/$DEVICE"

# Time of build startup
res1=$(date +%s.%N)

# Sync with latest sources
if [ "$SYNC" == "sync" ]
then
   echo -e "${bldblu}Syncing latest sources ${txtrst}"
   repo sync
fi

# Setup environment
echo -e "${bldblu}Setting up build environment ${txtrst}"
. build/envsetup.sh

# Set the device
echo -e "Setting the device... ${txtrst}"
breakfast "$DEVICE-userdebug"

# Clean out folder
if [ "$CLEAN" == "clean" ]
then
   echo -e "${bldblu}Cleaning up the OUT folder with make clobber ${txtrst}"
   make clean;
else
  echo -e "${bldblu}No make clobber so just make installclean ${txtrst}"
  make installclean;
fi

# Start compilation with or without log
if [ "$LOG" == "log" ]
then
   echo -e "${bldblu}Compiling $APK apk for $DEVICE and saving a build-apk log file ${txtrst}"
   make $APK 2>&1 | tee build-apk.log;
else
   echo -e "${bldblu}Compiling $APK for $DEVICE without saving a build log file ${txtrst}"
   make $APK;
fi

# Google Drive upload
if [ "$GDRIVE" == "gdrive" ]
then
   echo -e "${bldblu}Uploading $APK to Google Drive ${txtrst}"
   gdrive upload $BUILD_PATH/system/*/$APK --recursive;
fi

# Get elapsed time
res2=$(date +%s.%N)
echo "${bldgrn}Total time elapsed: ${txtrst}${grn}$(echo "($res2 - $res1) / 60"|bc ) minutes ($(echo "$res2 - $res1"|bc ) seconds) ${txtrst}"

#kill java if it's hanging on
pkill java
