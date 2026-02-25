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

# 1. Format the drive as XFS (Dynamic Inodes)
echo "Formatting $NVME_DRIVE as XFS..."
# -f forces the format if a filesystem already exists
mkfs.xfs -f "$NVME_DRIVE"

# 2. Get the new UUID
TARGET_UUID=$(blkid -s UUID -o value "$NVME_DRIVE")
echo "New Target UUID: $TARGET_UUID"

# 3. Mount and Sync
mkdir -p "$MOUNT_POINT"
mount "$NVME_DRIVE" "$MOUNT_POINT"

echo "Copying root filesystem to SSD..."
rsync -axHAWX --numeric-ids --info=progress2 \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / "$MOUNT_POINT"

# 4. Update the target's /etc/fstab
# We change the root (/) entry to point to our new UUID and 'xfs' type
echo "Updating /etc/fstab on the target SSD..."
TARGET_FSTAB="$MOUNT_POINT/etc/fstab"

if [ -f "$TARGET_FSTAB" ]; then
    # Backup fstab inside the SSD
    cp "$TARGET_FSTAB" "${TARGET_FSTAB}.bak"
    # Replace the root partition line. 
    # This regex looks for the line mounting to '/' and replaces the UUID and type.
    sed -i "s|^[^#].*\s\+/\s\+.*|UUID=$TARGET_UUID / xfs defaults 0 1|" "$TARGET_FSTAB"
fi

# 5. Update Bootloader (extlinux.conf)
EXTLINUX_CONF="/boot/extlinux/extlinux.conf"
SSD_EXTLINUX_CONF="$MOUNT_POINT/boot/extlinux/extlinux.conf"

echo "Updating bootloader config..."
# Update the local file first
sed -i "s|root=[^ ]*|root=UUID=$TARGET_UUID|g" "$EXTLINUX_CONF"
# Copy it to the SSD so they match
cp "$EXTLINUX_CONF" "$SSD_EXTLINUX_CONF"

sync
umount "$MOUNT_POINT"

echo "Success! The SSD is now XFS-formatted with dynamic inodes."
echo "Reboot to start using your 1TB drive."
