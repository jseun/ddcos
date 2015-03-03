#!/bin/bash

DISTVER="ddcos-${VERSION}"
SHDIR="/tmp/scripts"
DATADIR="/data"
ISODIR="${DATADIR}/iso"
APTDIR="${ISODIR}/archives"
PKGDIR="${APTDIR}/dists/local/main/binary-amd64"
ISOFILE="${DATADIR}/ddcos.iso"
ROOTFS="${DATADIR}/rootfs"
ROOTFS_SQUASH_FILE="${ISODIR}/live/filesystem.squashfs"

export ISODIR APTDIR PKGDIR DATADIR ISOFILE ROOTFS ROOTFS_SQUASH_FILE \
SHDIR DISTVER

LINES=8; COLUMNS=78
export LINES COLUMNS

for dir in $ISODIR $PKGDIR $DATADIR \
  $ISODIR/live $ROOTFS; do
  [ -d $dir ] || mkdir -p $dir
done

source ${SHDIR}/functions
run_scripts ${SHDIR}/build
