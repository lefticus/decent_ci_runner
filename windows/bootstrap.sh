
# exit status of 0 means nothing happened, continue as normal
# exit status of 1 means something was installed, and restarting the script is necessary
# exit status of 2 means an error occured


net session >nul 2>&1


if [ $? -eq 0 ]
then
  ISADMIN=1
else
  ISADMIN=0
fi

which choco

if [ $? -eq 0 ]
then
  HAS_CHOCO=1
else
  HAS_CHOCO=0
fi

which ruby

if [ $? -eq 0 ]
then
  HAS_RUBY=1
else
  HAS_RUBY=0
fi


which elevate

if [ $? -eq 0 ]
then
  HAS_ELEVATE=1
else
  HAS_ELEVATE=0
fi



if [ ! $HAS_CHOCO ]
then
  if [ $ISADMIN ]
  then
    echo "Installing chocolatey https://chocolatey.org"
    cmd //C "@powershell -NoProfile -ExecutionPolicy Bypass -Command \"iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))\" "
  else
    echo "You must run this process from an administrative bash console to install chocolately"
    exit 2
  fi
fi

if [ $HAS_ELEVATE -eq 0 -o $HAS_RUBY -eq 0 ]
then
  if [ $ISADMIN ]
  then
    echo "Installing the 'elevate' and 'ruby' tool https://chocolatey.org/packages/elevate.native"
    $ALLUSERSPROFILE\\chocolatey\\bin\\choco install elevate.native ruby
    exit 1
  else
    echo "You must run this process from an administrative bash console to install 'elevate' and 'ruby'"
    exit 2
  fi
fi

exit 0

