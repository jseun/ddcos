#!/bin/bash

LIVE_PATH=/lib/live/mount/persistence/sr0/live
DISTVER=$(cat /etc/version)
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
		#model=$(udevadm info -n /dev/${devname} -q property | \
		#    sed -n 's/^ID_MODEL=//p')
                model="Hard disk"
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
  printf "n\np\n\n\n\na\nw\n" | fdisk /dev/$disk
  mkfs.ext4 -L persistence /dev/${disk}1
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

copy_live_to_disk()
{
  [ -e $LIVE_PATH ] || return 1
  [ -d /mnt/boot ] || mkdir -p /mnt/boot
  cp -vax $LIVE_PATH /mnt/boot/$DISTVER
}

copy_docker_to_disk()
{
  version=$(/usr/bin/docker version | awk '/Client version:/{print $3}')
  mkdir -p /mnt/usr/bin; cp -v /usr/bin/docker /mnt/usr/bin/docker-$version
  (cd /mnt/usr/bin; ln -sf docker-$version docker)
}

write_persistence_conf()
{
  cat <<EOF > /mnt/persistence.conf
/etc            union
/usr/bin        union
/var/lib/docker bind
EOF
}

write_boot_config()
{
  sl_conf_file=/mnt/boot/syslinux/syslinux.cfg
  cat <<EOF > $sl_conf_file
UI menu.c32
PROMPT 0
MENU TITLE Boot Menu
TIMEOUT 50
EOF
  allos=($(cd /mnt/boot; ls -d * | egrep -v syslinux))
  for os in ${allos[@]}; do
    kernel=$(basename /mnt/boot/$os/vmlinuz-*)
    initrd=$(basename /mnt/boot/$os/initrd.img-*)
    kernel_boot_params=$(cat /mnt/boot/$os/bootparams.txt)
    cat <<EOF >> $sl_conf_file

LABEL $os
  MENU LABEL $os
  LINUX /boot/$os/$kernel
  INITRD /boot/$os/$initrd 
  APPEND boot=live live-media-path=boot/$os ${kernel_boot_params}

EOF
  done
  cat <<EOF >> $sl_conf_file

DEFAULT $os
EOF
}

config_boot_loader()
{
  mkdir -p /mnt/boot/syslinux
  cp -r /usr/lib/syslinux/modules/bios/*.c32 /mnt/boot/syslinux
  extlinux --install /mnt/boot/syslinux
  dd bs=440 count=1 if=/usr/lib/syslinux/mbr/mbr.bin of=/dev/${disk}
}

do_install()
{
  find_usable_storage
  select_disk
  erase_disk || return 1
  format_disk
  mount_persistent_fs
  write_persistence_conf
  copy_live_to_disk
  copy_docker_to_disk
  config_boot_loader
  write_boot_config
  umount_persistent_fs
}

while true; do
	case $(whiptail --title "$DISTVER" \
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
