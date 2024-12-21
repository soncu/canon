#!/bin/bash

# Catch errors and return early
set -e

# Basic Variables
WORKING_DIR=$(pwd)
IMAGE_SIZE_MB=64
FILESYSTEM_IMG="$WORKING_DIR/rootfs.img"
INITRD_IMG="$WORKING_DIR/initrd.img"
MOUNT_DIR="$WORKING_DIR/local_mnt"
KERNEL_FILE="$WORKING_DIR/bzImage"
INIT_EXECUTABLE="$WORKING_DIR/init"


# necessary packages for the environment
# Uncomment the following if needed
#
#echo "Installing required packages..."
#sudo apt-get update
#sudo apt-get install -y build-essential libncurses-dev bison flex libssl-dev libelf-dev
#sudo apt-get install -y qemu qemu-system qemu-utils busybox

# Step 1: Create root file system
echo "Creating root file system ..."
dd if=/dev/zero of=$FILESYSTEM_IMG bs=1M count=$IMAGE_SIZE_MB
mkfs.ext4 -q $FILESYSTEM_IMG

# Step 2: Mount the image to local folder (local_mnt)
echo "Mounting the file system ..."
mkdir -p $MOUNT_DIR
sudo mount -o loop $FILESYSTEM_IMG $MOUNT_DIR

# Step 3: Populate the filesystem with BusyBox (using host busybox package)
# This step is optional since I add init as a binary executable
echo "Populating filesystem with BusyBox ..."
sudo mkdir -p $MOUNT_DIR/{bin,sbin,etc,proc,sys,usr}
sudo cp -r $(which busybox) $MOUNT_DIR/bin/
sudo $MOUNT_DIR/bin/busybox --install -s $MOUNT_DIR/bin

# Step 4: Populate the filesystem with init executable (see init.c)
echo "Populating filesystem with init ..."
sudo cp $INIT_EXECUTABLE $MOUNT_DIR/init
sudo chmod +x $MOUNT_DIR/init

# Step 5: Create initrd image for qemu boot
echo "Creating Initial RAM disk ..."
(cd $MOUNT_DIR && find . -path ./lost+found -prune -o -print | cpio -o -H newc | gzip > $INITRD_IMG)

# Step 6: Unmount and remote file system image
echo "Cleaning the file system ..."
sudo umount $MOUNT_DIR
rm -rf $MOUNT_DIR
rm -f $FILESYSTEM_IMG

# Step 7.1: Use current Linux Kernel
sudo cp /boot/vmlinuz-$(uname -r) $KERNEL_FILE
sudo chmod 664 $KERNEL_FILE


# ALTERNATIVE: Step 7.2: Build the latest Linux kernel from source (takes time)
# Uncomment the following if needed
#
#if [ ! -f $KERNEL_FILE ]; then
#    echo "Downloading and building Linux kernel..."
#    mkdir -p $KERNEL_SOURCE_DIR
#    wget -qO- https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.6.tar.xz | tar -xJ -C $KERNEL_SOURCE_DIR --strip-components=1
#    cd $KERNEL_SOURCE_DIR
#    make defconfig > /dev/null
#    make -j$(nproc) bzImage > /dev/null
#    cp arch/x86/boot/bzImage $KERNEL_FILE
#    cd $WORK_DIR
#    rm -rf $KERNEL_SOURCE_DIR
#fi


# Step 8: Run the Hello World Linux image with QEMU
echo "Running the image with QEMU ..."
qemu-system-x86_64 -kernel $KERNEL_FILE -initrd $INITRD_IMG -append "console=ttyS0 root=/dev/ram rw init=/init noapic" -nographic -m 256M

# Quit QEMU with CTRL+a then x

