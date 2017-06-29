#!/usr/bin/env bash

echo "$0 configfile: '$1' installdeps: '$2' runonboot: '$3'"

CONFIG_FILE=$1
INSTALL_DEPS=$2
RUN_ON_BOOT=$3

if [ "$CONFIG_FILE" == "" ]
then
  echo "Expected: '$0 configfile installdeps runonboot"
  exit -1
fi

if [ `uname` == "Linux" ]
then
  RUNFILE=linux/bootstrap.sh
  RUBY=ruby
  TOOL="wget -O -"
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
bash <($TOOL $BASE/$RUNFILE) $INSTALL_DEPS

case "$?" in

0)  echo bootstrap success
    ;;
1)  echo ""
    echo "******************************************************************************"
    echo bootstrap tools installed, you must exit this bash window and restart the setup
    echo "******************************************************************************"
    exit 1
    ;;
2)  exit 1
    ;;

esac



function runonboot  {

  PREVIOUS_SUCCESS=$1
  DO_RUN_ON_BOOT=$2
  CONFIG_FILE=$3

  echo "runonboot '$PREVIOUS_SUCCESS' '$DO_RUN_ON_BOOT' '$CONFIG_FILE'"
  if [ $PREVIOUS_SUCCESS -eq 0 ]
  then
    if [ "$DO_RUN_ON_BOOT" == "true" ]
    then
      if [ `uname` == "Linux" ]
      then
        # linux - rc script
        echo "Setting up rc.d Linux script"
        sudo cp decent_ci /etc/init.d/decent_ci
        sudo cp decent_ci_run.sh /usr/local/bin/decent_ci_run.sh
        if [ ! -e /usr/local/etc/decent_ci_config.yaml ]
        then 
          sudo cp $CONFIG_FILE /usr/local/etc/decent_ci_config.yaml
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
          sudo cp $CONFIG_FILE /usr/local/etc/decent_ci_config.yaml
        fi

        PLIST=`mktemp plist.XXXXXX`
        echo "<?xml version='1.0' encoding='UTF-8'?>" > $PLIST
        echo "<!DOCTYPE plist PUBLIC '-//Apple//DTD PLIST 1.0//EN' 'http://www.apple.com/DTDs/PropertyList-1.0.dtd'>" >> $PLIST
        echo "<plist version='1.0'>" >> $PLIST
        echo "  <dict>" >> $PLIST
        echo "    <key>Label</key>" >> $PLIST
        echo "    <string>com.emptycrate.decent_ci_runner</string>" >> $PLIST
        echo "    <key>ProgramArguments</key>" >> $PLIST
        echo "    <array>" >> $PLIST
        echo "      <string>/usr/local/bin/decent_ci_run.sh</string>" >> $PLIST
        echo "      <string>/usr/local/etc/decent_ci_config.yaml</string>" >> $PLIST
        echo "      <string>false</string>" >> $PLIST
        echo "    </array>" >> $PLIST
        echo "    <key>RunAtLoad</key>" >> $PLIST
        echo "    <true/>" >> $PLIST
#        echo "    <key>StandardOutPath</key>" >> $PLIST
#        echo "    <string>/Users/jason/stdout</string> " >> $PLIST   
        echo "    <key>WorkingDirectory</key>" >> $PLIST
        echo "    <string>$HOME</string>" >> $PLIST
        echo "    <key>UserName</key>" >> $PLIST
        echo "    <string>$USER</string>" >> $PLIST
        echo "    <key>EnvironmentVariables</key>" >> $PLIST
        echo "    <dict>" >> $PLIST
        echo "      <key>PATH</key>" >> $PLIST
        echo "      <string>$PATH</string>" >> $PLIST
        echo "    </dict>" >> $PLIST
        echo "    <key>KeepAlive</key>" >> $PLIST
        echo "    <true/>" >> $PLIST
        echo "  </dict>" >> $PLIST
        echo "</plist>" >> $PLIST

        sudo cp $PLIST /Library/LaunchDaemons/com.emptycrate.decent_ci_runner.plist
 
        rm $PLIST

        launchctl unload /Library/LaunchDaemons/com.emptycrate.decent_ci_runner.plist
        launchctl load /Library/LaunchDaemons/com.emptycrate.decent_ci_runner.plist
#        launchctl start com.emptycrate.decent_ci_runner
      else
        # windows - install via win32
        echo "windows"
        mkdir "c:\\decent_ci_runner"

        if [ ! -e "c:\\decent_ci_runner\\decent_ci_config.yaml" ]
        then 
          cp $CONFIG_FILE "c:\\decent_ci_runner\\decent_ci_config.yaml"
        fi

        copy decent_ci_run.sh c:\\decent_ci_runner\\decent_ci_run.sh
        elevate nssm install decent_ci_runner "c:\\Program Files\\Git\\bin\\bash.exe" "c:\\decent_ci_runner\\decent_ci_run.sh" "c:\\decent_ci_runner\\decent_ci_config.yaml" false
      fi
      
      echo "**************************************************************************"
      echo Run on boot service set up - you need to configure your yaml and reboot!!
      echo "**************************************************************************"

    fi
  fi
}

if [ $ISGITFOLDER -eq 1 ]
then
  echo "Executing decent_ci_runner from $BASE"
  $RUBY $BASE/verifyenv.rb $CONFIG_FILE $INSTALL_DEPS
  COMMAND_RESULT=$?
  runonboot $COMMAND_RESULT $RUN_ON_BOOT
else
  if [ `uname` == "Darwin" ]
  then
    DIR=`mktemp -d $TMPDIR/decent_ci_runner.XXXXXX`
  else
    DIR=`mktemp --tmpdir -d decent_ci_runner.XXXXXX`
  fi

  pushd $DIR
  echo "Checkout out decent_ci_runner to $DIR for execution"
  git clone https://github.com/lefticus/decent_ci_runner
  pushd decent_ci_runner
  $RUBY ./verifyenv.rb $CONFIG_FILE $INSTALL_DEPS
  COMMAND_RESULT=$?
  echo "Result of verifyenv.rb: $COMMAND_RESULT"
  runonboot $COMMAND_RESULT $RUN_ON_BOOT
  popd
  popd
  echo "Removing $DIR"
  rm -rf $DIR
fi


case "$COMMAND_RESULT" in

0)  echo setup success
    exit 0
    ;;
1)  echo ""
    echo "**************************************************************************"
    echo setup tools installed, you must exit this bash window and restart the setup
    echo "**************************************************************************"
    exit 1
    ;;

esac



