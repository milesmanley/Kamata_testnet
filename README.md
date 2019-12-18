# Kamata Testnet
Script needs to be ran under a non-root user with sudo privileges. It will build from source and should work on Ubuntu 16/18 and Debian 9. Use at own risk.

## Docker Instructions
After creating user enter following commands
1.  snap install docker
2.  groupadd docker
3.  usermod -aG docker USER   *Replace USER with the username you just created.*
4.  reboot
Log back in as the user and run the script posted below

User input will be prompted so have in hand the following.
1.  zelnodeprivkey
2.  Collateral txid
3.  Collateral output index usually 0/1
4.  Your ZelID for Zelflux installation

```
wget https://raw.githubusercontent.com/dk808/Kamata_testnet/master/zelnode.sh && bash -i zelnode.sh
```
