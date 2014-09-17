#!/usr/bin/env ruby

require 'fileutils'

if ARGV.length < 4
  puts "Usage: #{__FILE__} [options] <buildfolder> <testruntrueorfalse> <githubtoken> <repositoryname> (<repositoryname> ...)"
  abort("Not enough arguments")
end

puts "starting CI system"


while true
  begin 
    puts "Creating folder #{ARGV[0]}"
    FileUtils.mkdir_p(ARGV[0])
    puts "Cleaning up old decent_ci folder"
    FileUtils.rm_rf("#{ARGV[0]}/decent_ci")
    puts "Changing to folder #{ARGV[0]}"
    FileUtils.cd(ARGV[0])

    break
  rescue => e 
    puts "Error setting up build folders, sleeping and trying again"
    sleep 120
  end
end

while !system("git clone https://github.com/lefticus/decent_ci")
  puts "Unable to clone decent_ci repository. Sleeping and trying again";
  sleep 120
end

puts "Successfully cloned decent_ci repository."

while true
  puts "Updating decent_ci"
  if system("cd decent_ci && git pull")
    puts "Running ci.rb"
    ci_args = ARGV[1..-1]
    if !system("#{RbConfig.ruby}", "decent_ci/ci.rb", *ci_args)
      puts "Unable to execute ci.rb script"
    end
  else
    puts "Unable to update decent_ci repository"
  end

  puts "Sleeping"
  sleep(300)
end

