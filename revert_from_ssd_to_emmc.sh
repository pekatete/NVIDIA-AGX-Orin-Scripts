#!/bin/bash

# Ensure script is run as root
if [ "$(whoami)" != "root" ]; then
    echo "Please run as root"
    exit 1
fi

# Define the eMMC root partition
EMMC_DRIVE="/dev/mmcblk0p1"
MOUNT_POINT="/mnt/emmc"

# Get the current root partition
CURRENT_ROOT=$(df '/' | tail -1 | awk '{print $1}')

# Ensure we are running from SSD
if [[ "$CURRENT_ROOT" != /dev/nvme* ]]; then
    echo "Already booting from eMMC. No changes needed."
    exit 0
fi

echo "Current root is on SSD ($CURRENT_ROOT). Switching back to eMMC ($EMMC_DRIVE)..."

# Check if eMMC partition exists
if [ ! -e "$EMMC_DRIVE" ]; then
    echo "eMMC partition not found! Exiting..."
    exit 1
fi

# Ensure eMMC is not mounted
if mount | grep -q "$EMMC_DRIVE"; then
    echo "eMMC is already mounted. Please unmount it first."
    exit 1
fi

# Create mount point if not exists
mkdir -p "$MOUNT_POINT"

# Mount the eMMC partition
sudo mount "$EMMC_DRIVE" "$MOUNT_POINT"

# Copy the root filesystem back to eMMC
echo "Copying root filesystem from SSD to eMMC..."
sudo rsync -axHAWX --numeric-ids --info=progress2 --exclude={"/dev/","/proc/","/sys/","/tmp/","/run/","/mnt/","/media/*","/lost+found"} / "$MOUNT_POINT"

# Ensure all data is written
sync
echo "Root filesystem copied back to eMMC."

# Modify extlinux.conf to boot from eMMC
echo -n "Before extlinux.conf change: "
cat /boot/extlinux/extlinux.conf | grep "root="

# Update bootloader configuration
sudo sed -i 's|root=/dev/nvme[^ ]*|root='"$EMMC_DRIVE"'|g' /boot/extlinux/extlinux.conf

# Copy updated config to eMMC boot partition
sudo cp /boot/extlinux/extlinux.conf "$MOUNT_POINT/boot/extlinux/extlinux.conf"

echo -n "After extlinux.conf change: "
cat /boot/extlinux/extlinux.conf | grep "root="

# Cleanup
sudo umount "$MOUNT_POINT"
rm -rf "$MOUNT_POINT"

echo "Reverted to eMMC boot. Reboot for changes to take effect."
