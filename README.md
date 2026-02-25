# NVIDIA-AGX-Orin-Scripts
If migrating to an SSD fomatted as XFS, ensure the kernel supports XFS before running the script. Run:
```
lsmod | grep xfs
```
or
```
grep CONFIG_XFS_FS /boot/config-$(uname -r)
```

Bash scripts to migrate root filesystem of NVIDIA AGX Orin to SSD or revert to eMMC

1. Migrating to SSD - this moves the root filesystem to the SSD

   a. Determine the SSD device (e.g /dev/nvme0n1 or /dev/nvme0n1p1)

   b. Download file: migrate_to_ssd.sh

   c. chmod +x migrate_to_ssd.sh

   d. sudo ./migrate_to_ssd.sh /dev/nvme0n1

   e. sudo reboot

3. Reverting to eMMC

    a. Download file: revert-from-ssd-to-emmc.sh

    b. chmod +x revert-from-ssd-to-emmc.sh

    c. sudo ./revert_to_emmc.sh

    d. sudo reboot
