#!/usr/bin/env bash

BRANCH_NAME=security_enhancements

echo "Running as `whoami`"
ISWINDOWS=0
if [ `uname` == "Linux" ]
then
  if [ `whoami` == "root" ]
  then
    ISADMIN=1
  else
    ISADMIN=0
  fi
elif [ `uname` == "Darwin" ]
then
  if [ `whoami` == "root" ]
  then
    ISADMIN=1
  else
    ISADMIN=0
  fi
else
  ISWINDOWS=1
  net session >/dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "IS ADMIN"
    ISADMIN=1
  else
    ISADMIN=0
  fi
fi


if [ "$#" -lt 2 ]
then
  echo "Wrong number arguments, expected: $0 <configfile> <installdeps> [<bootstrap deps only>]"
  exit 1
else
  if [ "$3" != "true" ]
  then
    BOOTSTRAP_DEPS_ONLY="false"
  else
    BOOTSTRAP_DEPS_ONLY="true"
  fi

  echo "Configfile: '$1', installdeps '$2', bootstrap_deps_only '$BOOTSTRAP_DEPS_ONLY'"
fi


#unfortunately required for firewalled hosts
TOOL="curl -k"


git status `pwd` > /dev/null

if [ $? -eq 0 ]
then
  echo "Running from git folder"
  BASE=`pwd`
  TOOL=cat
else
  echo "NOT Running from git folder"
  BASE=https://raw.githubusercontent.com/lefticus/decent_ci_runner/$BRANCH_NAME
fi


while [ 0 ]
do
  echo "Executing setup_ci.sh"
  bash <($TOOL $BASE/setup_ci.sh) $2 false $BOOTSTRAP_DEPS_ONLY

  if [ $? -eq 0 ]
  then
    echo "Executing $BASE/decent_ci_run.rb"
    echo "Running in: `pwd`"


    if [ $ISADMIN -eq 1 ]
    then
      if [ $ISWINDOWS -eq 0 ]
      then
        echo "Refusing to continue with process, cannot run as admin/root"
        exit 1;
      fi
    fi


    if [ `uname` == "Darwin" ]
    then
      RUBY_FILE=`mktemp $TMPDIR/decent_ci_run.rb.XXXXXX`
    else
      RUBY_FILE=`mktemp --tmpdir decent_ci_run.rb.XXXXXX`
    fi

    $TOOL $BASE/decent_ci_run.rb > $RUBY_FILE
    echo "Attempting to run $RUBY_FILE"
    ruby $RUBY_FILE $1 $2
    rm $RUBY_FILE
    echo "Build finished, sleeping"
  else
    echo "Setup process was unable to complete, sleeping"
  fi

  sleep 300
done

