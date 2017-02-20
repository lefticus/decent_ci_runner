# Background

When decent_ci_runner is used to execute decent_ci (as opposed to the mode where it can be used for managing virtual machines that are running decent_ci) it first verifies that all dependencies are met before allowing decent_ci to execute.

To accomplish this:

 1. [setup_ci.sh](setup_ci.sh) is executed which launches the appropriate `bootstrap.sh` to verify the basic requirements of to continue (such as having ruby install).
   * [linux/bootstrap.sh](linux/bootstrap.sh)
   * [windows/bootstrap.sh](windows/bootstrap.sh)
   * [macos/bootstrap.sh](macos/bootstrap.sh)
 2. Once the basic requirements are verified, [verifyenv.rb](verifyenv.rb) is executed, which verifies that the full list of dependencies are met
   * Global
     * [packages.yaml](packages.yaml)
   * Linux
     * [linux/packages.yaml](linux/packages.yaml)
        * Ubuntu 14.04 [linux/packages-14.04.yaml](linux/packages-14.04.yaml)
        * Ubuntu 16.04 [linux/packages-16.04.yaml](linux/packages-16.04.yaml)
       
   * Windows
     * [windows/packages.yaml](windows/packages.yaml)
     
   * MacOS
     * [macos/packages.yaml](macos/packages.yaml)
     
These individual `packages.yaml` files are merged (global, OS, OS version) into one set of dependencies that are verified for installation.

If any requirement is not met, the execution of decent_ci is halted an a message is presented to the console.

# Updating Dependencies

 1. To update the dependencies for decent_ci, simply add, remove, or modify the dependencies as appropriate in one of the files listed above.
 2. If an addition or change is made that the current host cannot match, then the next time that the decent_ci goes to execute, the execution will hault and a message will be displayed on the console
      
      *NOTE* This might cause an interruption in services if a change is made and no human intervention is made to make sure the systems stay up to date.

# Updating the Host

## Manually Managed Hosts

Execute the [setup_ci.sh](setup_ci.sh) script on the host as explained in [README.md](README.md#common). This should update all requirements (regardless of whether or not decent_ci is currently executing).

Reboot the host and allow decent_ci to restart and continue executing.

## Hosts Created With [packer](packer.io)

If the host was created with packer you can choose:

 * Re-create the host from scratch following the instructions for building a decent_ci host with packer
 
*OR*

 * Follow the instructions for "Manually Managed Hosts" above
 
# Updating the Host Operating System Version

## Linux

### Dependencies

If a new version of Ubuntu is desired, then a new switch will need to be added to [verifyenv.rb](https://github.com/lefticus/decent_ci_runner/blob/e29c7fb0051ca7491c85d5a39fdbdf532108c5e4/verifyenv.rb#L9-L13) to handle the differing requirements between operating system versions.

### Packer Build

If it is desired to have packer be able to build a new decent_ci system image for a new version of Ubuntu (or other Debian based Linux distributions) the JSON file (for example [ubuntu-16.04.json](https://github.com/lefticus/decent_ci_runner/blob/a0c76e4ac4c47832b4d0d803787806be337c4462/packer/linux/ubuntu-16.04.json)) will need to be copied to a new file (for example [ubuntu-18.04.json]) and updated to account for new operating system changes. 

The most likely aspect of the file that will need to be updated is the `boot_command` section.

*NOTE* Be sure to update and test both the vmware and virtual box versions of the script.

## Windows

### Dependencies

It is unlikely that a change in Windows versions will require a change in dependencies, but if it does, an OS version switch (see Linux Dependencies section above) will likely need to be added, but in the Windows section of the verifyenv.rb script.

### Packer Build

If it is desired to have packer be able to build a new decent_ci system image for a new version of Windows, a new appropriate JSON file will need to be created.

After the new JSON file has been created a new [packer/windows/Autounattend.xml](packer/windows/Autounattend.xml) file will need to be created.

 * This Autounattend.xml file is a special file that windows uses to run commands during installation of the OS
 * Commands such as installing and setting up winrs will likely be fine for new versions of Windows
 * Commands such as installing hotfixes will need to be modified / updated to be appropriate. Most of them can probably just be removed.
 
 
## MacOS

### Dependencies

It is unlikely that a change in MacOS versions will require a change in dependencies, but if it does, an OS version switch (see Linux Dependencies section above) will likely need to be added, but in the MacOS section of the verifyenv.rb script.

### Packer Build

If it is desired to have packer be able to build a new decent_ci system image for a new version of MacOS, it's unknown what changes will be necessary. MacOS versions are highly volatile and do not provide any automated installation support at all.
