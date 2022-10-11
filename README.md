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
