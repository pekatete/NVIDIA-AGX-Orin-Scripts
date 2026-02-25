#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

NVME_DRIVE="$1"
MOUNT_POINT="/mnt/ssd"

if [ -z "$NVME_DRIVE" ] || [ ! -e "$NVME_DRIVE" ]; then
    echo "Usage: $0 <SSD device path> (e.g., /dev/nvme0n1p1)"
    exit 1
fi

# Get the UUID of the target NVMe drive
TARGET_UUID=$(blkid -s UUID -o value "$NVME_DRIVE")
if [ -z "$TARGET_UUID" ]; then
    echo "Error: Could not find UUID for $NVME_DRIVE"
    exit 1
fi

mkdir -p "$MOUNT_POINT"
mount "$NVME_DRIVE" "$MOUNT_POINT"

echo "Copying root filesystem to SSD (UUID: $TARGET_UUID)..."
rsync -axHAWX --numeric-ids --info=progress2 \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / "$MOUNT_POINT"

sync

# Update extlinux.conf using the UUID
EXTLINUX_CONF="/boot/extlinux/extlinux.conf"
SSD_EXTLINUX_CONF="$MOUNT_POINT/boot/extlinux/extlinux.conf"

echo "Updating extlinux.conf with UUID..."
# This replaces whatever root= value existed with the new UUID format
sed -i "s|root=[^ ]*|root=UUID=$TARGET_UUID|g" "$EXTLINUX_CONF"

# Copy updated config to the SSD partition
cp "$EXTLINUX_CONF" "$SSD_EXTLINUX_CONF"

umount "$MOUNT_POINT"
echo "Migration completed. Target UUID: $TARGET_UUID. Reboot to apply."
