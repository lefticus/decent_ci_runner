After installation of this tool the CI will be set up to run on boot on all 3 platforms.

You will need to edit the appropriate configuration file and reboot the system for the CI to 
run as expected.

Be sure to read and follow all prompts during the installation process.

Windows
=======

Install git-bash: https://git-for-windows.github.io/

***NOTE GIT-BASH MUST BE INSTALLED IN PROGRAM FILES DIRECTORY. THIS MAY REQUIRE YOU TO INSTALL IT AS ADMIN***

Common
======


*Do you want to run a build system or do you want to run manage build VMs?*

> By setting the final parameter "true" when setting up, you are electing to install
> only the most basic dependencies, not everything required to run the full CI

Run either (from a bash shell window)

```
bash <(curl https://raw.githubusercontent.com/lefticus/decent_ci_runner/master/setup_ci.sh) true true <vm manager only? true|false>
```

*or*

```
bash <(wget -O - https://raw.githubusercontent.com/lefticus/decent_ci_runner/master/setup_ci.sh) true true <vm manager only? true|false>
```

Depending on which (wget|curl) is available on your platform.

*Follow all instructions, including some manual installations that need to occur on some platforms and guidelines on GUI options to select.*


VM MANAGER MODE
===============

In VM Manager Mode (a properly configured `virtual_machine_list` key, see also [sample_configs](sample_configs/vm_manager)), the system
loops over the list of virtual machines. For each machine it:

 1. Checks to see if machine is running
 2. If it is not running
    * Reset to snapshot (if configured)
    * Start virtual machine
 3. Sleep
 4. Goto 1.

