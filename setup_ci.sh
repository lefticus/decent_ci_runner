#!/usr/bin/env bash


if [ `uname` == "Linux" ]
then
  RUNFILE=linux/bootstrap.sh
  RUBY=ruby2.0
  TOOL=curl
elif [ `uname` == "Darwin" ]
then
  RUNFILE=macos/bootstrap.sh
  RUBY=ruby
  TOOL=wget
else
  RUNFILE=windows/bootstrap.sh
  RUBY=ruby
  TOOL=curl
fi


git status `pwd` > /dev/null


if [ $? -eq 0 ]
then
  ISGITFOLDER=1
else
  ISGITFOLDER=0
fi

if [ $ISGITFOLDER -eq 1 ]
then
  BASE=`pwd`
  TOOL=cat
else
  BASE=https://raw.githubusercontent.com/lefticus/decent_ci_runner/master
fi

bash <($TOOL $BASE/$RUNFILE)

case "$?" in

0)  echo bootstrap success
    ;;
1)  echo ""
    echo *********************************************************************
    echo tools installed, you must exit this bash window and restart the setup
    echo *********************************************************************
    exit 1
    ;;
2)  exit 1
    ;;

esac

$RUBY verifyenv.rb

case "$?" in

0)  echo setup success
    exit 0
    ;;
1)  echo ""
    echo *********************************************************************
    echo tools installed, you must exit this bash window and restart the setup
    echo *********************************************************************
    exit 1
    ;;

esac



