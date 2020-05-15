#!/bin/bash

function install_intel_drivers_init {
    YUM='yum'
    SPINNER='spinner'
    WC='wc'
    OPAE_PACKAGES="opae-libs opae-devel opae-tools opae-intel-fpga-driver"
    OPAE_VERSION=1.1.2-1
    PACKAGES=()
    for PKG in $(yum search opae 2> ${LOG} | awk '/^opae-.*\.x86_64/ {print $1}'); do
        PACKAGES+=(${PKG});
    done

    return 0
}


function install_intel_drivers {
    log_info "Installing Intel drivers and packages"

    for OPAE_PACKAGE in ${OPAE_PACKAGES}; do

        if [[ ! "${PACKAGES[@]}" =~ "${OPAE_PACKAGE}" ]]; then
            log_error "${OPAE_PACKAGE} not found in yum repo"
            return 1
        fi
        log_info "Installing ${OPAE_PACKAGE}"

        if [[ ${IS_SUPER_USER} == "TRUE" ]]; then
            ${YUM} install -y "${OPAE_PACKAGE}" &>> ${LOG} &
            ${SPINNER} $!
        else
            log_info "Not a super user. Skip installation of ${OPAE_PACKAGE}"
        fi

        PACKAGE_PRESENT=$(${YUM} list -q installed 2> ${LOG} | grep -E ${OPAE_PACKAGE} | ${WC} -l)
        if [[ "${PACKAGE_PRESENT}" == "0" ]]; then
            log_error "Installation of ${OPAE_PACKAGE} failed / Package not available\nDid you run as root ? (sudo ./install.sh ..)"
            return 2
        fi

    done

    log_success "Installed Intel drivers and packages"

    return 0
}
