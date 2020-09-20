#!/bin/bash
#
# Adds an device's uuid to fstab under a provided mount point,
# so it can be mounted more easily.
#
# Takes two arguments
#   1. mounted drive ex: /dev/sda
#   2. desired mount point for fstab, ex: /media/spinny-external-disk
#   3. user to own mount point
#
# Firstly the script will create a file using the desired mount point,
# and chown it appropriately.
#
# Script will attempt to source the UUID from the mounted drive
# and then safely append an fstab entry for it using the mount point
# that was created.
#

NC='\033[0m'
RED='\033[0;31m'


cleanup_rmdir() {
    exit_status=$?
    if [ "$exit_status" -ne 0 ]
    then
        echo "CLEANUP: removing $1"
        rmdir "$1"
    fi
}

usage() {
    echo -e "\nUsage: ${0##*/} drive desired-mount-point\n"
}

if [ $# -ne 3 ]
then
    echo -e "${RED}ERROR: Improper number of arguments${NC}"
    usage
    exit 1
fi

if [ $# = "--help" ] || [ $# == "-h" ]
then
    usage
    exit 0
fi

if [ "$(id -u)" -ne "0" ]
then
    echo -e "${RED}ERROR: Script must be run as root${NC}"
    usage
    exit 1
fi

echo "beginning fstab entry creation"
echo -e "\n"

DISK=$1
MOUNT_POINT=$2
USER=$3

echo "checking supplied user"
if id "$USER" &>/dev/null;
then
    echo "user valid"
else
    echo -e "${RED}ERROR: $USER is not a valid user${NC}"
    exit 1
fi

echo -e "\n"

echo "creating mount point directory, $MOUNT_POINT"
if [ -d "$MOUNT_POINT" ];
then
    echo -e "${RED}ERROR: mount point dir already exists${NC}"
    exit 1
else
    mkdir -p "$MOUNT_POINT"
    chown "$USER":"$USER" "$MOUNT_POINT"
    chmod +rw "$MOUNT_POINT"
    echo "mount point created"
fi

echo -e "\n"

# This is an "inline" trap. Moving this to the top level prior to checking to see
# if we have a valid mount point could lead to accidental deletion of a legit folder
trap 'cleanup_rmdir "$MOUNT_POINT"' EXIT

echo "attempting to write fstab entry"
echo "extracting uuid from disk, $DISK"

# outputs blkid information one line at a time with a LABEL= format
if ! UUID_OUTPUT=$(blkid "$DISK" --output export);
then
    echo -e "${RED}blkid lookup failure, unable to get info about device $DISK${NC}"
    exit 1
fi

UUID=$(echo "$UUID_OUTPUT" | awk '/^UUID=/ {print}')
# type must be just a literal
TYPE=$(echo "$UUID_OUTPUT" | awk '/^TYPE=/ {split($0,type,"="); print type[2]}')

if [ ! "$UUID" ] || [ ! "$TYPE" ]
then
    echo -e "${RED}ERROR: unable to extract values form blkid export output for device $DISK${NC}"
    exit 1
fi

FSTAB_ENTRY="$UUID $MOUNT_POINT $TYPE defaults,users,noauto 0 0"
echo "writing to fstab: $FSTAB_ENTRY"
echo -e "$FSTAB_ENTRY\n" >> /etc/fstab

exit 0
