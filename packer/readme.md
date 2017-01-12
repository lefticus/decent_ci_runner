
**Important Note: Currently this branch is hardcoded to use the "add_windows_packer" branch of decent_ci and decent_ci_runner. Both decent_ci_runner and decent_ci packages allow for configuring what branch is utilized, but this information is partially hardcoded, and will need to be replaced throughout the code bases when branches are tested and merged.**

**Be sure to read the [General Notes](#generalnotes) section**

This directory contains files necessary for using [packer](http://packer.io) to automatically generate build environments for MacOS, Windows and Linux.

# Currently Supported Operating Systems

 * MacOS 10.11
 * Linux Ubuntu 14.04
 * Windows 7 Enterprise

# Process

1. `cd` into this folder
2. Download the packer binary that is appropriate for your platform (Note: Packer 0.12.1 on Windows is known to have issues, Packer 0.12.0 is known to work). Also note that the packer archive should contain exactly one executable, regardless of platform.
3. Choose the operating system you want to build `<os>`
4. `cd <os>`
5. Copy an appropriate `decent_ci_config.yaml` file into current directory
  * Is `shutdown_after_run` set how you want? True if you want the VM to turn it self off after every execution because it is being managed by a vm manager script.
  * Are the security settings set how you want?
    * `--external_users`
    * `--trusted_branch`
  * Is the run_dir set to something appropriate?
6. Copy appropriate `.iso` file for base image into current directory (see [OS Specific Notes](#osspecificnotes))
7. Execute packer
  * `packer build -color=true -on-error=ask <platformname>.json`
  * If you want only vmware or only virtualbox
    * `-only=vmware-iso`
    * `-only=virtualbox-iso`
8. Wait... The result will be an artifact that should work for running the CI on the chosen platform

# <a name="generalnotes"></a>General Notes

 * Builds take a very long time to execute, in general. Be patient with them.
 * The process has an inherent volatility due to the fact that the software is installed from the Internet.
   * The setup process is robust to this volatility. Timeouts are long, and retries exist.
   * However, it is possible to expend all the retries and timeouts this is what the `-on-error=ask` command line parameter is for. In the event of a series of "too many" timeouts, you will be prompted by `packer` if you want to retry. Press `r` to retry and continue with the process.
 * Network interruption during install can lead to a successful but broken build, unfortunately.

# <a name="osspecificnotes"></a>OS Specific Notes

## Linux Ubuntu 14.04 Guest

Download [ubuntu-14.04.4-server-amd64.iso](http://releases.ubuntu.com/14.04/ubuntu-14.04.4-server-amd64.iso) to appropriate directory. 

## Windows 7 Enterprise Guest

 * Requires Windows 7 Enterprise ISO, named `en_windows_7_enterprise_with_sp1_x64_dvd_u_677651.iso`
 * You will need to provide your own Windows license
 * It would be very helpful if the Tex package could be reduced. Consider portable MikTex install instead so that requirements can be easily installed locally?
 * Be willing to “restart” when necessary (launch with -on-error=ask). See also [General Notes](#generalnotes).
 * Upgrading beyond Windows 7 could mitigate some of the time-to-build issues
 * We could consider using only the 2015 C++ Build Tools, not the entire MSVC 2015 system
 
Implementation Notes:

 * The file `Autounattend.xml` prescribes the settings and steps taken while installing Windows
 
 
## MacOS 10.11 Guest

 * Requires `Install OS X El Capitan (10.11).app` installation folder (the application folder is used to create an installation `dmg` file for building the final CI image.)
 * Execute `./prepare_iso/prepare_iso.sh -u decent_ci -p decdent_ci -D DISABLE_REMOTE_MANAGEMENT /path/to/Install\ OS\ X\ El\ Capitan\ \(10.11\).app .`
 * After the process has completed you should have the file `OSX_InstallESD_10.11.2_15C50.dmg` in the current folder, which is what packer will be looking for
 * ***When you execute packer, VMware should be possible, but the network interface has proven to be too unstable, therefore only VirtualBox is tested.***
 * ***The reboot process might be unstable, if the boot process hangs you will need to manually reboot the VM. This is fine the process is robust to it.***
 
Implementation Notes:
 
 * The process of creating a new dmg is necessary because Apple does not actually support automated / unattended installation of the OS
 * The `prepare_iso.sh` script unpacks the install ISO and configures the user name, password, and SSH and avoids any user interaction during OS install.


