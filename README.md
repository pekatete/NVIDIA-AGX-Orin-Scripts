# NVIDIA-AGX-Orin-Scripts
Bash scripts to set root filesystem of NVIDIA AGX Orin to SSD

1. Migrating to SSD

   a. Download file: migrate_to_ssd.sh

   b. chmod +x migrate_to_ssd.sh

   c. sudo ./migrate_to_ssd.sh /dev/nvme0n1

   d. sudo reboot

2. Reverting to eMMC

    a. Download file: revert-from-ssd-to-emmc.sh

    b. chmod +x revert-from-ssd-to-emmc.sh

    c. sudo ./revert_to_emmc.sh

    d. sudo reboot
