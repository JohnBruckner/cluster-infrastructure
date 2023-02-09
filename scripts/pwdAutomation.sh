#!/usr/bin/bash

#vars:
# $1 IP Address
# $2 old password
# $3 new password
# $4 hostname

echo "Configuring machine at ${1}"

echo "Removing old information at : ${1}"
ssh-keygen -f ~/.ssh/known_hosts -R ${1} 

echo "Changing root password for: ${1}"
expect ~/Workspace/Homelab/scripts/changePwd.sh ${1} ${2} ${3} 

echo "Installing ssh keys for: ${1}"
expect ~/Workspace/Homelab/scripts/copyKey.sh ${1} ${3}

echo "Done: ${1}"
