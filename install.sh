#!/bin/bash
1. Lets get connected to the internet.

# A network tool to connect to internet
iwctl
- device list # list available network adapters
- station wls3p0 scan # scan with wls3p0 wireless adapter
- station wls3p0 get-networks # Lists available networks
- station wls3p0 connect "SSID Name" # Will also ask for password if it has
- exit

ip a # check if you are connected
ping -c 3 8.8.8.8 # Verify access to internet

2. Set up disk partitioning(UEFI + Encryption)

fdisk -l # Check HDD/SDD installed under Disk e.g. (/dev/sda)
#fdisk /dev/sda
#- p # List available partitions
#- g # create a new GPT layout
#- n # create a new partition, choose the default partition number,fisrt sector, last 

## HAHAHA, better switch to cfdisk, lol.
cfdisk /dev/sda # Create your partitions as needed.
    root >40G   = /dev/sda2
    efi !<500M  = /dev/sda1
    swap >2G    = /dev/sda3
# NB: If you are dual booting, don't create a EFI partition, we will use the one already existing
lsblk # Verify if you can identify all required partitions
fdisk -l

# Format and set up LVM

## Note: Skip this if you already have an existing EFI partition
mkfs.fat -F32 /dev/sda1 # create a FAT32 file system for EFI boot partition
mkfs.ext4 /dev/sda2

## Setting up Encryption
cryptsetup luksFormat /dev/sda3 # COnfirm with YES and enter your strong password.

### Unlock this partition for use to work with it
cryptsetup open --type luks /dev/sda3 lvm # Enter the password you just set up.

## Create a physical volume to use with LVM
pvcreate --dataalignment 1m /dev/mapper/lvm

## Create a volume group - a name space that contains logical volume.
vgcreate volgroup0 /dev/mapper/lvm

## Create 2 Logical volumes: Root file system and Home folder
lvcreate -L 30GB volgroup0 -n lv_root
lvcreate -L 100%FREE volgroup0 -n lv_home # Give the remaining space to Home

modprobe dm_mod # Load a required kernel module
vgscan # scan volume groups
vgchange -ay # load logical volume

## Format Logical volumes for root and home file system
mkfs.ext4 /dev/volgroup0/lv_root
mount /dev/volgroup0/lv_root /mnt

mkdir /mnt/boot # create a boot partion
mount /dev/sda1 /mnt/boot

mkfs.ext4 /dev/volgroup0/lv_home
mkdir /mnt/home
mount /dev/volgroup0/lv_home /mnt/home

mkdir /mnt/etc/
genfstab -U -p /mnt >> /mnt/etc/fstab
cat /etc/fstab

# Start Installation of Arch Linux
pacstrap -i /mnt base
arch-chroot /mnt # Chroot to our install for configuration and install required packages

## Install Kernel and blah
pacman -S linux linux-headers 

## 
pacman -S nano base-devel openssh networkmanager wpa_supplicant wireless_tools netctl dialog lvm2
systemctl enable NetworkManager

nano /etc/mkinitcpio.conf # Edit line that begins with HOOKS (... block [here] filesystems...)
# For encrypted disk setup which we do, we need to add (...[encrypt lvm2]...) save and quit
mkinitcpio -p linux # regenerate the vmlinux image and look for encrypt and lvm2 in output logs
nano /etc/locale.gen # Uncomment your locale en_US.UTF-8 UTF-8
locale-gen # Generate newly configured locale

# Setting up users and permissions
passwd # Create a root password (Because we are chrooted as root account)

useradd -m -g users -G wheel username # Replace username with your user specific name
passwd username # Set password for username specified above
EDITOR=nano visudo # Uncomment line: Allow members of group wheel to execute any command %wheel ALL=(ALL) ALL

# Finalize installation with essential Grub installation and remaining packages and few tweaks
pacman -S grub efibootmgr os-prober 

