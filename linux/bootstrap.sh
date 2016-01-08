#!/usr/bin/env bash

if [ ! `which ruby` ]
then
  sudo apt-get install ruby2.0
fi

if [ ! `which git` ]
then
  sudo apt-get install git
fi


return 0

