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

Run either (from a bash shell window)

```
bash <(curl https://raw.githubusercontent.com/lefticus/decent_ci_runner/master/setup_ci.sh) true true
```

*or*

```
bash <(wget -O - https://raw.githubusercontent.com/lefticus/decent_ci_runner/master/setup_ci.sh) true true
```

Depending on which (wget|curl) is available on your platform.

*Follow all instructions, including some manual installations that need to occur on some platforms and guidelines on GUI options to select.*


