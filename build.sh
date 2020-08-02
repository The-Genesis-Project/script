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
PACKAGE_DIR="$ROMREPO_DIR/out/target/product/$DEVICE_CODENAME"
OUT_DIR="$HOME_DIR/out"

# CCache settings
export USE_CCACHE=1
export CCACHE_DIR="$HOME_DIR/.ccache/rom"
export CCACHE_COMPRESS=true
CCACHE_SIZE="120G"

# Build date
BUILD_DATE1=$(date +"%Y%m%d")
BUILD_DATE2=$(date +"%d%m%Y")


function build_started() {
    bash $SCRIPT_DIR/notify.sh started
}


function build_success() {
    bash $SCRIPT_DIR/notify.sh success
}


function load_parameter {
    if [ ! -d $VAR_DIR ] ; then
        mkdir -p $VAR_DIR
    fi
    python3 -u $SCRIPT_DIR/loader.py
}


function download_rom_repo {
    if [ -e $ROMREPO_DIR/$ROM_NAME-$ANDROID_VERSION ] ; then
        cd $ROMREPO_DIR
        echo -e ${green}"Syncing ROM repository."${txtrst}
        repo sync -c -j12 --force-sync --no-clone-bundle --no-tags
    else
        rm -rf $ROMREPO_DIR
        mkdir -p $ROMREPO_DIR
        cd $ROMREPO_DIR
        echo -e ${green}"Initialising ROM repository."${txtrst}
        repo init --depth=1 -u $ROM_REPO -b $ROM_BRANCH
        echo -e ${green}"Syncing ROM repository."${txtrst}
        repo sync -c -j12 --force-sync --no-clone-bundle --no-tags
        touch ./$ROM_NAME-$ANDROID_VERSION
    fi
}


function download_device_repo {
    if [[ $ANDROID_VERSION == "8" ]] ; then
        export ROOMSERVICE_DEFAULT_BRANCH="oreo"
    elif [[ $ANDROID_VERSION == "9" ]] ; then
        export ROOMSERVICE_DEFAULT_BRANCH="pie"
    elif [[ $ANDROID_VERSION == "10" ]] ; then
        export ROOMSERVICE_DEFAULT_BRANCH="ten"
    fi

    cd $ROMREPO_DIR
    python3 -u $SCRIPT_DIR/roomservice.py $DEVICE_MANUFACTURER $DEVICE_CODENAME
    rm -rf $ROMREPO_DIR/.repo/local_manifests
}


function set_ccache {
    case  $CLEAN_CCACHE  in
        "no"|"No"|"NO")
            ccache -M $CCACHE_SIZE
            ;;
        "yes"|"Yes"|"YES")
            ccache -C
            ccache -M $CCACHE_SIZE
            ;;
    esac
}


function set_gapps {
    case  $GAPPS_OPTION  in
        "no"|"No"|"NO"|"false"|"False"|"FALSE")
            export WITH_GAPPS=false
            ;;
        "yes"|"Yes"|"YES"|"true"|"True"|"TRUE")
            export WITH_GAPPS=true
            ;;
    esac
}


function clean_dir {
    case  $CLEAN_BUILD  in
        "no"|"No"|"NO")
            # Do nothing
            ;;
        "yes"|"Yes"|"YES")
            cd $ROMREPO_DIR
            source build/envsetup.sh
            mka clobber
            ;;
    esac
}


function build_rom {
    cd $ROMREPO_DIR
    source build/envsetup.sh
    lunch "$LUNCH_COMMAND"_"$DEVICE_CODENAME"-"$BUILD_TYPE"
    mka "$TARGET_COMMAND" -j$(nproc --all)
}


function copy_rom {
    if [ ! -d "$OUT_DIR"/rom/"$DEVICE_CODENAME"/"$ROM_NAME" ] ; then
        mkdir -p "$OUT_DIR"/rom/"$DEVICE_CODENAME"/"$ROM_NAME"
    fi

    if [ -e "$PACKAGE_DIR"/*"$BUILD_DATE1"*.zip ] ; then
        rm -rf "$OUT_DIR"/rom/"$DEVICE_CODENAME"/"$ROM_NAME"/*
        mv "$PACKAGE_DIR"/*"$BUILD_DATE1"*.zip "$OUT_DIR"/rom/"$DEVICE_CODENAME"/"$ROM_NAME"
    elif [ -e "$PACKAGE_DIR"/*"$BUILD_DATE2"*.zip ] ; then
        rm -rf "$OUT_DIR"/rom/"$DEVICE_CODENAME"/"$ROM_NAME"/*
        mv "$PACKAGE_DIR"/*"$BUILD_DATE2"*.zip "$OUT_DIR"/rom/"$DEVICE_CODENAME"/"$ROM_NAME"
    else
        echo -e ${red}"Build failed. No ROM package generated!"${txtrst}
        exit 1
    fi
}


function upload_rom {
    if [ -e "$OUT_DIR"/rom/"$DEVICE_CODENAME"/"$ROM_NAME"/*.zip ] ; then
        bash $SCRIPT_DIR/upload.sh
        echo -e ${green}"ROM package uploaded!"${txtrst}
    else
        echo -e ${red}"ROM package failed to upload!"${txtrst}
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

    DEVICE_NAME=$(cat "$VAR_DIR"/device.0)
    DEVICE_CODENAME=$(cat "$VAR_DIR"/device.1)
    DEVICE_MANUFACTURER=$(cat "$VAR_DIR"/device.2)
    ROM_NAME=$(cat "$VAR_DIR"/rom.0)
    TARGET_COMMAND=$(cat "$VAR_DIR"/rom.1)
    LUNCH_COMMAND=$(cat "$VAR_DIR"/rom.2)
    ROM_REPO=$(cat "$VAR_DIR"/rom.3)
    ROM_BRANCH=$(cat "$VAR_DIR"/rom.4)

    download_rom_repo
    download_device_repo
    set_ccache
    set_gapps
    clean_dir
    build_rom
    copy_rom
    upload_rom
    build_success
}


main_rom