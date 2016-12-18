Important Note: Currently this branch is hardcoded to use the "add_windows_packer" branch of decent_ci and decent_ci_runner. This will need to be changed before merging

To build a CI image of Linux Ubuntu 14.04

 1. Copy a decent_ci_config.yaml file into this directory. It should be fully configured.
     - Recommended - set shutdown_after_run: true in the config file for automated CI management
 2. Download packer, and unzip into this directory. It should be a single executable.
 3. Download ubuntu-14.04.4-server-amd64.iso to this directory http://releases.ubuntu.com/14.04/ubuntu-14.04.4-server-amd64.iso
 4. Execute packer
     - Build both vmware and virtualbox images
       - packer build ubuntu.json
     - Build only one or the other
       - packer build -only=vmware-iso ubuntu.json
       - packer build -only=virtualbox-iso ubuntu.json
 
An artifact will be created that is an appropriate VM for Ubuntu for executing the CI.
