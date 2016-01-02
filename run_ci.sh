

if [ `uname` -eq "Linux" ]
then
  linux/bootstrap.sh
  RUBY=ruby2.0
elsif [ `uname` -eq "Darwin" ]
  macos/bootstrap.sh
  RUBY=ruby
else
  windows/bootstrap.sh
  RUBY=ruby
end

$RUBY verifyenv.rb

