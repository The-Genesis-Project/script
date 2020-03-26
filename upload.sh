#!/bin/bash
#   SourceForge Uploader script
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