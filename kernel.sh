#!/bin/bash

# Colors makes things beautiful
export TERM=xterm
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
blu=$(tput setaf 4)             #  blue
cya=$(tput setaf 6)             #  cyan
txtrst=$(tput sgr0)             #  Reset

echo -e ${blu}"====================================="${txtrst}
echo -e ${blu}"       Unified Kernel Compiler       "${txtrst}
echo -e ${blu}"====================================="${txtrst}

# Kernel architecture
export ARCH=arm64
export SUBARCH=arm64

# CCache settings
export USE_CCACHE=1
CCACHE_SIZE="5G"

# Directory variable
SCRIPT_DIR="$HOME/android/script"
TOOLCHAIN_DIR="$HOME/android/toolchain"
KERNEL_DIR="$HOME/android/rom/kernel/xiaomi/msm8917"
ANYKERNEL_DIR="$HOME/android/anykernel3"
OUT_DIR="$HOME/android/out/kernel"
export CROSS_COMPILE="$HOME/android/toolchain/bin/aarch64-elf-"

# Build variable input
DEVICE="Riva"
TOOLCHAIN="GCC920"
VERSION=$a
DATE=$(date +"%Y%m%d")

# Write the information to console
echo -e ${grn}"Device          : Redmi 5A (riva)"${txtrst}
echo -e ${grn}"Android Version : 10"${txtrst}
echo -e ${grn}"Package Version : $VERSION"${txtrst}

# ============================== Download the Source ============================== #

# Function responsible for download Kernel Source if it's not found by the KERNEL_DIR variable
function download_kernelsource() {
    echo -e ${red}"Kernel Source hasn't been found in $KERNEL_DIR."${txtrst}
    echo -e ${blu}"Downloading it...."${txtrst}
    git clone --depth=1 https://github.com/rulim34/kernel_xiaomi_msm8917.git -b lineage-17.1 $KERNEL_DIR
}

# Function responsible for download Toolchain if it's not found by the TOOLCHAIN_DIR variable
function download_toolchain() {
    echo -e ${red}"Toolchain hasn't been found in $TOOLCHAIN_DIR."${txtrst}
    echo -e ${blu}"Downloading it...."${txtrst}
    git clone --depth=1 https://github.com/rulim34/arm64-gcc.git -b master $TOOLCHAIN_DIR
}

# Function responsible for download AnyKernel3 if it's not found by the ANYKERNEL_DIR variable
function download_anykernel() {
    echo -e ${red}"AnyKernel3 hasn't been found in $ANYKERNEL_DIR."${txtrst}
    echo -e ${blu}"Downloading it...."${txtrst}
    git clone --depth=1 https://github.com/rulim34/anykernel3.git -b ardadedali $ANYKERNEL_DIR
}

# Download Kernel Source if not found
if [ ! -d $KERNEL_DIR/.git ] ; then
    download_kernelsource
fi

# Download Toolchain if not found
if [ ! -d $TOOLCHAIN_DIR/.git ] ; then
    download_toolchain
fi

# Download AnyKernel3 if not found
if [ ! -d $ANYKERNEL_DIR/.git ] ; then
    download_anykernel
fi

# =============================== Update the Source =============================== #

# Update all needed repositories
echo -e ${cya}"Updating Kernel Source...."${txtrst}
cd $KERNEL_DIR
git fetch origin lineage-17.1
git reset --hard origin/lineage-17.1

echo -e ${cya}"Updating Toolchain...."${txtrst}
cd $TOOLCHAIN_DIR
git fetch origin master
git reset --hard origin/master

echo -e ${cya}"Updating AnyKernel3...."${txtrst}
cd $ANYKERNEL_DIR
git fetch origin ardadedali
git reset --hard origin/ardadedali

# =============================== Build the Kernel ================================ #

# Set the packaging information
kernelzip="Ardadedali_Plus-$VERSION-$TOOLCHAIN-$DEVICE-$DATE.zip"

# Build the kernel
echo -e ${cya}"Compiling kernel...."${txtrst}
cd $KERNEL_DIR
ccache -M $CCACHE_SIZE
mkdir -p out
make O=out clean
make O=out mrproper
make O=out riva-pe_defconfig
make O=out -j$(nproc --all)

# ================================ Copy the Kernel ================================ #

# Clean the $ANYKERNEL_DIR if there have been a zip file before
if [ -e $ANYKERNEL_DIR/*.zip ] ; then
    rm -rf $ANYKERNEL_DIR/*.zip
fi

# Clean the $ANYKERNEL_DIR if there have been a zImage file before
if [ -e $ANYKERNEL_DIR/zImage ] ; then
    rm -rf $ANYKERNEL_DIR/zImage
fi

# Move the kernel Image.gz-dtb to the AnyKernel3 folder if we confirm that a Image.gz-dtb is present.
if [ -e $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb ] ; then
    mv $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb $ANYKERNEL_DIR/zImage

# =============================== Build the Package =============================== #

# Make the flashable kernel package.
    cd $ANYKERNEL_DIR
    zip -r9 $kernelzip * -x .git README.md *placeholder

# Create the OUT_DIR if not found
    if [ ! -d $OUT_DIR ] ; then
        mkdir -p $OUT_DIR
    fi

# Copy the Kernel package to the OUT_DIR
    cp $kernelzip $OUT_DIR
    echo -e ${grn}"Kernel package generated at $OUT_DIR/$kernelzip"${txtrst}
fi

# =============================== Upload the Package ============================== #

# Run the upload.sh script if there have been a zip file in OUT_DIR
if [ -e $OUT_DIR/$kernelzip ] ; then
    export TYPE=Kernel
    source $SCRIPT_DIR/upload.sh
    echo -e ${grn}"Kernel package uploaded!"${txtrst}
else
    exit 1
fi

# =================================== Finishing =================================== #

# Return to script DIR
cd $SCRIPT_DIR