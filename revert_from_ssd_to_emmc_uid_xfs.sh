#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

EMMC_DRIVE="/dev/mmcblk0p1"
MOUNT_POINT="/mnt/emmc"

# 1. Get EMMC UUID
EMMC_UUID=$(blkid -s UUID -o value "$EMMC_DRIVE")
if [ -z "$EMMC_UUID" ]; then
    echo "Error: Could not find UUID for $EMMC_DRIVE"
    exit 1
fi

# 2. Mount and Sync back
mkdir -p "$MOUNT_POINT"
mount "$EMMC_DRIVE" "$MOUNT_POINT"

echo "Copying root filesystem back to eMMC..."
rsync -axHAWX --numeric-ids --info=progress2 \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / "$MOUNT_POINT"

# 3. Update /etc/fstab ON THE EMMC
# We must ensure the eMMC's fstab says 'ext4', not 'xfs'
echo "Ensuring eMMC /etc/fstab is set to ext4..."
EMMC_FSTAB="$MOUNT_POINT/etc/fstab"
if [ -f "$EMMC_FSTAB" ]; then
    # This force-sets the root entry back to the EMMC UUID and ext4 type
    sed -i "s|^[^#].*\s\+/\s\+.*|UUID=$EMMC_UUID / ext4 defaults 0 1|" "$EMMC_FSTAB"
fi

# 4. Update bootloader (extlinux.conf)
EXTLINUX_CONF="/boot/extlinux/extlinux.conf"
echo "Updating bootloader to point back to eMMC UUID..."
sed -i "s|root=[^ ]*|root=UUID=$EMMC_UUID|g" "$EXTLINUX_CONF"

# Ensure the config on the eMMC boot partition is also updated
cp "$EXTLINUX_CONF" "$MOUNT_POINT/boot/extlinux/extlinux.conf"

sync
umount "$MOUNT_POINT"

echo "Reverted. System is set to boot from eMMC (ext4) with UUID: $EMMC_UUID"
