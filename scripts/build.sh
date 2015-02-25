#!/bin/bash

DISTVER="ddcos-${VERSION}"

ISODIR="/tmp/iso"
PKGDIR="/tmp/bundle"
DATADIR="/data"
ISOFILE="${DATADIR}/ddcos.iso"
ROOTFS="/tmp/rootfs"
ROOTFS_SQUASH_FILE="${ISODIR}/live/squashfs.filesystem"

export ISODIR PKGDIR DATADIR ISOFILE ROOTFS ROOTFS_SQUASH_FILE

LINES=8; COLUMNS=78
export LINES COLUMNS

for dir in $ISODIR $PKGDIR $DATADIR \
  $ISODIR/boot $ISODIR/live $ISODIR/install \
  $ROOTFS; do
  [ -d $dir ] || mkdir -p $dir
done

for dir in /bundle/*/; do
  [ -d ${PKGDIR}/$(basename $dir) ] || mv $dir $PKGDIR
done

source /scripts/functions
run_scripts /scripts/build
