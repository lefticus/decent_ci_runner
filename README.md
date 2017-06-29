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

Edit a configuration file that matches your requirements, starting from https://github.com/lefticus/decent_ci_runner/blob/split_requirements/decent_ci_config.yaml and place it in an accessible location.

Run either (from a bash shell window)

```
bash <(curl https://raw.githubusercontent.com/lefticus/decent_ci_runner/split_requirements/setup_ci.sh) <fullpathtoconfigfile> true true
```

*or*

```
bash <(wget -O - https://raw.githubusercontent.com/lefticus/decent_ci_runner/split_requirements/setup_ci.sh) <fullpathtoconfigfile> true true
```

Depending on which (wget|curl) is available on your platform.

*Follow all instructions, including some manual installations that need to occur on some platforms and guidelines on GUI options to select.*


