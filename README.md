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