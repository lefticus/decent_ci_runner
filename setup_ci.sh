#!/usr/bin/env bash

echo "$0 installdeps: '$1' runonboot: '$2'"

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

echo "Executing with ruby: $RUBY"
git status `pwd` > /dev/null


if [ $? -eq 0 ]
then
  echo "Running from git folder"
  ISGITFOLDER=1
else
  echo "NOT Running from git folder"
  ISGITFOLDER=0
fi

if [ $ISGITFOLDER -eq 1 ]
then
  BASE=`pwd`
  TOOL=cat
else
  BASE=https://raw.githubusercontent.com/lefticus/decent_ci_runner/master
fi

echo "executing: '$TOOL $BASE/$RUNFILE'"
bash <($TOOL $BASE/$RUNFILE) $1

case "$?" in

0)  echo bootstrap success
    ;;
1)  echo ""
    echo "*********************************************************************"
    echo tools installed, you must exit this bash window and restart the setup
    echo "*********************************************************************"
    exit 1
    ;;
2)  exit 1
    ;;

esac



function runonboot  {
  echo "runonboot '$1' '$2'"
  if [ $1 -eq 0 ]
  then
    if [ "$2" == "true" ]
    then
      if [ `uname` == "Linux" ]
      then
        # linux - rc script
        sudo cp decent_ci /etc/init.d/decent_ci
        sudo update-rc.d decent_ci defaults
        sudo ln -s /etc/init.d/decent_ci /etc/rc5.d/decent_ci
      elif [ `uname` == "Darwin" ]
      then
        # macos - use launchd
        echo "macos"
      else
        # windows - install via win32
        echo "windows"
      fi
    fi
  fi
}

if [ $ISGITFOLDER -eq 1 ]
then
  echo "Executing decent_ci_runner from $BASE"
  $RUBY $BASE/verifyenv.rb $1
  COMMAND_RESULT=$?
  runonboot $COMMAND_RESULT $2
else
  DIR=`mktemp -d`
  pushd $DIR
  echo "Checkout out decent_ci_runner to $DIR for execution"
  git clone https://github.com/lefticus/decent_ci_runner
  pushd decent_ci_runner
  $RUBY ./verifyenv.rb $1
  COMMAND_RESULT=$?
  runonboot $COMMAND_RESULT $2
  popd
  popd
  rm -rf $DIR
fi


case "$COMMAND_RESULT" in

0)  echo setup success
    exit 0
    ;;
1)  echo ""
    echo "*********************************************************************"
    echo tools installed, you must exit this bash window and restart the setup
    echo "*********************************************************************"
    exit 1
    ;;

esac



