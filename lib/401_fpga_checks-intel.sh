#!/bin/bash

function check_intel_device_files_init {
    log_info "Checking for intel device entries"

    DEV_DIR='/dev/'
    FME_NAME='intel-fpga-fme'
    PORT_NAME='intel-fpga-port'
    BDF_LINK_PRE='/sys/class/fpga/intel-fpga-dev'
    BDF_LINK_POST='/device'
    DEVICES_LIST=()
    DEVICES_PORT_LIST=()
    DEVICES_BDF_LIST=()
    REGEX_DEV="\.(\w)"
    REGEX_BDF="(\w{2}):(\w{2})\.(\w)"

    for FME in $(ls -1 ${DEV_DIR}${FME_NAME}* 2>>${LOG});do
        DEVICES_LIST+=(${FME})
    done

    return 0
}


function check_intel_device_files {
    # confirm device entries
    if [[ ${#DEVICES_LIST[@]} -lt 1 ]]; then
        log_error "No Intel device entries found"
        return 1
    fi
   
    for DEVICE in ${DEVICES_LIST[@]}; do 
        [[ "${DEVICE}" =~ $REGEX_DEV ]]
        local TARGET_DEV_PORT=${DEV_DIR}${PORT_NAME}.${BASH_REMATCH[1]}
        # not used here, storing for docker-compose.yml
        DEVICES_PORT_LIST+=(${TARGET_DEV_PORT})
        if [ ! -e ${TARGET_DEV_PORT} ]; then
            log_error "Found ${DEVICE} but ${TARGET_DEV_PORT} is missing"
            return 2
        fi

        local BDF_LINK="${BDF_LINK_PRE}.${BASH_REMATCH[1]}${BDF_LINK_POST}"
        # not used here, storing for docker-compose.yml
        DEVICES_BDF_LIST+=(${BDF_LINK_PRE}.${BASH_REMATCH[1]}/${PORT_NAME}.${BASH_REMATCH[1]})
        if [ ! -e ${BDF_LINK} ]; then
            log_error "Found ${DEVICE} but ${BDF_LINK} is missing"
            return 3
        fi
    done

    log_success "Device entries for ${#DEVICES_LIST[@]} Intel card(s) detected"
    return 0
}
