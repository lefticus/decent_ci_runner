#!/usr/bin/env ruby

require 'fileutils'
require 'yaml'
require 'deep_merge'

if ARGV.length < 1
  puts "Usage: #{__FILE__} <config_file>"
  abort("Not enough arguments")
end

puts "starting CI system"

begin
  puts "Loading configuration file from : '#{ARGV[0]}'"
  config = YAML.load_file("#{ARGV[0]}")


  if !config["remote_config_url"].nil?
    puts "Merging remote configuration file from : '#{config["remote_config_url"]}'"
    yml = YAML.load(`curl #{config["remote_config_url"]}`)
    config.deep_merge!(yml)
  end


  if !config["pause"].nil? and config["pause"] then
    puts "Configuration has this system paused"
    exit
  end 

  run_dir = config["run_dir"]

  if run_dir.nil? || run_dir=="" then
    puts "No run_dir configured"
    exit
  end  

  puts "Environment: #{config["environment"]}"
  merged_env = ENV.to_hash.merge(config["environment"].nil? ? Hash.new() : config["environment"])
  puts "Merged Environment: #{merged_env}"
  puts "options: #{config["options"]}"

  while true
    begin
      puts "Creating folder #{run_dir}"
      FileUtils.mkdir_p(run_dir) unless File.exists?(run_dir)
#      puts "Cleaning up old decent_ci folder"
#      FileUtils.rm_rf("#{run_dir}/decent_ci")
      puts "Changing to folder #{run_dir}"
      FileUtils.cd(run_dir)

      break
    rescue => e 
      puts "Error setting up build folders, sleeping and trying again: #{e}"
      sleep 120
    end
  end

  if File.directory?("decent_ci") 
    FileUtils.cd("decent_ci")
    while !system("git pull")
      puts "Unable to update decent_ci repository. Sleeping and trying again";
      sleep 120
    end
  else
    while !system("git clone https://github.com/lefticus/decent_ci")
      puts "Unable to clone decent_ci repository. Sleeping and trying again";
      sleep 120
    end
  end

  puts "Successfully cloned decent_ci repository."

  FileUtils.cd(run_dir)
  
  if !config["purge_build_dirs"].nil? and config["purge_build_dirs"] then
    puts "Purging Build Dirs in #{run_dir}"
    Dir.entries(run_dir).each { |entry|
      if File.directory?(entry) and entry =~ /^.+-[a-f0-9]+-.+-.+$/ then
        puts "Purging matched directory: #{entry}"
        FileUtils.remove_entry_secure(entry, true)
      end
    }
  end

  puts "Running ci.rb"
  if !system(merged_env, "#{RbConfig.ruby}", "#{run_dir}/decent_ci/ci.rb", *config["options"], config["test_mode"] ? "true" : "false", config["github_token"], *config["repositories"])
    puts "Unable to execute ci.rb script"
  end


rescue => e
  puts "Error setting up build environment #{e}"
end


