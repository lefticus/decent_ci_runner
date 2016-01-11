#!/usr/bin/env bash



if [ "$#" -ne 2 ]
then
  echo "Too few arguments, expected: $0 <configfile> <installdeps>"
  exit 1
else
  echo "Configfile: '$1', onlytestsetup '$2'"
fi


if [ `uname` == "Linux" ]
then
  TOOL=curl
elif [ `uname` == "Darwin" ]
then
  TOOL=wget
else
  TOOL=curl
fi


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
    echo "Executing $BASE/run_ci.rb"
    RUBY_FILE=`mktemp`
    $TOOL $BASE/run_ci.rb > $RUBY_FILE
    ruby $RUBY_FILE $1 $2
    rm $RUBY_FILE
  else
    echo "Setup process was unable to complete, sleeping"
    sleep 300
  fi
done

