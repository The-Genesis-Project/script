#!/bin/bash
#   Unified ROM Compiler script
#   Copyright (C) 2020  Genesis Project
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Colors makes things beautiful
export TERM=xterm
red=$(tput setaf 1)             #  red
green=$(tput setaf 2)           #  green
blue=$(tput setaf 4)            #  blue
cyan=$(tput setaf 6)            #  cyan
txtrst=$(tput sgr0)             #  reset

# Directory variable
SCRIPT_DIR=$(dirname "$0")
HOME_DIR=$(dirname "$SCRIPT_DIR")
VAR_DIR="$HOME_DIR/var"
ROMREPO_DIR="$HOME_DIR/rom"
PACKAGE_DIR="$ROMREPO_DIR/out/target/product/$device_codename"
OUT_DIR="$HOME_DIR/out/rom/$device_codename/$rom_name"

# CCache settings
export USE_CCACHE=1
export CCACHE_DIR="$HOME_DIR/.ccache/rom"
export CCACHE_COMPRESS=true
CCACHE_SIZE="120G"

# Build date
BUILD_DATE1=$(date +"%Y%m%d")
BUILD_DATE2=$(date +"%d%m%Y")

# Input parameter
device_name=$DEVICE_NAME
android_version=$ANDROID_VERSION
rom_name=$ROM_NAME
dt_repo=$DT_REPO
dt_branch=$DT_BRANCH
build_type=$BUILD_TYPE
gapps_option=$GAPPS_OPTION
ccache_clean=$CCACHE_CLEAN


function build_started() {
    bash $SCRIPT_DIR/notify.sh started
}


function build_success() {
    bash $SCRIPT_DIR/notify.sh success
}


function build_failed() {
    bash $SCRIPT_DIR/notify.sh failed
}


function load_parameter {
    if [ ! -d $VAR_DIR ] ; then
        mkdir -p $VAR_DIR
    fi
    python3 -u $SCRIPT_DIR/loader.py
}


function download_rom_repo {
    if [ -e $ROMREPO_DIR/$rom_name-$android_version ] ; then
        cd $ROMREPO_DIR
        echo -e ${green}"Syncing ROM repository."${txtrst}
        repo sync -c -j12 --force-sync --no-clone-bundle --no-tags
    else
        rm -rf $ROMREPO_DIR
        mkdir -p $ROMREPO_DIR
        cd $ROMREPO_DIR
        echo -e ${green}"Initialising ROM repository."${txtrst}
        repo init --depth=1 -u $rom_repo -b $rom_branch
        echo -e ${green}"Syncing ROM repository."${txtrst}
        repo sync -c -j12 --force-sync --no-clone-bundle --no-tags
        touch ./$rom_name-$android_version
    fi
}


function download_device_repo {
    if [ $android_version == "8" ] ; then
        export ROOMSERVICE_DEFAULT_BRANCH="oreo"
    elif [ $android_version == "9" ] ; then
        export ROOMSERVICE_DEFAULT_BRANCH="pie"
    elif [ $android_version == "10" ] ; then
        export ROOMSERVICE_DEFAULT_BRANCH="ten"
    fi

    cd $ROMREPO_DIR
    python3 -u $SCRIPT_DIR/roomservice.py $device_manufacturer $device_codename
    rm -rf $ROMREPO_DIR/.repo/local_manifests
}


function gapps {
    case  $gapps_options  in
        "no"|"No"|"NO"|"false"|"False"|"FALSE")
            export WITH_GAPPS=false
            ;;
        "yes"|"Yes"|"YES"|"true"|"True"|"TRUE")
            export WITH_GAPPS=true
            ;;
    esac
}


function ccache {
    case  $ccache_clean  in
        "no"|"No"|"NO")
            ccache -M $CCACHE_SIZE
            ;;
        "yes"|"Yes"|"YES")
            ccache -C
            ccache -M $CCACHE_SIZE
            ;;
    esac
}


function build_rom {
    cd $ROMREPO_DIR
    source build/envsetup.sh
    mka clobber
    lunch "$lunch_command"_"$device_codename"-"$build_type"
    mka "$target_command" -j$(nproc --all)
}


function copy_rom {
    if [ ! -d "$OUT_DIR"/"$device_codename"/"$rom_name" ] ; then
        mkdir -p "$OUT_DIR"/"$device_codename"/"$rom_name"
    fi

    if [ -e "$PACKAGE_DIR"/*"$BUILD_DATE1"*.zip ] ; then
        rm -rf "$OUT_DIR"/"$device_codename"/"$rom_name"/*
        cp "$PACKAGE_DIR"/*"$BUILD_DATE1"*.zip "$OUT_DIR"/"$device_codename"/"$rom_name"
    elif [ -e "$PACKAGE_DIR"/*"$BUILD_DATE2"*.zip ] ; then
        rm -rf "$OUT_DIR"/"$device_codename"/"$rom_name"/*
        cp "$PACKAGE_DIR"/*"$BUILD_DATE2"*.zip "$OUT_DIR"/"$device_codename"/"$rom_name"
    else
        echo -e ${red}"Build failed. No ROM package generated!"${txtrst}
        build_failed
        exit 1
    fi
}


function upload_rom {
    if [ -e "$OUT_DIR"/"$device_codename"/"$rom_name"/*.zip ] ; then
        bash $SCRIPT_DIR/upload.sh
        echo -e ${green}"ROM package uploaded!"${txtrst}
    else
        echo -e ${red}"ROM package failed to upload!"${txtrst}
        build_failed
        exit 1
    fi
}


function main_rom {
    echo -e ${green}"=============================="${txtrst}
    echo -e ${green}"     Unified ROM Compiler     "${txtrst}
    echo -e ${green}"=============================="${txtrst}

    echo "ROM" > "$VAR_DIR"/type
    load_parameter
    build_started

    device_name=$(cat "$VAR_DIR"/device.0)
    device_codename=$(cat "$VAR_DIR"/device.1)
    device_manufacturer=$(cat "$VAR_DIR"/device.2)
    rom_name=$(cat "$VAR_DIR"/rom.0)
    target_command=$(cat "$VAR_DIR"/rom.1)
    lunch_command=$(cat "$VAR_DIR"/rom.2)
    rom_repo=$(cat "$VAR_DIR"/rom.3)
    rom_branch=$(cat "$VAR_DIR"/rom.4)

    download_rom_repo
    download_device_repo
    ccache
    gapps
    build_rom
    copy_rom
    upload_rom
    build_success
}


main_rom