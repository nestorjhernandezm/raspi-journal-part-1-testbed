#!/usr/bin/env bash

set -e -u

# Target device
dev=/dev/mmcblk0

# Print error
echoerr() { cat <<< "$@" 1>&2; }

# Make sure script is run with root permissions
if [ "$(id -u)" != "0" ]; then
   echoerr "This script must be run as root"; exit 1
fi

# Make sure we write to a block device
if [ ! -b ${dev} ]; then
    echoerr "Error: ${dev} is not a block device"; exit 1
fi

# Make sure the user knows what he is doing
read -r -p "WARNING: Everything on ${dev} will be erased. Continue [y/N]? " response
[[ ! ${response,,} =~ ^(yes|y) ]] && exit 1



# Erase partition table (4M because: rather too much than too little)
dd if=/dev/zero of=${dev} bs=4M count=1

(echo o;                                        # Create DOS partition table
    echo n; echo p; echo 1; echo ; echo +64M;   # Create boot partition
    echo t; echo b;                             # Set boot partition type to FAT
    echo n; echo p; echo 2; echo ; echo ;       # Create home partition (default partition type: Linux)
    echo w                                      # Write table to disk
    ) | fdisk ${dev}

# Print new partition table
fdisk -lu ${dev}

# Format partitions
mkfs.vfat -n BOOT ${dev}p1
mkfs.ext4 -L HOME ${dev}p2

# SHOULD THE BELOW BE COPIED FROM THE ROOT IMAGE?

# Create temp directory that is erased when script exits
mnt=$(mktemp -d)

# Create home directory for user: pi (uid=1000) in group pi (gid=1000). (gid=100 if group users are preferred)
# mode=700 means: drwx------ (i.e. only the user and root has access to his directory)
mount ${dev}p2 ${mnt}
install -d -o 1000 -g 1000 -m 700 ${mnt}/pi && sync

# Cleanup
umount ${mnt} && rm -r ${mnt}
