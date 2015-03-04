#!/bin/bash
#
# ICOS distribution installer.
#
# Maintainer: Samuel Jean <sjean@idsmicronet.com>

usable_disks=()
disk=

reboot()
{
	echo 1 >/proc/sys/kernel/sysrq
	echo u > /proc/sysrq-trigger
	echo s > /proc/sysrq-trigger
	echo b > /proc/sysrq-trigger
}

is_mapper_device()
{
    dev="$1"
    # we don't consider control a mapper device
    echo "$dev" | grep "/dev/mapper/control" >/dev/null && return 1
    echo "$dev" | grep "/dev/mapper/.\+" >/dev/null && return 0
    return 1
}

is_md_device()
{
    dev="$1"
    echo "$dev" | grep "/dev/md[0-9]" >/dev/null && return 0
    return 1
}

find_usable_storage() {
	usable_disks=()
	for devname in $(lsblk -n -o NAME,TYPE | egrep "disk" | \
	    awk '{print $1}'); do
		[ -e "/dev/$devname" ] || continue
		model=$(udevadm info -n /dev/${devname} -q property | \
		    sed -n 's/^ID_MODEL=//p')
		usable_disks+=($devname "(${model})")
	done
}

select_disk()
{
	disk=$(whiptail --title "Choose a disk to work with" --menu \
	"The following disks have been detected :" 20 78 4 \
	"${usable_disks[@]}" 3>&1 1>&2 2>&3)
}

erase_disk()
{
	if (whiptail --title "WARNING! About to erase disk /dev/${disk}" --yesno "A fresh install of ICOS on the disk WILL ERASE ALL DATA you may have on it.  Continue anyway?" 8 78) then
		echo "Erasing disk /dev/${disk}"
		pv -tpreb /dev/zero | dd of=/dev/${disk} bs=1 seek=446 count=64 conv=notrunc
		return 0
	else
		return 1
	fi
}

format_disk()
{
	# Create docker partition (10G).
	printf "n\np\n\n\n+10G\nw\n" | fdisk /dev/$disk
	mkfs.btrfs -L docker -f /dev/${disk}1

	# Create persistent partition (remaining).
	printf "n\np\n\n\n\nw\n" | fdisk /dev/$disk
	mkfs.ext4 -L casper-rw /dev/${disk}2
}

build_iso_again()
{
	outdir=$1
	[ -e $outdir ] || mkdir -p $outdir 
	isoname=$(cat /etc/version)
	xorriso -publisher "IDS MICRONET" -as mkisofs -l -J -R \
		-V "$(cat /etc/version)" -no-emul-boot -boot-load-size 4 \
		-boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat \
		-isohybrid-mbr /usr/lib/syslinux/isohdpfx.bin \
		-o ${outdir}/${isoname}.iso /cdrom
}

mount_persistent_fs()
{
    rootfs=$1
    mkdir -p /cow $rootfs
    cowdevice=$(blkid -L casper-rw)
    cow_fstype="ext4"
    cow_mountopt="rw,noatime"

    mount -t $cow_fstype -o $cow_mountopt $cowdevice /cow

    case ${UNIONFS} in
        aufs|unionfs)
            mount -t ${UNIONFS} -o noatime,dirs=/cow=rw:/rofs=ro \
		$cowdevice $rootfs
            ;;
        overlayfs)
            mount -t overlayfs -o "upperdir=/cow,lowerdir=/rofs" \
		$cowdevice $rootfs
            ;;
    esac

    for i in /dev /dev/pts /proc /sys /run; do mount -B $i ${rootfs}$i; done
}

umount_persistent_fs()
{
	rootfs=$1
	for i in /dev/pts /dev /proc /sys /run; do \
		umount ${rootfs}$i; done
	umount $rootfs
	umount $cowdevice
}

config_boot_loader()
{
	rootfs=$1
	chroot $rootfs dpkg -i /tmp/install-tools/*.deb
	/tmp/scripts/write_grub_config.sh \
		"${rootfs}/etc/grub.d/99_icos"
	chmod +x ${rootfs}/etc/grub.d/99_icos
	chroot $rootfs update-grub
}

do_install()
{
	find_usable_storage
	select_disk
	erase_disk || return 1
	format_disk
	mount_persistent_fs "/rootfs"
	build_iso_again "/rootfs/boot"
	config_boot_loader "/rootfs"
	umount_persistent_fs "/rootfs"
}

do_upgrade()
{
	find_usable_storage
	select_disk
	mount_persistent_fs "/rootfs"
	build_iso_again "/rootfs/boot"
	config_boot_loader "/rootfs"
	umount_persistent_fs "/rootfs"
}

while true; do
	case $(whiptail --title "$(cat /etc/version)" \
		--menu "\nWelcome to the ICOS installer. What do you want to do?" \
		20 78 8 \
		"1." "Install system" \
		"2." "Upgrade system" \
		"3." "Rebuild ISO" \
		"4." "Run a shell" \
		"5." "Reboot" \
		3>&1 1>&2 2>&3) in
	1*) do_install
	;;

	2*) do_upgrade
	;;
	3*) build_iso_again "/tmp"
	;;
	4*) /bin/bash
	;;
	5*) reboot
	;;
	esac

	# exit if started with DEBUG= ./install.sh
	[ -z ${DEBUG+x} ] || exit
done
