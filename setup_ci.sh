#!/usr/bin/env bash

echo "$0 installdeps: '$1' runonboot: '$2'"

if [ `uname` == "Linux" ]
then
  RUNFILE=linux/bootstrap.sh
  RUBY=ruby2.0
  TOOL=wget
elif [ `uname` == "Darwin" ]
then
  if [ ! -d "/Applications/XCode.app" ] 
  then
    echo "You Must install XCode before continuing"
    exit 2
  fi

  RUNFILE=macos/bootstrap.sh
  RUBY=ruby
  TOOL=curl
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
        echo "Setting up rc.d Linux script"
        sudo cp decent_ci /etc/init.d/decent_ci
        sudo cp decent_ci_run.sh /usr/local/bin/decent_ci_run.sh
        if [ ! -e /usr/local/etc/decent_ci_config.yaml ]
        then 
          sudo cp decent_ci_config.yaml /usr/local/etc/decent_ci_config.yaml
        fi
        sudo update-rc.d decent_ci defaults
      elif [ `uname` == "Darwin" ]
      then
        # macos - use launchd
        echo "Setting up launchd MacOS script"
        sudo mkdir -p /usr/local/bin
        sudo mkdir -p /usr/local/etc
        sudo cp decent_ci_run.sh /usr/local/bin/decent_ci_run.sh
        if [ ! -e /usr/local/etc/decent_ci_config.yaml ]
        then 
          sudo cp decent_ci_config.yaml /usr/local/etc/decent_ci_config.yaml
        fi
        sudo cp com.emptycrate.decent_ci_runner.plist /usr/local/etc/com.emptycrate.decent_ci_runner.plist
        launchctl unload /usr/local/etc/com.emptycrate.decent_ci_runner.plist
        launchctl load /usr/local/etc/com.emptycrate.decent_ci_runner.plist
        launchctl start com.emptycrate.decent_ci_runner
      else
        # windows - install via win32
        echo "windows"
	ruby installwin32service.rb
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
  if [ `uname` == "Darwin" ]
  then
    DIR=`mktemp -d $TMPDIR/decent_ci_runner.XXXXXX`
  else
    DIR=`mktemp -d decent_ci_runner.XXXXXX`
  end

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


