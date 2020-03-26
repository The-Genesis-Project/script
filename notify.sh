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

# Telegram token
TELEGRAM_TOKEN=$(cat $HOME/temp/token/genesisproject_bot)

# Time variable
TIME=$((BUILD_END - BUILD_START))

# Name variable
case  $UPLOAD_TYPE  in
    "Kernel")
        NAME=$KERNEL_NAME
        ;;
    "ROM")
        NAME=$ROM_NAME
        ;;
esac

# Function responsible for send the message to Genesis Project [CI] channel
function sendCI() {
    curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendmessage" --data "text=${*}&chat_id=-1001314659481&disable_web_page_preview=true&parse_mode=Markdown" > /dev/null
}

# Message template
case  $1  in
    "started")
        sendCI "*Build started*%0A%0ADevice: *${DEVICE} (${CODENAME})*%0AAndroid: *${ANDROID}*%0AType: *${UPLOAD_TYPE}*%0AName: *${NAME}*%0A%0A[${BUILD_URL}]()"
        ;;
    "success")
        sendCI "*Build success*%0A%0ADevice: *${DEVICE} (${CODENAME})*%0AAndroid: *${ANDROID}*%0AType: *${UPLOAD_TYPE}*%0AName: *${NAME}*%0A%0ADuration: *$((TIME / 3600))h $((TIME % 3600 / 60))m $((TIME % 60))s*%0A%0A[${BUILD_URL}]()"
        ;;
    "failed")
        sendCI "*Build failed*%0A%0ADevice: *${DEVICE} (${CODENAME})*%0AAndroid: *${ANDROID}*%0AType: *${UPLOAD_TYPE}*%0AName: *${NAME}*%0A%0ADuration: *$((TIME / 3600))h $((TIME % 3600 / 60))m $((TIME % 60))s*%0A%0A[${BUILD_URL}]()"
        ;;
    "aborted")
        DEVICE=$(cat $HOME/android/script/DEVICE)
        CODENAME=$(cat $HOME/android/script/CODENAME)
        ANDROID=$(cat $HOME/android/script/ANDROID)
        UPLOAD_TYPE=$(cat $HOME/android/script/UPLOAD_TYPE)
        NAME=$(cat $HOME/android/script/NAME)
        BUILD_START=$(cat $HOME/android/script/BUILD_START)
        BUILD_END=$(date +"%s")
        TIME=$((BUILD_END - BUILD_START))
        sendCI "*Build aborted*%0A%0ADevice: *${DEVICE} (${CODENAME})*%0AAndroid: *${ANDROID}*%0AType: *${UPLOAD_TYPE}*%0AName: *${NAME}*%0A%0ADuration: *$((TIME / 3600))h $((TIME % 3600 / 60))m $((TIME % 60))s*%0A%0A[${BUILD_URL}]()"
        ;;
esac