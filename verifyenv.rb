
require 'yaml'
require 'set'

yml = YAML.load_file("packages.yaml")
linux = YAML.load_file("linux/packages.yaml")

linux["packages"].concat(yml["packages"])


def execute(string)
  puts("Executing: '#{string}'")
  return `#{string}`
end

def load_apt_keys()
  keys = Set.new()

  execute("apt-key list").split("\n").each{ |keyline|
    if /pub\s+.*\/(?<id>\S+)\s+.*/ =~ keyline then
      keys << id
    end
  }

  puts("#{keys.length} keys loaded")
  return keys
end

def load_apt_sources()
  sources = Set.new()
  File.open('/etc/apt/sources.list', 'r') do |f1|  
    while line = f1.gets  
      if /^deb\s.*/ =~ line then
        sources << line.strip
      end
    end  
  end      
  puts("#{sources.length} sources loaded")
  return sources
end

def load_gem_packages()
  found_packages = []
  prev_count = 0
  ["gem", "gem2.0"].each{ |gemname| 
    execute("#{gemname} list --local").split("\n").each{ |gemline|
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

def load_apt_packages()
  found_packages = []
  execute("apt list --installed").split("\n").each{ |aptline|
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
    execute("#{pipname} list").split("\n").each{ |pipline|
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


found_packages = load_gem_packages()
found_packages.concat(load_apt_packages())
found_packages.concat(load_pip_packages())

apt_keys = load_apt_keys()
apt_sources = load_apt_sources()

# puts("Found Packages: #{found_packages}")

needed_packages = []

linux["packages"].each { |package|
  needed_packages << [package["source"], package["name"], package["version"], package["url"], package["check_file"], package["script"]]
}

to_install = []

needed_packages.each{ |needed|
  is_installed = false
  if needed[0] == "script" then
    puts("checking script object: #{needed}")
    if File.exist?(needed[4]) then
      is_installed = true
    end
  else
    found_packages.each{ |found|
      if (needed[0] == found[0] || (needed[0] == "dpkg" && found[0] == "apt")) && needed[1] == found[1] then
#        puts("needed[2]: #{needed[2]}  found[2]: #{found[2]}")
        if (needed[2] == nil || needed[2] == "" || needed[2] == found[2]) then
#          puts("#{needed[1]} FOUND!!")
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

def install_apt_sources(sources, apt_keys, apt_sources)
  did_something = false 
  sources.each { |source| 
    if !apt_keys.include?(source["id"]) then
      execute("wget -O - #{source["key"]} | sudo apt-key add -")
      did_something = true
    end

    if !apt_sources.include?(source["repository"]) then
      execute("sudo apt-add-repository '#{source["repository"]}'")
      did_something = true
    end
  }

  if did_something then
    execute("sudo apt-get update")
  end
end

install_apt_sources(linux["apt-sources"], apt_keys, apt_sources)

def install_apt(to_install)
  apt_string = "sudo apt-get --yes install "
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
    execute("echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections")
    execute("echo ttf-mscorefonts-installer msttcorefonts/present-mscorefonts-eula note | sudo debconf-set-selections")
    puts(execute("#{apt_string}"))
  else
    puts("No apt packages to install")
  end
end

install_apt(to_install)

def install_dpkg(to_install)
  to_install.each{ |package| 
    if package[0] == "dpkg" then
      puts(execute("URL='#{package[3]}'; FILE=`mktemp`; wget \"$URL\" -qO $FILE && sudo dpkg -i $FILE; rm $FILE"))
    end
  }  
end

install_dpkg(to_install)

def install_script(to_install)
  to_install.each{ |package|
    if package[0] == "script" then
      puts(execute(package[5]))
    end
  }
end

install_script(to_install)


def install_gem_pip(to_install)

  ["gem", "gem2.0", "pip", "pip2"].each{ |gemname| 
    gem_string = "sudo #{gemname} install "
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
  
install_gem_pip(to_install)


