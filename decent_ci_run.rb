#!/usr/bin/env ruby

require 'fileutils'
require 'yaml'
require 'deep_merge'
require 'rbconfig'

def manage_vm(exe, vm_command)
  command = "#{exe} #{vm_command}"
  begin
    result = `#{command}`
    puts "VM '#{command}' result: '#{result}'"

    if $?.exitstatus == 0
      return true
    else
      puts "While executing vm command: '#{command}' an error code was returned"
      return false
    end

  rescue => e
    puts "While executing vm command: '#{command}' error '#{e.to_s}'"
  end
end


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
      puts "Error setting up build folders, sleeping and trying again"
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
  system("git checkout #{config["branch_name"]}")

  FileUtils.cd(run_dir)


  if !config["virtual_machine_list"].nil?
    config["virtual_machine_list"].each { |machine|
      vmname = machine["name"]
      type = machine["type"]
      revert_snapshot = machine["revert_snapshot"]

      if vmname.nil?
        puts "vmname not specified, skipping"
        next
      end

      if type.nil?
        puts "machine type for #{vmname} not specified, skipping"
        next
      end

      if vmname == "vmware"
        exe = config["virtual_machine_vmware_executable"]
        if exe.nil?
          puts "vmware executable not specified, skipping #{vmname}"
          next
        end

        if !revert_snapshot.nil?
          if manage_vm(exe, "-T ws list").split("\n").none? { |name| File.identical?(vmname, name.strip) }
            puts "vmware #{vmname} not running, executing revert"
            manage_vm(exe, "-T ws revertToSnapshot \"#{vmname}\" \"#{revert_snapshot}\"")
          end
        end

        manage_vm(exe, "-T ws start \"#{vmname}\" \"#{revert_snapshot}\"")
      elsif vmname == "virtualbox"
        exe = config["virtual_machine_virtualbox_executable"]
        if exe.nil?
          puts "virtualbox executable not specified, skipping #{vmname}"
          next
        end

        if !revert_snapshot.nil?
          running_vm = manage_vm(exe, "list runningvms").split("\n").none? { |n|
            m = /"(?<name>.*)" {(?<uuid>.*)}/.match(n)
            return !m.nil? && m.size == 2 && (vmname == m[1] || vmname == m[2])
          }

          if !running_vm 
            manage_vm(exe, "snapshot \"#{vmname}\" restore \"#{revert_snapshot}\"")
          end
        end

        manage_vm(exe, "startvm \"#{vmname}\"")
      end
    }
  end

  if !config["virtual_machine_manager_only"]
    puts "Running ci.rb"
    if !system(merged_env, "#{RbConfig.ruby}", "#{run_dir}/decent_ci/ci.rb", *config["options"], config["test_mode"] ? "true" : "false", config["github_token"], *config["repositories"])
      puts "Unable to execute ci.rb script"
    end
  end

  if config["shutdown_after_run"]
    if RbConfig::CONFIG["target_os"] =~ /mingw|mswin/
      # windows
      `shutdown /s`
    else
      # not windows
      `sudo shutdown -h now`
    end
  end



rescue => e
  puts "Error setting up build environment #{e}"
end


