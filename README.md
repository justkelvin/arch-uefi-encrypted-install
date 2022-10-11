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