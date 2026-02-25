#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

NVME_DRIVE="$1"
MOUNT_POINT="/mnt/ssd"

# --- SAFETY CHECKS ---
if [ -z "$NVME_DRIVE" ] || [ ! -e "$NVME_DRIVE" ]; then
    echo "Usage: $0 <SSD device path> (e.g., /dev/nvme0n1p1)"
    exit 1
fi

# Prevent formatting the eMMC by mistake
if [[ "$NVME_DRIVE" == *"mmcblk"* ]]; then
    echo "ERROR: Target drive $NVME_DRIVE looks like internal eMMC! Aborting."
    exit 1
fi

# Final manual confirmation
read -p "WARNING: This will WIPE ALL DATA on $NVME_DRIVE. Are you sure? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted by user."
    exit 1
fi
# ---------------------

# 1. Install xfsprogs
if ! command -v mkfs.xfs &> /dev/null; then
    echo "Installing xfsprogs..."
    apt update && apt install -y xfsprogs
fi

# 2. Add XFS to initramfs modules
MODULES_FILE="/etc/initramfs-tools/modules"
if ! grep -q "^xfs" "$MODULES_FILE"; then
    echo "Adding xfs to initramfs modules..."
    echo "xfs" >> "$MODULES_FILE"
fi

# 3. Format as XFS (Fixed your inode issue forever)
echo "Formatting $NVME_DRIVE as XFS..."
mkfs.xfs -f "$NVME_DRIVE"
TARGET_UUID=$(blkid -s UUID -o value "$NVME_DRIVE")

# 4. Mount and Sync
mkdir -p "$MOUNT_POINT"
mount "$NVME_DRIVE" "$MOUNT_POINT"

echo "Copying root filesystem to SSD..."
rsync -axHAWX --numeric-ids --info=progress2 \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / "$MOUNT_POINT"

# 5. Update FSTAB and Bootloader
echo "Updating /etc/fstab and bootloader..."
sed -i "s|^[^#].*\s\+/\s\+.*|UUID=$TARGET_UUID / xfs defaults 0 1|" "$MOUNT_POINT/etc/fstab"
sed -i "s|root=[^ ]*|root=UUID=$TARGET_UUID|g" /boot/extlinux/extlinux.conf
cp /boot/extlinux/extlinux.conf "$MOUNT_POINT/boot/extlinux/extlinux.conf"

# 6. Update Initramfs
echo "Regenerating initramfs..."
update-initramfs -u
sync
umount "$MOUNT_POINT"

echo "Done! Target UUID: $TARGET_UUID. You can now reboot."
