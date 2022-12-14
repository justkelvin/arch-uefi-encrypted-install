# Install Arch Linux in UEFI + Encryption

---

1. **Getting connected to internet.**
   
   - **iwctl**
     
     A network tool to connect to internet generally used in arch installs
     
     ```bash
     root@archlive~: iwctl
     iwctl: device list # list available network adapters
     iwctl: station wls3p0 scan # scan with wls3p0 wireless adapter
     iwctl: station wls3p0 get-networks # Lists available networks
     iwctl: station wls3p0 connect "SSID Name" # Will ask for creds
     iwctl: exit
     
     root@archlive~: ip a # check if you are connected
     root@archlive~: ping 8.8.8.8 # Verify access to internet
     ```

2. **Set up disk partitioning(UEFI + Encryption)**
   
   - **cfdisk** - Creating required partitions
     
     ```bash
     cfdisk /dev/sda # Create your partitions as needed.
     ```
     
     *I have an EFI partiotion(/dev/sda1) from windows installation and my root has been created at sda4 to avoid confusion.*
     
     **efi** - 500MB = /dev/sda1 *create this if you don't have existing efi*
     
     **root** - 300GB = /dev/sda4
     
     **NB: If you are dual booting, don't create a EFI partition, use existing one. In my case that is /dev/sda1**
     
     ```bash
     lsblk # Verify if you can identify all required partitions
     fdisk -l # Different way.
     ```

   - **mks tools*** - Formating and setting up LVM
     
     ### <u>**Setup EFI Partion**</u>
     
     **Note: Skip this if you already have an existing EFI partition**
     
     Format EFI to FAT32
     
     ```bash
     mkfs.fat -F32 /dev/sda1 # create a FAT32 file system for EFI boot partition
     ```
     
     Format root partion to ext4
     
     ```bash
     mkfs.ext4 /dev/sda4 # the root partition
     ```

     ### <u>**Setting up Encryption**</u>
     
     ```bash
     cryptsetup luksFormat /dev/sda4 # Confirm with YES and enter your strong password.
     
     cryptsetup open --type luks /dev/sda4 lvm # Enter the password you just set up to unlock the partition.
     ```

     ### <u>**Unlock root partition in order for us to work with**</u>
     
     ```bash
     cryptsetup open --type luks /dev/sda3 lvm # Enter the password you just set up and map as lvm.
     ```
     
     ### <u>**Create a physical volume to use with LVM**</u>
     
     ```bash
     pvcreate --dataalignment 1m /dev/mapper/lvm
     ```
     
     ### <u>**Create a volume group - a name space that contains logical volume.**</u>
     
     ```bash
     vgcreate volgroup0 /dev/mapper/lvm
     ```
     
     ### <u>**Create Logical volumes for root and perform required ops**</u>
     
     ```bash
     lvcreate -L 100%FREE volgroup0 -n lv_root # Give all space to root
     modprobe dm_mod # Load a required kernel module
     vgscan # scan volume groups
     vgchange -ay # load logical volume
     ```
     
     ### <u>**Format root logical volume and mount required partitions**</u>
     
     ```bash
     mkfs.ext4 /dev/volgroup0/lv_root
     
     mount /dev/volgroup0/lv_root /mnt
     
     mkdir /mnt/boot/EFI # create a boot partion
     
     mount /dev/sda1 /mnt/boot # Mount it
     
     mkdir /mnt/etc/ # Config directory
     
     genfstab -U -p /mnt >> /mnt/etc/fstab # Generate filesystem conf and save it
     
     cat /etc/fstab # Verify 
     ```

3. **Start Arch Installation**
   
    Lets first install main packages and the kernel
   
   ```bash
   pacstrap -i /mnt base
   
   arch-chroot /mnt # Chroot to our system
   
   pacman -S linux linux-headers # Thats the kernel and headers
   
   pacman -S nano base-devel openssh networkmanager wpa_supplicant wireless_tools netctl dialog lvm2 # You need this, trust me.
   
   systemctl enable NetworkManager # Enable network service
   ```
   
    Some required editing you need in order for our luks to work
   
   ```bash
   nano /etc/mkinitcpio.conf # Edit line that begins with HOOKS (... block [here] filesystems...)
   ```
   
    For encrypted disk setup which we do, we need to add ***(...[encrypt lvm2]...)*** save and quit
    Should now look like this.
   
   ```bash
   HOOKS (... block encrypt lvm2 filesystems...)
   ```
   
    Regenerate the vmlinux image and look for **encrypt and lvm2** in output logs
   
   ```bash
   mkinitcpio -p linux
   ```
   
   ```bash
   nano /etc/locale.gen # Uncomment your locale e.g. en_US.UTF-8 UTF-8
   locale-gen # Generate newly configured locales
   ```

4. **Set up users and permissions**
   
   ```bash
   passwd # Create a root password (Because we are chrooted as root account)
   
   useradd -m -g users -G wheel justkelvin # Replace justkelvin with your desired name
   
   passwd justkelvin # Set password for user created above
   ```
   
    Let's add the newly created user to the sudoers file
   
   ```bash
   EDITOR=nano visudo # Uncomment line: Allow members of group wheel to execute any command %wheel ALL=(ALL) ALL
   ```
   
    **NB: This will allow the user to run sudo commands**

5. **Grub installation and rebooting**
   
    Install grub and os-prober in order to locate any other installed OS.
   
   ```bash
   pacman -S grub efibootmgr os-prober 
   ```
   
    Now edit this file and append this line to enable os detection and luks support
   
   ```bash
   grub-install --target=x86_64-efi --bootloader-id=grub_efi --recheck # Install grub
   
   nano /etc/default/grub 
   # Uncomment this line GRUB_ENABLE_CRYPTODISK=y
   
   # Change this line and replace /dev/sda4 with your root device number GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=/dev/sda4:volgroup0:allow-discards loglevel=3 quiet"
   
   # Add this at the end of the file - GRUB_DISABLE_OS_PROBER=false
   
   grub-mkconfig -o /boot/grub/grub.cfg # Generate grub config
   ```
   
    Time to reboot, fingers crossed if you did everything correctly it will boot successfully.
   
    **Goodluck**
   
   ```bash
   exit # Exit chroot environment
   reboot # Reboot the system.
   ```

6. **Finalize your installation**
   
    Login in the TTY with your user account created, not root.
   
   ```bash
   su # Change to root, enter your password, not the root.
   cd /root/
   
   # Create a swap file.
   dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress # Create a 2GB swap file. Change the count to your desired size
   
   chmod 600 /swapfile # Set permissions
   
   mkswap /swapfile # Make it a swapfile
   ```
   
    Create a backup of your filesystem file (**fstab**)
   
   ```bash
   cp /etc/fstab /etc/fstab.bak
   
   # We are going to append a line that will let the system know the swapfile existence
   
   echo "/swapfile none swap sw 0 0" | tee -a /etc/fstab # Append to fstab and echo
   
   mount -a # Test fstab for error
   swapon -a # Activate swap
   free -m # Confirm swap size
   ```

7. Configure timezone and Hostname and Hosts
   
   ```bash
   timedatectl list-timezones # Find yours 
   
   timedatectl set-timezone Asia/Hong_Kong # Replace it here
   
   systemctl enable --now systemd-timesyncd # Service for our time synchronization
   
   hostnamectl set-hostname arch # replace arch with what you like
   
   nano /etc/hosts # as follows, replace arch with what you set above
   
   # 127.0.0.1     localhost
   # 127.0.1.1     arch
   ```
   
    Install CPU microcode
   
   ```bash
   pacman -S amd-ucode # Or intel-ucode for intel device
   ```

8. Install Desktop Environment... ;)
   
   ```bash
   pacman -S xorg-server # Xorg
   pacman -S mesa # Video driver for Intel and AMD Inc.
   
   # For Nvidia GPU
   pacman -S nvidia
   
   # For VM installs guest
   pacman -S virtualbox-guest-utils xf86-vides-vmware
   systemctl enable --now vboxservice
   ```
   
    Now choose your prefered DE, WM.
   
   ```bash
   # Gnome Environment
   pacman -S gnome gnome-tweaks
   systemctl enable --now gdm.service # Enable and start Dispaly manager *GDM
   
   # KDE Plasma
   pacman -S plasma-meta kde-applications 
   systemctl enable --now sddm.service # Enable and start SDDM
   ```

9. Phew, thats it guys. 
   
   ```bash
   pacman -S neofetch
   neofetch # Show your crush now.
   ```