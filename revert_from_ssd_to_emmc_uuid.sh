#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

EMMC_DRIVE="/dev/mmcblk0p1"
MOUNT_POINT="/mnt/emmc"

# Get EMMC UUID
EMMC_UUID=$(blkid -s UUID -o value "$EMMC_DRIVE")
if [ -z "$EMMC_UUID" ]; then
    echo "Error: Could not find UUID for $EMMC_DRIVE"
    exit 1
fi

mkdir -p "$MOUNT_POINT"
mount "$EMMC_DRIVE" "$MOUNT_POINT"

echo "Copying root filesystem back to eMMC (UUID: $EMMC_UUID)..."
rsync -axHAWX --numeric-ids --info=progress2 \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / "$MOUNT_POINT"

sync

# Update bootloader to point back to eMMC UUID
EXTLINUX_CONF="/boot/extlinux/extlinux.conf"
sed -i "s|root=[^ ]*|root=UUID=$EMMC_UUID|g" "$EXTLINUX_CONF"
cp "$EXTLINUX_CONF" "$MOUNT_POINT/boot/extlinux/extlinux.conf"

umount "$MOUNT_POINT"
echo "Reverted. System will now boot from eMMC UUID: $EMMC_UUID"
