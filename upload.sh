#!/bin/bash

# Directory variable
ROM_DIR="$HOME/android/out/rom"
KERNEL_DIR="$HOME/android/out/kernel"

# Upload script
case  $UPLOAD_TYPE  in
    "Kernel")
        ssh -q -o StrictHostKeyChecking=no -i ~/.ssh/jenkins1 -t genesis-project,genesis-$CODENAME@shell.sourceforge.net create
        ssh -q -o StrictHostKeyChecking=no -i ~/.ssh/jenkins1 -t genesis-project,genesis-$CODENAME@shell.sourceforge.net 'bash -c' "'
        cd /home/frs/project/genesis-$CODENAME/ROM/
        if [ ! -d ./$KERNEL_NAME ] ; then
            mkdir ./$KERNEL_NAME
        fi
        '"
        ssh -q -o StrictHostKeyChecking=no -i ~/.ssh/jenkins1 -t genesis-project,genesis-$CODENAME@shell.sourceforge.net shutdown
        rsync -avP -e "ssh -i ~/.ssh/jenkins1 -o StrictHostKeyChecking=no" "$KERNEL_DIR"/"$CODENAME"/"$KERNEL_NAME"/*.zip genesis-project@web.sourceforge.net:/home/frs/project/genesis-$CODENAME/Kernel/$KERNEL_NAME
        ;;
    "ROM")
        ssh -q -o StrictHostKeyChecking=no -i ~/.ssh/jenkins1 -t genesis-project,genesis-$CODENAME@shell.sourceforge.net create
        ssh -q -o StrictHostKeyChecking=no -i ~/.ssh/jenkins1 -t genesis-project,genesis-$CODENAME@shell.sourceforge.net 'bash -c' "'
        cd /home/frs/project/genesis-$CODENAME/ROM/
        if [ ! -d ./$ROM_NAME ] ; then
            mkdir ./$ROM_NAME
        fi
        '"
        ssh -q -o StrictHostKeyChecking=no -i ~/.ssh/jenkins1 -t genesis-project,genesis-$CODENAME@shell.sourceforge.net shutdown
        rsync -avP -e "ssh -i ~/.ssh/jenkins1 -o StrictHostKeyChecking=no" "$ROM_DIR"/"$CODENAME"/"$ROM_NAME"/*.zip genesis-project@web.sourceforge.net:/home/frs/project/genesis-$CODENAME/ROM/$ROM_NAME
        ;;
    *)
        exit 1
        ;;
esac