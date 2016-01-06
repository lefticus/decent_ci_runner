

if [ `uname` == "Linux" ]
then
  linux/bootstrap.sh
  RUBY=ruby2.0
elif [ `uname` == "Darwin" ]
then
  macos/bootstrap.sh
  RUBY=ruby
else
  windows/bootstrap.sh
  RUBY=ruby
fi

$RUBY verifyenv.rb

