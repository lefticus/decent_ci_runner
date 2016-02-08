#!/usr/bin/env bash



if [ "$#" -ne 2 ]
then
  echo "Wrong number arguments, expected: $0 <configfile> <installdeps>"
  exit 1
else
  echo "Configfile: '$1', onlytestsetup '$2'"
fi


TOOL=curl


git status `pwd` > /dev/null

if [ $? -eq 0 ]
then
  echo "Running from git folder"
  BASE=`pwd`
  TOOL=cat
else
  echo "NOT Running from git folder"
  BASE=https://raw.githubusercontent.com/lefticus/decent_ci_runner/master
fi


while [ 0 ]
do
  echo "Executing setup_ci.sh"
  bash <($TOOL $BASE/setup_ci.sh) $2

  if [ $? -eq 0 ]
  then
    echo "Executing $BASE/decent_ci_run.rb"
    echo "Running in: `pwd`"

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

