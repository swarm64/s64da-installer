#!/bin/bash

function install_xilinx_drivers_init {

    YUM='yum'
    SPINNER='spinner'
    WC='wc'
    XILINX_PACKAGES="xrt"
    if [[ "${TARGET_DEVICE}" == "u50" ]]; then
       XILINX_PACKAGES+=" xilinx-u50-gen3x16-xdma-blp xilinx-cmc-u50 xilinx-sc-fw-u50"
    else
       XILINX_PACKAGES+=" xilinx-${TARGET_DEVICE}-xdma"
    fi
    PACKAGES=()
    for PKG in $(yum search xilinx | awk '/^xilinx-/ || /^xrt/ {print $1}'); do
        PACKAGES+=(${PKG});
    done
}


function install_xilinx_drivers {
    if [[ "${TARGET_DEVICE}" == "smartssd" ]]; then
        log_warn "Samsung SmartSSD automatic driver installation not available.\nInstall manually and execute installer again."
    else    
        log_info "Installing Xilinx drivers and packages"

        for XILINX_PACKAGE in ${XILINX_PACKAGES}; do
            if [[ ! "${PACKAGES[@]}" =~ "${XILINX_PACKAGE}" ]]; then
                log_error "${XILINX_PACKAGE} not found in yum repo"
                return 1
            fi
            log_info "Installing ${XILINX_PACKAGE}"

            if [[ ${IS_SUPER_USER} == "TRUE" ]]; then
                ${YUM} install -y "${XILINX_PACKAGE}" &>>${LOG} &
                ${SPINNER} $!
            else
                log_info "Not a super user. Skip installation of ${XILINX_PACKAGE}"
            fi

            PACKAGE_PRESENT=$(${YUM} list -q installed 2> ${LOG} | grep -E ${XILINX_PACKAGE} | ${WC} -l)
            if [[ "${PACKAGE_PRESENT}" == "0" ]]; then
                log_error "Installation of ${XILINX_PACKAGE} failed / Package not available\nDid you run as root ? (sudo ./install.sh ..)"
                return 2
            fi
        done

        log_success "Installed Xilinx drivers and packages"
    fi

    return 0
}
