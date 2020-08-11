# Deprecation Notice

This tool is deprecated and will not be further maintained.

# Summary

The Swarm64 DA installer will assist in starting an instance of S64 DA by checking the 
system configuration, installing optional required drivers, downloading
the desired S64 DA version from the Swarm64 repository, and verifying the state of the instance.

Once the instance is up and running you can connect through a psql client or run
a benchmark using the [Swarm64 DA Benchmark Toolkit](https://github.com/swarm64/s64da-benchmark-toolkit).

Important notice: In order to guarantee compatibility between S64 DA and
s64da-installer, please checkout the GIT Tag that corresponds to your version of S64 DA. 
For example, if your version of S64 DA is 4.2.0, clone this repository and execute
`git checkout v4.2.0` within the the repository root folder before proceeding.

# Prerequisites

- Docker and Docker-Compose
- Centos/RHEL 7 (>=7.4)
- A valid S64 DA license copied to `./config/license/s64da.license`. Replace the existing dummy file.
  If you don't have a license file yet request one by contacting support@swarm64.com.
- For FPGA targets: All FPGA(s) must be setup with their Shells (the part on the FPGA)
- Consult the Swarm64 DA user guide or contact support@swarm64.com for more information

# Launch a Swarm64 DA Instance

It is recommended to run ```yum update``` before executing the Swarm64 DA installer.

Run the ```install.sh``` script in the top level directory.
You need to include a switch to signal which type of accelerator is to be used. <br />
```sudo ./install.sh --type intel``` for intel PAC Arria 10 <br />
```sudo ./install.sh --type xilinx-u50``` for Xilinx U50 <br />
```sudo ./install.sh --type xilinx-u200``` for Xilinx U200 <br />
```sudo ./install.sh --type xilinx-u250``` for Xilinx U250 <br />
```sudo ./install.sh --type cpu``` for the CPU accelerated version <br />

Note: The ```install.sh``` script must be run with sudo rights

# Additional information

The individual steps are scripts in ```./lib```:
- Checking that the pre-requisite OS and software are installed
- Getting and checking user credentials to connect to the Swarm64 repository
- Checking for FPGAs if applicable
- Downloading and installing the FPGA drivers if applicable
- Editing the PostgreSQL configuration file through a docker-compose env file
- Editing the docker-compose file to be used
- Editing the sysctl file to be loaded
- Pulling the docker image, starting the container, loading the license, and creating a test db
