#!/usr/bin/env bash

echo "$0 installdeps: '$1'"


if [ ! `which ruby` ]
then
  if [ "$1" == "true" ]
  then
    if [ `lsb_release | grep "14.04"` ]
    then
      # this is ubuntu 14.04, install ruby and ruby2.0
      sudo apt-get --yes install ruby ruby2.0
    else
      # this is later than ubuntu 14.04, install ruby only
      sudo apt-get --yes install ruby
    fi
  else
    exit 1
  fi
fi

if [ ! `which git` ]
then
  if [ "$1" == "true" ]
  then
    sudo apt-get --yes install git
  else
    exit 1
  fi
fi


if [ "$2" == "" ]
then
  echo "User not known - unable to update sudoers file"
  exit 1
fi

sudo grep -q  "$2.*NOPASSWD.*poweroff.*shutdown.*" /etc/sudoers

if [ $? -eq 1 ]
then
  sudo sh -c "echo \"$2 ALL=(ALL) NOPASSWD: /sbin/poweroff, /sbin/reboot, /sbin/shutdown\" >> /etc/sudoers"
fi

exit 0

