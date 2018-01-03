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
GDRIVE="$5"
SHUTDOWN="$6"

ROOT_PATH=$PWD
BUILD_PATH="$ROOT_PATH/out/target/product/$DEVICE"

# Start tracking time
echo -e ${bldblu}
echo -e "---------------------------------------"
echo -e "SCRIPT STARTING AT $(date +%D\ %r)"
echo -e "---------------------------------------"
echo -e ${txtrst}

START=$(date +%s)

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
   echo -e "${bldblu}Compiling for $DEVICE and saving a build log file ${txtrst}"
   mka bacon 2>&1 | tee build.log;
else
   echo -e "${bldblu}Compiling for $DEVICE without saving a build log file ${txtrst}"
   mka bacon;
fi

# If the above was successful
if [ `ls $BUILD_PATH/ABCrom_*.zip 2>/dev/null | wc -l` != "0" ]
then
   BUILD_RESULT="Build successful"

    # Copy the device ROM.zip to root (and before doing this, remove old device builds but not the last one of them, adding an OLD_tag to it)
    echo -e "${bldblu}Copying ROM.zip and Changelog to $ROOT_PATH ${txtrst}"

    if [ `ls $ROOT_PATH/OLD_ABCrom_$DEVICE-*.zip 2>/dev/null | wc -l` != "0" ]
    then
    rm OLD_ABCrom_$DEVICE-*.zip
    fi

    if [ `ls $ROOT_PATH/ABCrom_$DEVICE-*.zip 2>/dev/null | wc -l` != "0" ]
    then
    for file in ABCrom_$DEVICE-*.zip
    do
        mv -f "${file}" "${file/ABCrom/OLD_ABCrom}"
    done
    fi

    cp $BUILD_PATH/ABCrom_*.zip $ROOT_PATH
    cp $BUILD_PATH/$DEVICE-Changelog.txt $ROOT_PATH
    # Google Drive upload
    if [ "$GDRIVE" == "gdrive" ]
    then
    echo -e "${bldblu}Uploading build to Google Drive ${txtrst}"
    gdrive upload ABCrom_*.zip
	gdrive upload $DEVICE-Changelog.txt
    fi
# If the build failed
else
   BUILD_RESULT="Build failed"
fi

# back to root dir
cd $ROOT_PATH

# Stop tracking time
END=$(date +%s)
echo -e ${bldblu}
echo -e "-------------------------------------"
echo -e "SCRIPT ENDING AT $(date +%D\ %r)"
echo -e ""
echo -e "${BUILD_RESULT}!"
echo -e "TIME: $(echo $((${END}-${START})) | awk '{print int($1/60)" MINUTES AND "int($1%60)" SECONDS"}')"
echo -e "-------------------------------------"
echo -e ${txtrst}

BUILDTIME="Build time: $(echo $((${END}-${START})) | awk '{print int($1/60)" minutes and "int($1%60)" seconds"}')"

#kill java if it's hanging on
pkill java

# Shutdown the system if required by the user
if [ "$SHUTDOWN" == "off" ]
then
  poweroff
fi
