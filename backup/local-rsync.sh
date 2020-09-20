#!/bin/bash

# rsync backup script for a local target
#
# This script takes two parameters:
#   1. a folder of stuff to back up: BACKUP_SOURCE
#   2. a destination mount point that exists in fstab
#
# local_rsync will:
#   1. mount the provided BACKUP_TARGET
#   2. rsync the backup source into a folder called "backups" in the target,
#      named for the current date and time
#   3. create a symbolic link to the most recent backup called LATEST
#
# Subequent runs will update the latest link
#

NC='\033[0m'
RED='\033[0;31m'

usage() {
    echo -e "\nUsage: ${0##*/} BACKUP_SOURCE BACKUP_TARGET\n"
}

cleanup_rsync() {
    echo "${RED}Bad backup to $1, moving to BAD_BACKUP${NC}"
    mv "$1" BAD_BACKUP

    rm -rI BAD_BACKUP
}

handle_signals() {
    echo "${RED}Recieved signal, stopping and cleaning${NC}"
    cleanup_rsync "$1"
}

if [ $# -ne 2 ]
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

echo "beginning local rsync backup"
echo -e "\n"

BACKUP_SOURCE=$1
BACKUP_TARGET=$2

if [ ! -d "$BACKUP_SOURCE" ]
then
    echo -e "${RED}ERROR: Privided BACKUP_SOURCE is not a directory${NC}"
    exit 1
fi

if mountpoint -q "$BACKUP_TARGET";
then
    echo -e "Provided backup target $BACKUP_TARGET is already mounted"
else
    if ! mount "$BACKUP_TARGET";
    then
        echo -e "${RED}ERROR: Provided backup target $BACKUP_TARGET could not be mounted"
        exit 1
    fi
fi

readonly DATETIME="$(date '+%Y-%m-%d_%H:%M:%S')"
readonly BACKUP_DIR="${BACKUP_TARGET}/backups"
readonly BACKUP_PATH="${BACKUP_DIR}/${DATETIME}"
readonly LATEST_LINK="${BACKUP_DIR}/latest"

mkdir -p "$BACKUP_DIR"

echo "rsync source: ${BACKUP_SOURCE}"
echo "rsync target: ${BACKUP_PATH}"
echo -e "\n"

trap 'handle_signals "$BACKUP_PATH"' SIGINT SIGTERM

if rsync_status=$(rsync -avq --delete \
    "${BACKUP_SOURCE}/" \
    --link-dest "${LATEST_LINK}" \
    --exclude=".cache" \
    "${BACKUP_PATH}");
then
    echo "updating latest link"
    rm -rf "${LATEST_LINK}"
    ln -s "${BACKUP_PATH}" "${LATEST_LINK}"
else
    echo "${RED}Error: rsync failure, cleaning up $BACKUP_PATH"
    cleanup_rsync "$BACKUP_PATH"
fi
