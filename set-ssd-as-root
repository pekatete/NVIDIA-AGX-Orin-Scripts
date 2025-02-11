#!/bin/bash

# Ensure the script is run as root
if [ "$(whoami)" != "root" ]; then
    echo "Please run as root."
    exit 1
fi

# Define variables
NVME_DRIVE="$1"
MOUNT_POINT="/mnt/ssd"

# Check if SSD device argument is provided
if [ -z "$NVME_DRIVE" ]; then
    echo "Usage: $0 <SSD device path> (e.g., /dev/nvme0n1p1)"
    exit 1
fi

# Check if the SSD exists
if [ ! -e "$NVME_DRIVE" ]; then
    echo "Error: SSD device $NVME_DRIVE not found!"
    exit 1
fi

# Ensure the SSD is not mounted
if mount | grep -q "$NVME_DRIVE"; then
    echo "Error: SSD is already mounted. Please unmount it first."
    exit 1
fi

# Create mount point if not exists
mkdir -p "$MOUNT_POINT"

# Mount the SSD
sudo mount "$NVME_DRIVE" "$MOUNT_POINT"

# Copy the root filesystem from eMMC to SSD
echo "Copying root filesystem to SSD..."
sudo rsync -axHAWX --numeric-ids --info=progress2 \
    --exclude={"/dev/","/proc/","/sys/","/tmp/","/run/","/mnt/","/media/*","/lost+found"} / "$MOUNT_POINT"

# Ensure all data is written to the SSD
sync
echo "Root filesystem successfully copied to SSD."

# Update bootloader (extlinux.conf) to boot from SSD
EXTLINUX_CONF="/boot/extlinux/extlinux.conf"
SSD_EXTLINUX_CONF="$MOUNT_POINT/boot/extlinux/extlinux.conf"

echo "Updating extlinux.conf to boot from SSD..."
ROOT_DRIVE=$(df / | tail -1 | awk '{print $1}')
sed -i "s|root=$ROOT_DRIVE|root=$NVME_DRIVE|g" "$EXTLINUX_CONF"

# Copy the updated config to the SSD
sudo cp "$EXTLINUX_CONF" "$SSD_EXTLINUX_CONF"

echo "extlinux.conf updated:"
grep "root=" "$EXTLINUX_CONF"

# Unmount the SSD (optional, as reboot will remount it)
sudo umount "$MOUNT_POINT"

echo "Migration completed. Reboot your system for changes to take effect."
