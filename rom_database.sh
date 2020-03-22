#!/bin/bash
#   Android ROM Database Injector script
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

# Android 10 ROM Database
if [ "$f" == "10" ] ; then
    export ff=$f # ANDROID VERSION, default parameters is {10}
    case  $a  in
        "aex")
            export aa=AospExtended
            export cc=bacon
            export dd=aosp
            export gg=https://github.com/AospExtended/manifest.git
            export hh=10.x
            ;;
        "aosip")
            export aa=AOSiP
            export cc=kronic
            export dd=aosip
            export gg=https://github.com/AOSiP/platform_manifest.git
            export hh=ten
            ;;
        "crdroid")
            export aa=crDroid
            export cc=bacon
            export dd=lineage
            export gg=https://github.com/crdroidandroid/android.git
            export hh=10.0
            ;;
        "havoc")
            export aa=Havoc-OS
            export cc=bacon
            export dd=havoc
            export gg=https://github.com/Havoc-OS/android_manifest.git
            export hh=ten
            ;;
        "arrow")
            export aa=ArrowOS
            export cc=bacon
            export dd=arrow
            export gg=https://github.com/ArrowOS/android_manifest.git
            export hh=arrow-10.0
            ;;
        "msm-xtended")
            export aa=MSM-Xtended
            export cc=xtended
            export dd=xtended
            export gg=https://github.com/Project-Xtended/manifest.git
            export hh=xq
            ;;
        "evolution-x")
            export aa=Evolution-X
            export cc=bacon
            export dd=aosp
            export gg=https://github.com/Evolution-X/manifest.git
            export hh=ten
            ;;
        "bootleggers")
            export aa=Bootleggers
            export cc=bacon
            export dd=bootleg
            export gg=https://github.com/BootleggersROM/manifest.git
            export hh=queso
            ;;
        "pixelexperience")
            export aa=PixelExperience
            export cc=bacon
            export dd=aosp
            export gg=https://github.com/PixelExperience/manifest.git
            export hh=ten
            ;;
        "derpfest")
            export aa=DerpFest
            export cc=kronic
            export dd=derp
            export gg=https://github.com/DerpLab/platform_manifest.git
            export hh=ten
            ;;
        "corvus")
            export aa=Corvus
            export cc=corvus
            export dd=du
            export gg=https://github.com/Corvus-ROM/android_manifest.git
            export hh=10
            ;;
        "aospa")
            export aa=AOSPA
            export cc=bacon
            export dd=pa
            export gg=https://github.com/AOSPA/manifest.git
            export hh=quartz
            ;;
        "aosap")
            export aa=AOSAP
            export cc=bacon
            export dd=aosap
            export gg=https://github.com/AOSAP/platform_manifest.git
            export hh=ten
            ;;
        "cygnus")
            export aa=Cygnus
            export cc=cygnus
            export dd=cygnus
            export gg=https://github.com/cygnus-rom/manifest.git
            export hh=caf-ten
            ;;
        "candy")
            export aa=Candy
            export cc=candy
            export dd=candy
            export gg=https://github.com/CandyROMs/candy.git
            export hh=c10
            ;;
        "nitrogen")
            export aa=Nitrogen-OS
            export cc=otapackage
            export dd=nitrogen
            export gg=https://github.com/nitrogen-project/android_manifest.git
            export hh=10
            ;;
        "lineage")
            export aa=LineageOS
            export cc=bacon
            export dd=lineage
            export gg=https://github.com/LineageOS/android.git
            export hh=lineage-17.1
            ;;
        "wave")
            export aa=WaveOS
            export cc=bacon
            export dd=wave
            export gg=https://github.com/Wave-Project/manifest.git
            export hh=q
            ;;
        "baikal")
            export aa=BaikalOS
            export cc=baikalos
            export dd=baikalos
            export gg=https://github.com/baikalos/manifest.git
            export hh=q10.0
            ;;
        "aicp")
            export aa=AICP
            export cc=bacon
            export dd=aicp
            export gg=https://github.com/AICP/platform_manifest.git
            export hh=q10.0
            ;;
        *)
            export aa=$a # ROM NAME, ie. PixelExperience, AOSiP, etc
            export cc=$c # TARGET COMMAND, ie. bacon, kronic {mka "target_command" -j$(nproc --all)}
            export dd=$d # LUNCH COMMAND, ie. aosp, aosip {"$lunch_command"_"device_codename"}
            export gg=$g # ROM REPO, ie. https://github.com/PixelExperience/manifest
            export hh=$h # ROM BRANCH ie. ten, pie (Branch of the ROM REPO)
            ;;
    esac
fi

# Build variable
export bb=$b # GAPPS OPTIONS, default parameters is {FALSE}
export ee=$e # BUILD TYPE, default parameters is {userdebug}
export ii=$i # VT DIRECT, default parameters is {NO}
export jj=$j # DT REPO
export kk=$k # DT BRACH
export ll=$l # VT REPO
export mm=$m # VT BRANCH
export nn=$n # KS REPO
export oo=$o # KS BRANCH
export pp=$p # CCACHE CLEAN OPTIONS, default parameters is {NO}

# Exit with error if repo paramaters is empty
if [ "$j" == "" ] || [ "$k" == "" ] || [ "$l" == "" ] || [ "$m" == "" ] || [ "$n" == "" ] || [ "$o" == "" ] ; then
    echo -e ${red}"Repo parameters is empty!"${txtrst}
    echo -e ${red}"Aborting...."${txtrst}
    exit 1
fi
