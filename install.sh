#!/bin/bash

SWARM64DA_RELEASE_VERSION=4.2.0

if [[ ${1} == "--help" ]]; then
    echo "run: ./install.sh --type __acceleration_option__"
    echo "acceleration option must be one of the following:"
    echo "intel, xilinx-u50, xilinx-u200, xilinx-u250, samsung-smartssd, cpu"
    echo "e.g. ./install.sh --type intel"
    exit 0
fi

if [[ ${1} != "--type" ]]; then
    echo "Switch must be either --type or --help"
    echo
    exit 1
fi

INSTALLER_BASE_DIR=$( dirname "$(readlink -f "$0")")

case ${2} in
    "intel")
        ACCELERATION='intel'
        TARGET_DEVICE='pac-a10'
        TARGET_STRING='Intel PAC Arria10'
        ;;
    "xilinx-u50")
        ACCELERATION='xilinx'
        TARGET_DEVICE='u50'
        TARGET_STRING='Xilinx Alveo U50'
        ;;
    "xilinx-u200")
        ACCELERATION='xilinx'
        TARGET_DEVICE='u200'
        TARGET_STRING='Xilinx Alveo U200'
        ;;
    "xilinx-u250")
        ACCELERATION='xilinx'
        TARGET_DEVICE='u250'
        TARGET_STRING='Xilinx Alveo U250'
        ;;
    "samsung-smartssd")
        ACCELERATION='xilinx'
        TARGET_DEVICE='smartssd'
        TARGET_STRING='Samsung SmartSSD'
        ;;                        
    "cpu")
        ACCELERATION='cpu'
        TARGET_DEVICE='cpu'
        TARGET_STRING='Swarm64 CPU'
        ;;
    *)
        echo "Invalid option, arg intel, xilinx-u50, xilinx-u200, xilinx-u250, samsung-smartssd or cpu must be given"
        exit 1
        ;;
esac

if [[ ${3} == "--advanced" ]]; then
    echo "Running advanced mode with menu"
    ADVANCED='TRUE'
fi

function read_libs() {
    for file in lib/*.sh; do 
        if [ -f "$file" ]; then 
            . "$file"
        fi
    done
}

# Source the files in the libs directory
read_libs

# Get the tasks that will be listed individually
load_tasks

load_colours

# Show the main menu for advanced mode only
if [[ "${ADVANCED}" == "TRUE" ]]; then
    main_menu
fi
echo
echo "Running S64 DA ${SWARM64DA_RELEASE_VERSION} Installer for ${TARGET_STRING}"
echo
read_steps ${ACCELERATION}