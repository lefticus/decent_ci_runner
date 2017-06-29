require 'yaml'
require 'set'
require 'tempfile'
require 'net/http'
require 'openssl'

puts("Disabling SSL certificate verification due to client requirements")
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE # warning: already initialized constant VERIFY_PEER


install_deps = ARGV[1] == "true"
config_file = ARGV[0]

puts("Loading config file '#{config_file}'");

config_file_yml = YAML.load_file(config_file)

is_linux = false
is_windows = false
is_macos = false

if /.*linux.*/i =~ RUBY_PLATFORM 
  is_linux = true
  SUDO_TOOL="sudo"
  GEM_NEEDS_SUDO=true
  PIP_NEEDS_SUDO=true
  run_apt = true
  run_choco = false
elsif /.*darwin.*/i =~ RUBY_PLATFORM
  is_macos = true
  SUDO_TOOL="sudo"
  GEM_NEEDS_SUDO=true
  PIP_NEEDS_SUDO=true
  run_apt = false
  run_choco = false
else
  is_windows = true
  SUDO_TOOL="elevate -c -w "
  GEM_NEEDS_SUDO=false
  PIP_NEEDS_SUDO=false
  run_apt = false
  run_choco = true
  ENV["PATH"] = "#{ENV["PATH"]};C:\\tools\\python2\\Scripts;C:\\Python27\\Scripts"
end


package_paths = [""]
if config_file_yml.include?("extra_packages_paths")
  config_file_yml["extra_packages_paths"].each { |path|
    package_paths << path
    puts("Loading extra packages from: #{path}")
  }
else
  puts("No extra packages locations specified in the config file")
end


def concat(dest, src)
  dest["packages"].concat(src["packages"]) if src && src.include?("packages")
  dest["apt-sources"].concat(src["apt-sources"]) if src && src.include?("apt-sources")
end

def load_yaml(package_path, filename)
  puts ("loading yaml from: '#{package_path}'/'#{filename}'")
  begin
    if package_path.empty?
      return YAML.load_file(filename);
    elsif package_path.start_with? "http"
      return YAML.load(Net::HTTP.get(URI("#{package_path}/#{filename}")))
    else
      return YAML.load_file("#{package_path}/#{filename}");
    end
  rescue EOFError
    puts ("YAML contained no data")
    return {}
  end
end

config = {"packages"=>[], "apt-sources"=>[]}

package_paths.each{ |package_path| 
  puts("Processing package path: #{package_path}")
  concat(config, load_yaml(package_path, "packages.yaml"))

  if is_linux
    concat(config, load_yaml(package_path, "linux/packages.yaml"))
  elsif is_macos
    concat(config, load_yaml(package_path, "macos/packages.yaml"))
  else
    concat(config, load_yaml(package_path, "windows/packages.yaml"))
  end
}

puts(config)

needed_packages = []

config["packages"].each { |package|
  if package["check_file"].kind_of?(Array) then
    check_files = package["check_file"]
  else
    check_files = [package["check_file"]]
  end

  needed_packages << [package["source"], package["name"], package["version"], package["url"], check_files, package["script"], package["message"], package["package_parameters"]]
}


def execute(string, critical=true)
  puts("Executing: '#{string}'")
  begin 
    result = `#{string}`
    return result
  rescue => e
    if critical then
      raise
    else
      puts("Error during execution: #{e}")
      return ""
    end
  end
end

def show_message(string)
  execute("echo \"\" | powershell -C \"[System.Reflection.Assembly]::LoadWithPartialName(\\\"System.Windows.Forms\\\"); [System.Windows.Forms.MessageBox]::Show(\\\"#{string}\\\") ")
end

def load_apt_keys()
  keys = Set.new()

  execute("apt-key list", false).split("\n").each{ |keyline|
    if /pub\s+.*\/(?<id>\S+)\s+.*/ =~ keyline then
      keys << id
    end
  }

  puts("#{keys.length} keys loaded")
  return keys
end

def load_apt_sources()
  sources = Set.new()

  begin
    File.open('/etc/apt/sources.list', 'r') do |f1|  
      while line = f1.gets  
        if /^deb\s.*/ =~ line then
          sources << line.strip
        end
      end  
    end
  rescue
    # I guess it doesn't exist...
  end
  puts("#{sources.length} sources loaded")
  return sources
end

def load_gem_packages()
  found_packages = []
  prev_count = 0
  ["gem", "gem2.0"].each{ |gemname| 
    execute("#{gemname} list --local", false).split("\n").each{ |gemline|
      if /(?<name>^[a-zA-Z0-9.+_-]+) \((?<version>[0-9.]+)\)/ =~ gemline then
        found_packages << [gemname, name, version]
      else
        puts("Unparsed line: #{gemline}")
      end
    }
    puts("#{found_packages.length - prev_count} #{gemname} modules found")
    prev_count = found_packages.length
  }
  return found_packages
end

def load_choco_packages()
  found_packages = []
  execute("choco list -lo", false).split("\n").each{ |chocoline|
    if /(?<name>^[a-zA-Z0-9.+_-]+) (?<version>[0-9.]+)/ =~ chocoline then
      found_packages << ['choco', name, version]
    else
      puts("Unparsed line: #{chocoline}")
    end
  }
  puts("#{found_packages.length} choco packages found")
  return found_packages
end


def load_apt_packages()
  found_packages = []
  execute("apt list --installed", false).split("\n").each{ |aptline|
#    puts("'#{aptline}'")
    if /(?<name>^[a-zA-Z0-9.+_-]+)\/(?<source>\S*) ([0-9]+:)?(?<version>[0-9.]+).*/ =~ aptline then
#      puts("'#{aptline}': '#{name}' '#{source}' '#{version}'")
      found_packages << ['apt', name, version]
    else
      puts("Unparsed line: #{aptline}")
    end
  }
  puts("#{found_packages.length} apt packages found")
  return found_packages
end

def load_pip_packages()
  found_packages = []
  prev_count = 0
  ["pip", "pip2"].each{ |pipname| 
    execute("#{pipname} list", false).split("\n").each{ |pipline|
      if /(?<name>^[a-zA-Z0-9.+_-]+) \((?<version>[0-9.]+).*\)/ =~ pipline then
        found_packages << [pipname, name, version]
      else
        puts("Unparsed line: #{pipline}")
      end
    }
    puts("#{found_packages.length - prev_count} #{pipname} modules found")
    prev_count = found_packages.length
  }
  return found_packages
end



def install_apt_sources(sources, apt_keys, apt_sources)
  did_something = false 
  if sources == nil then
    return
  end

  sources.each { |source| 
    if !apt_keys.include?(source["id"]) then
      execute("wget -O - #{source["key"]} | #{SUDO_TOOL} apt-key add -")
      did_something = true
    end

    if !apt_sources.include?(source["repository"]) then
      execute("#{SUDO_TOOL} apt-add-repository '#{source["repository"]}'")
      did_something = true
    end
  }

  if did_something then
    execute("#{SUDO_TOOL} apt-get update")
  end
end

def install_apt(to_install)
  apt_string = "#{SUDO_TOOL} apt-get --yes install "
  something_to_do = false
  to_install.each{ |package| 
    if package[0] == "apt" then
      something_to_do = true
      apt_string += package[1]
      if package[2] != nil then
        apt_string += "=#{package[2]}"
      end
      apt_string += " "
    end
  }  

  if something_to_do then
    # we need to pre-accept the mscorefont eula to be able to install this automagically
    execute("echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | #{SUDO_TOOL} debconf-set-selections")
    execute("echo ttf-mscorefonts-installer msttcorefonts/present-mscorefonts-eula note | #{SUDO_TOOL} debconf-set-selections")
    puts(execute("#{apt_string}"))
  else
    puts("No apt packages to install")
  end
end

def install_dpkg(to_install)
  to_install.each{ |package| 
    if package[0] == "dpkg" then
      puts(execute("URL='#{package[3]}'; FILE=`mktemp`; wget \"$URL\" -qO $FILE && #{SUDO_TOOL} dpkg -i $FILE; rm $FILE"))
    end
  }  
end

def install_script(to_install)
  to_install.each{ |package|
    if package[0] == "script" then
      if !package[6].nil? then
        show_message(package[6])
      end

      puts(execute(package[5]))
    end
  }
end

def install_choco(to_install)
  Tempfile.create(["packages", ".config"]) { |file|
    file.write("<?xml version='1.0' encoding='utf-8'?>\n")
    file.write("<packages>\n")
    something_to_do = false
    to_install.each{ |package| 
      if package[0] == "choco" then
        something_to_do = true
        file.write("<package id='" + package[1] + "'")
        if package[2] != nil then
          file.write(" version='" + package[2] + "'")
        end
        if package[7] != nil then
          file.write(" packageParameters='" + package[7] + "'")
        end
        file.write(" />\n")
      end
    }
    file.write("</packages>\n");
    file.close()

    if something_to_do then
      puts(execute("#{SUDO_TOOL} choco install --yes --acceptlicense #{file.path}"))
    end
  }
end

def install_gem_pip(to_install)

  ["gem", "gem2.0", "pip", "pip2"].each{ |gemname| 
    if GEM_NEEDS_SUDO || PIP_NEEDS_SUDO then
      gem_string = SUDO_TOOL
    else 
      gem_string = ""
    end

    gem_string = "#{gem_string} #{gemname} install "
    something_to_do = false
    to_install.each{ |package| 
      if package[0] == gemname then
        something_to_do = true
        gem_string += package[1]
        if package[2] != nil then
          gem_string += "=#{package[2]}"
        end
        gem_string += " "
      end
    } 
    if something_to_do then
      puts(execute("#{gem_string}"))
    else
      puts("No #{gemname} packages to install")
    end
  } 

end

  
found_packages = load_gem_packages()

if run_apt
  found_packages.concat(load_apt_packages())
end

found_packages.concat(load_pip_packages())

if run_choco
  found_packages.concat(load_choco_packages())
end

to_install = []

needed_packages.each{ |needed|
  is_installed = false
  if needed[0] == "script" then
    print("checking script object: #{needed[1]}... ")

    is_installed = needed[4].all? { |filename| File.exist?(filename) }

    if is_installed then
      puts("FOUND")
    else
      puts("NOT FOUND")
    end
  else
    found_packages.each{ |found|
      if (needed[0] == found[0] || (needed[0] == "dpkg" && found[0] == "apt")) && needed[1] == found[1] then
        if (needed[2] == nil || needed[2] == "" || needed[2] == found[2]) then
          is_installed = true
          break
        end
      end
    }
  end

  if !is_installed then
    to_install << needed
  end
}


if !to_install.empty? and !install_deps
  puts "Dependency installation disabled, exiting"
  puts "Missing packages: #{to_install}"
  exit 1
end

if run_apt
  apt_keys = load_apt_keys() 
  apt_sources = load_apt_sources() 
  install_apt_sources(config["apt-sources"], apt_keys, apt_sources) 
  install_apt(to_install)
  install_dpkg(to_install)
end

if run_choco
  install_choco(to_install)
end

install_script(to_install)
install_gem_pip(to_install)

if !to_install.empty? then
  puts "Something was installed, you must restart from a new console"
  exit 1
else
  exit 0
end

