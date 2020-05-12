#!/bin/bash
#   Telegram Notifier script
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

# Directory variable
SCRIPT_DIR=$(dirname "$0")
HOME_DIR=$(dirname "$SCRIPT_DIR")
VAR_DIR="$HOME_DIR/var"

# Telegram token
TELEGRAM_TOKEN=$(cat $VAR_DIR/token/genesisproject_bot)

# Parameters
DEVICE=$(cat "$VAR_DIR"/device.0)
CODENAME=$(cat "$VAR_DIR"/device.1)
ANDROID=$(cat "$VAR_DIR"/android)
TYPE=$(cat "$VAR_DIR"/type)

# Time variable
case  $1  in
    "started")
        START=$(date +"%s")
        echo $START > "$VAR_DIR"/start
        ;;
    "success"|"failed"|"aborted")
        STOP=$(date +"%s")
        echo $STOP > "$VAR_DIR"/stop
        BUILD_START=$(cat "$VAR_DIR"/start)
        BUILD_STOP=$(cat "$VAR_DIR"/stop)
        TIME=$((BUILD_STOP - BUILD_START))
        ;;
esac

# Name variable
case  $TYPE  in
    "Kernel")
        KERNEL_NAME=$(cat "$VAR_DIR"/kernel.0)
        NAME=$KERNEL_NAME
        ;;
    "ROM")
        ROM_NAME=$(cat "$VAR_DIR"/rom.0)
        NAME=$ROM_NAME
        ;;
esac

# Function responsible for send the message to Genesis Project [CI] channel
function send {
    curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendmessage" --data "text=${*}&chat_id=-1001314659481&disable_web_page_preview=true&parse_mode=Markdown" > /dev/null
}

# Message template
case  $1  in
    "started")
        send "*Build started*%0A%0ADevice: *${DEVICE} (${CODENAME})*%0AAndroid: *${ANDROID}*%0AType: *${TYPE}*%0AName: *${NAME}*%0A%0A[${BUILD_URL}]()"
        ;;
    "success")
        send "*Build success*%0A%0ADevice: *${DEVICE} (${CODENAME})*%0AAndroid: *${ANDROID}*%0AType: *${TYPE}*%0AName: *${NAME}*%0A%0ADuration: *$((TIME / 3600))h $((TIME % 3600 / 60))m $((TIME % 60))s*%0A%0A[${BUILD_URL}]()"
        ;;
    "failed")
        send "*Build failed*%0A%0ADevice: *${DEVICE} (${CODENAME})*%0AAndroid: *${ANDROID}*%0AType: *${TYPE}*%0AName: *${NAME}*%0A%0ADuration: *$((TIME / 3600))h $((TIME % 3600 / 60))m $((TIME % 60))s*%0A%0A[${BUILD_URL}]()"
        ;;
    "aborted")
        send "*Build aborted*%0A%0ADevice: *${DEVICE} (${CODENAME})*%0AAndroid: *${ANDROID}*%0AType: *${TYPE}*%0AName: *${NAME}*%0A%0ADuration: *$((TIME / 3600))h $((TIME % 3600 / 60))m $((TIME % 60))s*%0A%0A[${BUILD_URL}]()"
        ;;
    *)
        exit 1
        ;;
esac