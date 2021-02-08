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


BACKUP_SOURCE=$1
BACKUP_TARGET=$2
readonly DATETIME="$(date '+%Y-%m-%d_%H:%M:%S')"
readonly BACKUP_DIR="${BACKUP_TARGET}/backups"
readonly BACKUP_PATH="${BACKUP_DIR}/${DATETIME}"
readonly LATEST_LINK="${BACKUP_DIR}/latest"

usage() {
    echo -e "\nUsage: ${0##*/} BACKUP_SOURCE BACKUP_TARGET\n"
}

cleanup_rsync() {
    BAD_BACKUP_PATH="$BACKUP_PATH"
    BAD_BACKUP_DESTINATION="$BACKUP_DIR/BAD_BACKUP"
    echo -e "${RED}Cleaning up${NC}"
    echo -e "${RED}Bad backup to $BAD_BACKUP_PATH, moving to $BAD_BACKUP_DESTINATION${NC}"

    mv "$BAD_BACKUP_PATH" "$BAD_BACKUP_DESTINATION"
}

handle_signals() {
    echo -e "${RED}Recieved signal, stopping and cleaning${NC}"

    # Stop provided background rsync pid
    kill -2 "$1"
    # perform cleanup 
    cleanup_rsync

    exit 1
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

echo -e "beginning local rsync backup"
echo -e "\n"

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

mkdir -p "$BACKUP_DIR"

echo -e "rsync source: ${BACKUP_SOURCE}"
echo -e "rsync target: ${BACKUP_PATH}"
echo -e "\n"

# Start rsync process in the background 
rsync -avq --delete --progress \
    "${BACKUP_SOURCE}/" \
    --link-dest "${LATEST_LINK}" \
    --exclude=".cache" \
    "${BACKUP_PATH}" &

# Save pid of rsync
rsync_pid=$!

# Set a trap for this potentially long running process 
trap 'handle_signals "$rsync_pid"' SIGINT SIGTERM

# Wait for background jobs
if wait; then
    echo -e "Update completed"
    echo -e "updating latest link"
    rm -rf "${LATEST_LINK}"
    ln -s "${BACKUP_PATH}" "${LATEST_LINK}"
else
    echo -e "${RED}Error: rsync failure, cleaning up $BACKUP_PATH"
    cleanup_rsync
fi
