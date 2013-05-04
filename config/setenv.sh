#
# This file configures the chroot and buildchain configuration
#

# Chroot folder name
# Don't use "" due to Makefile sourcing
export CHROOT_NAME=chroot4cubie

# Mirror for retrive packages during chroot creation
export ARCHLINUX_MIRROR="http://mir.archlinux.fr"
