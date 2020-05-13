# Summary

The Swarm64 DA installer will assist in starting an instance of S64 DA by checking the 
system configuration, installing optional required drivers, downloading
the desired S64 DA version from the Swarm64 repository, and verifying the state of the instance.

Once the instance is up and running you can connect through a psql client or run
a benchmark using the [Swarm64 DA Benchmark Toolkit](https://github.com/swarm64/s64da-benchmark-toolkit).

Important notice: In order to guarantee compatibility between S64 DA and
s64da-compose, please checkout the GIT Tag that corresponds to your version of S64 DA. 
For example, if your version of S64 DA is 4.1.0, clone this repository and execute 
`git checkout v4.1.0` within the the repository root folder before proceeding.

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
- Pulling the docker image, starting the container, and creating a test db and table
