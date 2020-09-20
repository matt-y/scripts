# Script collection

Herein is a collection of scripts intended to make day to day life a bit easier
on the computer. The collection is a bit of a hodgepodge - they run the gamut
from automating backups to creating mount points for devices in fstab. The real
unifying theme is that they make a repetetive task a little more tolerable.

## Categories

Scripts are divided into various categories based on their intended use. See the
outline below for a listing. 

### [Drives](./drives)

Intended to aid in the management of storage media. Primarily the external
variety.

- [add-to-fstab.sh](./drives/add-to-fstab.sh) &dash; Adds a device's uuid to
  fstab with a user provided mount point. Ensures that a provided device will
  get the same mount point every time it is plugged in.

### [Backup](./backup)

Scripts related to backup creation, and backup execution.

- [local-rsync.sh](./backup/local-rsync) &dash; Script that executes an rsync
  with a local source to a local mountable target. I use this in combination
  with the [add-to-fstab.sh](./drives/add-to-fstab.sh) script to create a local
  backup of my home directory to an external drive that I use for simple
  backups.
