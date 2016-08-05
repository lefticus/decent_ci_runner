#!/bin/bash -eux

echo "==> Installing VirtualBox Tools"

mkdir /tmp/vbox
mount -o loop /home/${SSH_USERNAME}/VBoxGuestAdditions.iso /tmp/vbox
cd /tmp/vbox
./VBoxLinuxAdditions.run
rm /home/${SSH_USERNAME}/*.iso

echo "==> Installed VirtualBox Tools"

