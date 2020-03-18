#!/bin/bash

# Colors makes things beautiful
export TERM=xterm
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
blu=$(tput setaf 4)             #  blue
cya=$(tput setaf 6)             #  cyan
txtrst=$(tput sgr0)             #  Reset

echo -e ${blu}"=================================="${txtrst}
echo -e ${blu}"       Unified ROM Compiler       "${txtrst}
echo -e ${blu}"=================================="${txtrst}

# CCache settings
export USE_CCACHE=1
export CCACHE_DIR="$HOME/.ccache/rom"
export CCACHE_COMPRESS=true
CCACHE_SIZE="120G"

# Directory variable
SCRIPT_DIR="$HOME/android/script"
HOME_DIR="$HOME/android"
ROMREPO_DIR="$HOME/android/rom"
PACKAGE_DIR="$HOME/android/rom/out/target/product/riva"
OUT_DIR="$HOME/android/out/rom"
DT_DIR="$HOME/android/rom/device/xiaomi/riva"
VT_DIR="$HOME/android/rom/vendor/xiaomi"
VT_DIR2="$HOME/android/rom/vendor/xiaomi/riva"
KS_DIR="$HOME/android/rom/kernel/xiaomi/msm8917"

# Build date
BUILD_DATE1=$(date +"%Y%m%d")
BUILD_DATE2=$(date +"%d%m%Y")

# Build variable input
source $SCRIPT_DIR/rom_database.sh

# Device variable
device_name=$aaa
device_codename=$bbb

# Build variable
rom_name=$aa
gapps_options=$bb
target_command=$cc
lunch_command=$dd
build_type=$ee
android_version=$ff
rom_repo=$gg
rom_branch=$hh
vt_direct=$ii
dt_repo=$jj
dt_branch=$kk
vt_repo=$ll
vt_branch=$mm
ks_repo=$nn
ks_branch=$oo
ccache_clean=$pp

# Write the information to console
echo -e ${grn}"Device          : $device_name ($device_codename)"${txtrst}
echo -e ${grn}"ROM Name        : $rom_name"${txtrst}
echo -e ${grn}"Android Version : $android_version"${txtrst}
echo -e ${grn}"GApps Options   : $gapps_options"${txtrst}

# ==================================== Starting =================================== #

# Export global variable for notifier.sh and upload.sh
export DEVICE=$device_name
export CODENAME=$device_codename
export ANDROID=$android_version
export UPLOAD_TYPE="ROM"
export ROM_NAME=$rom_name

# ============================== Download the Source ============================== #

# Function responsible for download ROM Repo if it's not found by the ROMREPO_DIR variable
function download_romrepo() {
    echo -e ${red}"ROM Repo hasn't been found in $ROMREPO_DIR."${txtrst}
    echo -e ${blu}"Downloading it...."${txtrst}
    rm -rf $ROMREPO_DIR
    mkdir -p $ROMREPO_DIR
    cd $ROMREPO_DIR
    repo init --depth=1 -u $rom_repo -b $rom_branch
    touch ./$rom_name-$android_version
}

# Function responsible for download Device Tree if it's not found by the DT_DIR variable
function download_dt() {
    echo -e ${red}"Device Tree hasn't been found in $DT_DIR."${txtrst}
    echo -e ${blu}"Downloading it...."${txtrst}
    git clone --depth=1 $dt_repo -b $dt_branch $DT_DIR
}

# Function responsible for download Vendor Tree if it's not found by the VT_DIR variable
function download_vt() {
    echo -e ${red}"Vendor Tree hasn't been found in $VT_DIR."${txtrst}
    echo -e ${blu}"Downloading it...."${txtrst}
    git clone --depth=1 $vt_repo -b $vt_branch $VT_DIR
}

# Function responsible for download Vendor Tree 2 if it's not found by the VT_DIR2 variable
function download_vt2() {
    echo -e ${red}"Vendor Tree hasn't been found in $VT_DIR2."${txtrst}
    echo -e ${blu}"Downloading it...."${txtrst}
    git clone --depth=1 $vt_repo -b $vt_branch $VT_DIR2
}

# Function responsible for download Kernel Source if it's not found by the KS_DIR variable
function download_ks() {
    echo -e ${red}"Kernel Source hasn't been found in $KS_DIR."${txtrst}
    echo -e ${blu}"Downloading it...."${txtrst}
    git clone --depth=1 $ks_repo -b $ks_branch $KS_DIR
}

# Download ROM Repo Source if not found
if [ ! -e $ROMREPO_DIR/$rom_name-$android_version ] ; then
    download_romrepo
fi

# Download Device Tree if not found
if [ ! -d $DT_DIR/.git ] ; then
    download_dt
fi

# Download Vendor Tree if not found
case  $vt_direct  in
    "no"|"No"|"NO")
        if [ ! -d $VT_DIR/.git ] ; then
            download_vt
        fi
        ;;
    "yes"|"Yes"|"YES")
        if [ ! -d $VT_DIR2/.git ] ; then
            download_vt2
        fi
        ;;
esac

# Download Kernel Source if not found
if [ ! -d $KS_DIR/.git ] ; then
    download_ks
fi

# =============================== Update the Source =============================== #

# Sync ROM Repo
echo -e ${cya}"Updating ROM Repo...."${txtrst}
cd $ROMREPO_DIR
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# Exit with error if Device Tree is not found
if [ ! -d $DT_DIR/.git ] ; then
    echo -e ${red}"Device Tree is not found!"${txtrst}
    echo -e ${red}"Aborting...."${txtrst}
    exit 1
fi

# Update Device Tree
echo -e ${cya}"Updating Device Tree...."${txtrst}
cd $DT_DIR
git fetch origin $dt_branch
git reset --hard origin/$dt_branch

# Exit with error if Vendor Tree is not found
case  $vt_direct  in
    "no"|"No"|"NO")
        if [ ! -d $VT_DIR/.git ] ; then
            echo -e ${red}"Vendor Tree is not found!"${txtrst}
            echo -e ${red}"Aborting...."${txtrst}
            exit 1
        fi
        ;;
    "yes"|"Yes"|"YES")
        if [ ! -d $VT_DIR2/.git ] ; then
            echo -e ${red}"Vendor Tree is not found!"${txtrst}
            echo -e ${red}"Aborting...."${txtrst}
            exit 1
        fi
        ;;
esac

# Update Vendor Tree
echo -e ${cya}"Updating Vendor Tree...."${txtrst}
case  $vt_direct  in
    "no"|"No"|"NO")
        cd $VT_DIR
        git fetch origin $vt_branch
        git reset --hard origin/$vt_branch
        ;;
    "yes"|"Yes"|"YES")
        cd $VT_DIR2
        git fetch origin $vt_branch
        git reset --hard origin/$vt_branch
        ;;
esac

# Exit with error Kernel Source is not found
if [ ! -d $KS_DIR/.git ] ; then
    echo -e ${red}"Kernel Source is not found!"${txtrst}
    echo -e ${red}"Aborting...."${txtrst}
    exit 1
fi

# Update Kernel Source
echo -e ${cya}"Updating Kernel Source...."${txtrst}
cd $KS_DIR
git fetch origin $ks_branch
git reset --hard origin/$ks_branch

# ================================= Build the ROM ================================= #

# Enter the ROMREPO_DIR directory
cd $ROMREPO_DIR
echo -e ${cya}"Building ROM...."${txtrst}

# GApps Options
case  $gapps_options  in
    "no"|"No"|"NO"|"false"|"False"|"FALSE")
        export WITH_GAPPS=false
        ;;
    "yes"|"Yes"|"YES"|"true"|"True"|"TRUE")
        export WITH_GAPPS=true
        ;;
esac

# CCache option
case  $ccache_clean  in
    "no"|"No"|"NO")
        ccache -M $CCACHE_SIZE
        ;;
    "yes"|"Yes"|"YES")
        ccache -C
        ccache -M $CCACHE_SIZE
        ;;
esac

# Set the build environment
source build/envsetup.sh

# Clean the build directory
mka clobber

# Choose the device and build type
lunch "$lunch_command"_"$device_codename"-"$build_type"

# Build the ROM
mka "$target_command" -j$(nproc --all)

# ================================ Copy the Package =============================== #

# Create the OUT_DIR if not found
if [ ! -d "$OUT_DIR"/"$device_codename"/"$rom_name" ] ; then
    mkdir -p "$OUT_DIR"/"$device_codename"/"$rom_name"
fi

# Copy the ROM package to the OUT_DIR
if [ -e "$PACKAGE_DIR"/*"$BUILD_DATE1"*.zip ] ; then
    rm -rf "$OUT_DIR"/"$device_codename"/"$rom_name"/*
    cp "$PACKAGE_DIR"/*"$BUILD_DATE1"*.zip "$OUT_DIR"/"$device_codename"/"$rom_name"

elif [ -e "$PACKAGE_DIR"/*"$BUILD_DATE2"*.zip ] ; then
    rm -rf "$OUT_DIR"/"$device_codename"/"$rom_name"/*
    cp "$PACKAGE_DIR"/*"$BUILD_DATE2"*.zip "$OUT_DIR"/"$device_codename"/"$rom_name"

# Exit with error if ROM package is not found
else
    echo -e ${red}"No ROM package generated. Looks like the build failed!"${txtrst}
    echo -e ${red}"Aborting...."${txtrst}
    exit 1
fi

# =============================== Upload the Package ============================== #

# Run the upload.sh script if there have been a zip file in OUT_DIR directory
if [ -e "$OUT_DIR"/"$device_codename"/"$rom_name"/*.zip ] ; then
    source $SCRIPT_DIR/upload.sh
    echo -e ${grn}"ROM package uploaded!"${txtrst}
else
    exit 1
fi

# =================================== Finishing =================================== #

# Return to script directory
cd $SCRIPT_DIRECTORY