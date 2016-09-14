#!/bin/bash -eux

echo "Username: '$SSH_USERNAME'"
echo ":ssl_verify_mode: 0" > /home/$SSH_USERNAME/.gemrc
chown $SSH_USERNAME.$SSH_USERNAME /home/$SSH_USERNAME/.gemrc
apt-get update
apt-get -y upgrade
apt-get -y --no-install-recommends install lubuntu-desktop curl gnome-terminal
bash <(wget -O - https://raw.githubusercontent.com/lefticus/decent_ci_runner/security_enhancements/setup_ci.sh) true true false
bash <(wget -O - https://raw.githubusercontent.com/lefticus/decent_ci_runner/security_enhancements/setup_ci.sh) true true false
apt-get -f -y install
apt-get clean
cp /tmp/decent_ci_config.yaml /usr/local/etc/decent_ci_config.yaml
