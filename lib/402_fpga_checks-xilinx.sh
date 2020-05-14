#!/bin/bash

function check_xilinx_device_files_init {
    LS='ls'
    XBUTIL=/opt/xilinx/xrt/bin/xbutil
    XBMGMT=/opt/xilinx/xrt/bin/xbmgmt

    FPGAS_TOTAL=$($XBUTIL scan | grep -Eo 'Found total [0-9]+' | grep -Eo [0-9]+)
    FPGAS_USABLE=$($XBUTIL scan | grep -Eo '[0-9]+ are usable' | grep -Eo [0-9]+)

    DEVICES_LIST=( $(ls /dev/xclmgmt* )) 2>>${LOG}
    DEVICES_PORT_LIST=( $(ls /dev/dri/renderD* )) 2>>${LOG}
    
    LEN_DEVICES_LIST=${#DEVICES_LIST[@]}
    LEN_PORT_LIST=${#DEVICES_PORT_LIST[@]}
    
}


function check_xilinx_device_files {
    if [[ ${LEN_DEVICES_LIST} -lt 1 ]]; then
        log_error "Can't find xclmgmt entries in /dev. Reboot and re-run the installer"
        return 1
    fi

    if [[ ${LEN_PORT_LIST} -lt 1 ]]; then
        log_error "Can't find any entries in /dev/dri. Reboot and re-run the installer"
        return 2
    fi

    if [[ ! -f ${XBUTIL} ]]; then
        log_error "!!! Cannot find ${XBUTIL}.  Are you sure the XRT package has been installed?"
        return 3
    fi
    
    if [[ ! -f ${XBMGMT} ]]; then
        log_error "!!! Cannot find ${XBMGMT}.  Are you sure the XRT package has been installed?"
        return 4
    fi

    if [[ ${FPGAS_TOTAL} -ne ${FPGAS_USABLE} ]]; then
        log_error "Found ${FPGAS_TOTAL} total FPGAs - but only ${FPGAS_USABLE} are usable. Reboot and re-run the installer"
        return 5
    fi

    if [[ ${LEN_DEVICES_LIST} -ne ${LEN_PORT_LIST} ]]; then
        log_error "Got non-matching number of mgmt (${LEN_MGMT_LIST}) and renderD (${LEN_RENDER_LIST}) devices."
        return 6
    fi

    for DEVICE in ${DEVICES_LIST[@]}; do
        local DEV=$(echo ${DEVICE} | grep -Eo [0-9]+)
        local CURRENT_BD=$(${XBMGMT} scan | grep ${DEV} | grep -Eo '[0-9a-fA-F]+:[0-9a-fA-F]+:[0-9a-fA-F]+')
        local CURRENT_DEVICE_ID=$(${XBUTIL} scan | grep ${CURRENT_BD} | grep -Eo '\[[0-9]]' | grep -Eo [0-9])
        local CURRENT_BDF=$(${XBUTIL} scan | grep ${CURRENT_BD} | grep -Eo '[0-9a-fA-F]+:[0-9a-fA-F]+:[0-9a-fA-F]+\.[0-9]+')
        # xbutil scan returns all visible user devices
        local TARGET_DRI=$(${XBUTIL} scan | grep "\[${CURRENT_DEVICE_ID}\]" | grep -oP '(?<=inst=)[0-9]+')     
        local RENDERD_PATH=/dev/dri/renderD${TARGET_DRI}

        if ! ${LS} ${RENDERD_PATH} > /dev/null 2>&1; then    
            log_error "Found ${DEVICE} but missing the corresponding ${RENDERD_PATH}. Was it mapped in ?"
            return 7
        fi
    done


    log_success "Device entries for ${#LEN_DEVICES_LIST[@]} Xilinx card(s) detected"
    return 0
}
