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

echo "Executing with ruby: $RUBY"
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

if [ $ISGITFOLDER -eq 1 ]
then
  echo "Executing decent_ci_runner from $BASE"
  $RUBY $BASE/verifyenv.rb $1
  COMMAND_RESULT=$?
else
  DIR=`mktemp -d`
  pushd $DIR
  echo "Checkout out decent_ci_runner to $DIR for execution"
  git clone https://github.com/lefticus/decent_ci_runner
  pushd decent_ci_runner
  $RUBY ./verifyenv.rb $1
  COMMAND_RESULT=$?
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



