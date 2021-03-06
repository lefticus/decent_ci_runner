#!/usr/bin/env bash

echo "$0 installdeps: '$1'"


if [ ! `which ruby` ]
then
  if [ "$1" == "true" ]
  then
    sudo apt-get --yes install ruby ruby2.0
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

