#!/bin/bash
#
# This script creates an ArchLinux clean chroot environment,
# where the buildchain will be located.
#
######################################################################################
#
# Copyright 2013. Ferigo D., Kapidani B.
#
# cubieboard-laptop is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# cubieboard-laptop is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with cubieboard-laptop.  If not, see <http://www.gnu.org/licenses/>.
#
######################################################################################

CHROOT_NAME=chroot4cubie
ARCHLINUX_MIRROR="http://mir.archlinux.fr"

if [ $(whoami) != "root" ] ; then
	echo -e ">>"
	echo -e ">> This script must be run with root privileges"
	echo -e ">>"
	exit 1
fi

if [ "$1" != "" ] ; then
	CHROOT_NAME=$1
fi

# pwd from the calling folder
CHROOT_DIR=$(pwd)/$CHROOT_NAME

# Change the variable in the environment file, used in in-chroot.sh
# Don't use the "" defining CHROOT_NAME because then the Makefile doesn't likes them
sed -i "s/CHROOT_NAME=.*$/CHROOT_NAME=\"${CHROOT_NAME}\"/g" config/setenv.sh

#yellow="\e[1;33m"
#blue="\e[1;34m"
PrintColor()
{
	bold="\e[;1m"
	green="\e[1;32m"
	default="\e[0m"
	echo -e "$green==>$default$bold $@ $default"
}

Error()
{
	bold="\e[;1m"
	red="\e[1;31m"
	default="\e[0m"
	echo -e "$red==>$defaul$bold $@ $default"
}

Die()
{
	Error "$@"
	exit 1
}

CheckNetwork()
{
	if ( ! ping -c 3 www.google.it &> /dev/null ) ; then
		echo -e ">>"
		echo -e ">> You need internet an available connection"
		echo -e ">>"
		exit 1
	fi
}

# This function is used to shorten the EXECUTion of commands
# inside the chroot from an EXTernal environment
ExecutExt()
{
	PASSUSER2CHROOT=""
	if [ "$1" = --asuser ] ; then
		shift
		PASSUSER2CHROOT=--userspec=$1
		shift
	fi
	LC_ALL=C chroot $PASSUSER2CHROOT "${CHROOT_DIR}" $@
}

# Check if the distro lack some binary used in this script
CheckBinary()
{
	for i in $@ ; do
		if ( ! which $i &> /dev/null ) ; then
			echo -e ">>"
			echo -e ">> You lack $i binary"
			echo -e ">> Install $i from your distro repository"
			echo -e ">>"
			exit 1
		fi
	done
}

# From archlinux official script:
track_mount() {
  mount "$@" && CHROOT_ACTIVE_MOUNTS=("$2" "${CHROOT_ACTIVE_MOUNTS[@]}")
}

api_fs_mount() {
  CHROOT_ACTIVE_MOUNTS=()
  { mountpoint -q "$1" || track_mount "$1" "$1" --bind; } &&
  track_mount proc "$1/proc" -t proc -o nosuid,noexec,nodev &&
  track_mount sys "$1/sys" -t sysfs -o nosuid,noexec,nodev &&
  track_mount udev "$1/dev" -t devtmpfs -o mode=0755,nosuid &&
  track_mount devpts "$1/dev/pts" -t devpts -o mode=0620,gid=5,nosuid,noexec &&
  track_mount shm "$1/dev/shm" -t tmpfs -o mode=1777,nosuid,nodev &&
  track_mount run "$1/run" -t tmpfs -o nosuid,nodev,mode=0755 &&
  track_mount tmp "$1/tmp" -t tmpfs -o mode=1777,strictatime,nodev,nosuid
}

api_fs_umount() {
  umount "${CHROOT_ACTIVE_MOUNTS[@]}"
}

# The preferred architecture for the chroot environment is x86_64.
# If we are in a iX86 machine, force the chroot architecture to 32bit.
# (it's not possible execute 64bit binaries in 32bit system)
MASTER_ARCH=$(uname -m)

if [ "$MASTER_ARCH" = "i686" ]; then
	ARCH=i686
else
	ARCH=${MASTER_ARCH}
fi

# All binary used in this script
CheckBinary wget sed xz tar chroot

# Check if internet connection is available
CheckNetwork

# Download the bootstrap script
PrintColor "Downloading the bootstrap script"
wget http://tokland.googlecode.com/svn/trunk/archlinux/arch-bootstrap.sh || die "Download failed"

# Executable rights
chmod +x arch-bootstrap.sh

# Launch the script
PrintColor "Launching the bootstrap script"
mkdir chroot4cubie/
./arch-bootstrap.sh -a $ARCH -r ${ARCHLINUX_MIRROR} ${CHROOT_DIR} || \
	die "Something goes wrong executing the bootstrap script"

# Mount some folder
PrintColor "Mounting /dev /proc /sys folders"
# mount -o bind /dev ${CHROOT_DIR}/dev && \
# 	mount -t proc none ${CHROOT_DIR}/proc && \
# 	mount -t sysfs none ${CHROOT_DIR}/sys && \
# 	mkdir -p ${CHROOT_DIR}/dev/pts && \
# 	mount -t devpts pts ${CHROOT_DIR}/dev/pts/ || die 
api_fs_mount ${CHROOT_DIR} || die "Mounting fs in chroot env failed"

# Trap the EXIT signal with the folder umount  
trap '{ api_fs_umount "${CHROOT_DIR}"; umount "$chrootdir/etc/resolv.conf"; } 2>/dev/null' EXIT
track_mount /etc/resolv.conf "${CHROOT_DIR}/etc/resolv.conf" --bind

# Sets again the SigLevel to Never
# Oss: ExecutExt is not used because sed is still no installed inside
sed -i "s/^[[:space:]]*SigLevel[[:space:]]*=.*$/SigLevel = Never/" "${CHROOT_DIR}/etc/pacman.conf"

# Add some repositories and install other useful packages
ExecutExt echo -e "\n[archlinuxfr]\nServer = http://repo.archlinux.fr/$ARCH" >> ${CHROOT_DIR}/etc/pacman.conf
PrintColor "Installing additional packages, including base-devel"
ExecutExt /usr/bin/pacman --noconfirm --arch $ARCH --needed  -Sy \
	`ExecutExt pacman -Sqg base-devel` nano iputils less man-db git gperf wget yaourt inetutils || \
	die "Something goes wrong downloading or installing extra packages in the chroot"

#
# Configure the chroot:
#
# - Set a root password
PrintColor "Enter the ROOT password:"
ExecutExt passwd
#
# - Add new user
PrintColor "Enter the name for the non-root user. This will be used for all the tasks:"
read USERNAME
ExecutExt "useradd -m -g users -s /bin/bash $USERNAME"
PrintColor "Enter $USERNAME password:"
ExecutExt "passwd $USERNAME"
#
# - Configure system locale
PrintColor "Generating locales"
sed -i "s/#en_US/en_US/" ${CHROOT_DIR}/etc/locale.gen
sed -i "s/#it_IT/it_IT/" ${CHROOT_DIR}/etc/locale.gen
ExecutExt locale-gen
ExecutExt echo -e 'LANG="it_IT.UTF-8"' >> ${CHROOT_DIR}/etc/locale.conf

#
# Set the hostname
PrintColor "Setting hostname"
ExecutExt echo -e "chroot4cubie" > ${CHROOT_DIR}/etc/hostname 

# Set the timezone and keymap
PrintColor "Setting localtime and console keymap"
ln -s $CHROOT_DIR/usr/share/zoneinfo/Europe/Rome ${CHROOT_DIR}/etc/localtime
ExecutExt echo -e "KEYMAP=it" > ${CHROOT_DIR}/etc/vconsole.conf

#
# Install, configure and run crosstool-ng to build the cross toolchain
#

# Install crosstool-ng package
ExecutExt --asuser $USERNAME yaourt -S crosstool-ng --noconfirm || \
	die "Crosstool-ng build or install failed"

# Copy the ct-ng config file
mkdir -p ${CHROOT_DIR}/home/$USERNAME/cross
mkdir -p ${CHROOT_DIR}/home/$USERNAME/cross/src
cp config/crosstool.config ${CHROOT_DIR}/home/$USERNAME/cross
cp ${CHROOT_DIR}/home/$USERNAME/cross/crosstool.config ${CHROOT_DIR}/home/$USERNAME/cross/.config
chown -R $USERNAME:users ${CHROOT_DIR}/home/$USERNAME/cross
