#!/bin/bash
#
# ICOS distribution installer.
#
# Maintainer: Samuel Jean <sjean@idsmicronet.com>

usable_disks=()
disk=

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
	for devname in $(lsblk -n -o NAME,TYPE | grep "disk" | \
	    awk '{print $1}'); do
		[ -e "/dev/$devname" ] || continue
		model=$(udevadm info -n /dev/${devname} -q property | \
		    sed -n 's/^ID_MODEL=//p')
		usable_disks+=($devname "(${model})")
	done
echo ${usable_disks[@]}
}

select_disk()
{
	disk=$(whiptail --title "Choose a disk to work with" --menu \
	"The following disks have been detected :" 20 78 4 \
	"${usable_disks[@]}" 3>&1 1>&2 2>&3)
}

erase_disk()
{
	if (whiptail --title "WARNING! About to erase disk /dev/${disk}" --yesno "A fresh install WILL ERASE ALL DATA you may have on it.  Continue anyway?" 8 78) then
		echo "Erasing disk /dev/${disk}"
		dd if=/dev/zero of=/dev/${disk} bs=1 seek=446 count=64 conv=notrunc
		return 0
	else
		return 1
	fi
}

format_disk()
{
  printf "n\np\n\n\n\nw\n" | fdisk /dev/$disk
  mkfs.ext4 -L persistence /dev/${disk}1
}

build_iso_again()
{
	outdir=$1
	[ -e $outdir ] || mkdir -p $outdir 
	isoname=$(cat /etc/version)
	xorriso -publisher "$(cat /etc/publisher)" -as mkisofs -l -J -R \
		-V "$(cat /etc/version)" -no-emul-boot -boot-load-size 4 \
		-boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat \
		-isohybrid-mbr /usr/lib/syslinux/isohdpfx.bin \
		-o ${outdir}/${isoname}.iso /cdrom
}

mount_persistent_fs()
{
  mkdir -p /mnt
  mount -t ext4 -o rw /dev/${disk}1 /mnt
}

umount_persistent_fs()
{
  umount /mnt
}

config_boot_loader()
{
  mkdir -p /mnt/boot/syslinux
  cp -r /usr/lib/syslinux/modules/bios/*.c32 /mnt/boot/syslinux
  extlinux --install /mnt/boot/syslinux
  printf '\x1' | cat /usr/lib/syslinux/mbr/altmbr.bin - | \
    dd bs=440 count=1 iflag=fullblock of=/dev/${disk}

  cat <<EOF > /mnt/persistence.conf
/bin  union
/etc  union
/lib  union
/sbin union
/usr  union
/boot bind
/var  bind
EOF

}

do_install()
{
	find_usable_storage
	select_disk
	erase_disk || return 1
	format_disk
	mount_persistent_fs
	build_iso_again "/mnt/boot"
	config_boot_loader
	umount_persistent_fs
}

while true; do
	case $(whiptail --title "$(cat /etc/version)" \
		--menu "\nWelcome to the installer. What do you want to do?" \
		20 78 8 \
		"1." "Install system" \
		"2." "Run a shell" \
		"3." "Reboot" \
		3>&1 1>&2 2>&3) in
	1*) do_install
	;;

	2*) /bin/bash --norc
	;;
	3*) reboot
	;;
	esac

	# exit if started with DEBUG= ./install.sh
	[ -z ${DEBUG+x} ] || exit
done
