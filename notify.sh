#!/bin/bash

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
esac