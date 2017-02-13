#!/usr/bin/env bash

echo "$0 installdeps: '$1'"


if [ ! `which ruby` ]
then
  if [ "$1" == "true" ]
  then
    lsb_release | grep "14.04"
    if [ $? -eq 0  ]
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


exit 0

