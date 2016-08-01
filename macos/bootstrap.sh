#!/usr/bin/env bash

echo "$0 installdeps: '$1'"


command -v qmake

if [ $? -eq 0 ]
then
  echo "qt is installed"
else
  echo "******************************************************"
  echo "You must install Qt and add its binaries to your path!"
  echo "******************************************************"
  exit 1
fi



command -v pip

if [ $? -eq 0 ]
then
  echo "pip is installed"
else
  if [ "$1" == "true" ]
  then
    echo "Installing pip"
    sudo easy_install pip 
    if [ $? -eq 0 ]
    then
      exit 0
    else
      exit 1
    fi
  else
    echo "******************************************************"
    echo "Pip is not installed and installdeps != true"
    echo "******************************************************"
    exit 1
  fi
fi

if [ ! `sudo grep -q  "%users localhost=/sbin/shutdown -h now" /etc/sudoers` ]
then
  sudo sh -c "echo \"%users localhost=/sbin/shutdown -h now\" >> /etc/sudoers"
fi




exit 0

