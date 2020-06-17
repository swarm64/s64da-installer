#!/bin/bash

function system_config_init {
    EDIT_FILE='edit_file'
    ULIMIT='ulimit'
    ECHO='echo'
    CAT='cat'
    CP='cp'
    UDEVADM='udevadm'
    CHMOD='chmod'
    SYSCTL='sysctl'
    STAT='stat'
    SYSCTL_CONF='99-sysctl_swarm64.conf'
    OS_SYSCTL_CONF='/etc/sysctl.d/99-sysctl_swarm64.conf'
    SYSCTL_TEMPLATE='templates/99-sysctl_swarm64.conf.template'
    RC_LOCAL='config/rc.local'
    OS_RC_LOCAL='/etc/rc.d/rc.local'
    UDEV_RULES='config/99-swarm64.rules'
    UDEV_RULES_DIR='/etc/udev/rules.d/'
    OS_UDEV_RULES='/etc/udev/rules.d/99-swarm64.rules'
    DESIRED_ULIMIT_V='unlimited'
    PROC_OVERCOMMIT_MEM='/proc/sys/vm/overcommit_memory'
    HUGEPAGE_ENABLED='/sys/kernel/mm/transparent_hugepage/enabled'
    HUGEPAGE_DEFRAG='/sys/kernel/mm/transparent_hugepage/defrag'

    HUGE_SHM_GROUP=100

    case ${TARGET_DEVICE} in
        "pac-a10")
            NUM_HUGE_PAGES=$((${#DEVICES_LIST[@]} * 265))
            ;;
        "u50")
            NUM_HUGE_PAGES=$((${#DEVICES_LIST[@]} * 520))
            ;;
        "u200")
            NUM_HUGE_PAGES=$((${#DEVICES_LIST[@]} * 1032))
            ;;
        "u250")
            NUM_HUGE_PAGES=$((${#DEVICES_LIST[@]} * 1032))
            ;;
        "smartssd")
            NUM_HUGE_PAGES=$((${#DEVICES_LIST[@]} * 264))
            ;;                                                
        "cpu")
            NUM_HUGE_PAGES=137
            ;;
        *)
            log_error "TARGET_DEVICE variable value $TARGET_DEVICE unknown."
            ;;
    esac

    sed "s#__HUGE_SHM_GROUP__#${HUGE_SHM_GROUP}#g; s#__NUM_HUGE_PAGES__#${NUM_HUGE_PAGES}#g" \
    "${SYSCTL_TEMPLATE}" > ${SYSCTL_TEMPLATE}.tmp

    return 0
}


function system_config {
    # Editing system config is disabled for now
    #${EDIT_FILE} ${SYSCTL_CONF} ${SYSCTL_TEMPLATE}.tmp
    #if [[ $? -ne 0 ]]; then
    #    return 1
    #fi
    mv ${SYSCTL_TEMPLATE}.tmp config/${SYSCTL_CONF} 2>>${LOG}

    ${CAT} config/${SYSCTL_CONF} > ${OS_SYSCTL_CONF:-/tmp/s64_remove_me} 2>>${LOG}
    ${CHMOD} +x ${OS_SYSCTL_CONF:-/tmp/s64_remove_me} 2>>${LOG}
    ${SYSCTL} -p ${OS_SYSCTL_CONF} >>${LOG}
    log_success "Written sysctl settings to: ${OS_SYSCTL_CONF}"

    local CHECK_HUGE_PAGES=$(${SYSCTL} vm.nr_hugepages | awk '{print $3}')
    if [[ ${CHECK_HUGE_PAGES} -lt ${NUM_HUGE_PAGES} ]]; then
        log_error "Huge pages must be at least ${NUM_HUGE_PAGES}"
        return 2
    fi

    local CHECK_HUGE_SHM_GROUP=$(${SYSCTL} vm.hugetlb_shm_group | awk '{print $3}')
    if [[ "${CHECK_HUGE_SHM_GROUP}" != "${HUGE_SHM_GROUP}" ]]; then 
        log_error "Huge pages shm group not updated"
        return 3
    fi

    local CHECK_ULIMIT_V=$(${ULIMIT} -v)
    if [[ "${CHECK_ULIMIT_V}" != "${DESIRED_ULIMIT_V}" ]]; then 
        ${ULIMIT} -v ${DESIRED_ULIMIT_V}
        if [[ $? != 0 ]]; then
            log_error "Allocation of unlimited virtual memory could not be set (ulimit -v)"
            return 4
        fi
    fi

    local CHECK_OVERCOMMIT=$(${CAT} ${PROC_OVERCOMMIT_MEM})
    if [[ ${CHECK_OVERCOMMIT} != 0 || ${CHECK_OVERCOMMIT} != 1 ]]; then 
        log_info "Setting unrestricted virtual memory (${PROC_OVERCOMMIT_MEM})"
        ${ECHO} 0 > ${PROC_OVERCOMMIT_MEM}
        if [[ $? != 0 ]]; then
            log_error "Setting unrestricted virtual memory failed"
            return 5
        fi
    fi

    log_info "Updating ${HUGEPAGE_ENABLED}"
    ${ECHO} never > ${HUGEPAGE_ENABLED}
    if [[ $? != 0 ]]; then
        log_error "Updating hugepages failed"
        return 6
    fi

    log_info "Updating ${HUGEPAGE_DEFRAG}"
    ${ECHO} never > ${HUGEPAGE_DEFRAG}
    if [[ $? != 0 ]]; then
        log_error "Updating hugepage defrag failed"
        return 7
    fi

    if [[ ! -f ${OS_RC_LOCAL} ]]; then
        log_info "Creating rc.local entries"
        ${CAT} ${RC_LOCAL} >> ${OS_RC_LOCAL:-/tmp/s64_remove_me}
        if [[ $? != 0 ]]; then
            log_error "Couldn't create swarm rc.local file"
            return 8
        fi

        ${CHMOD} +x ${OS_RC_LOCAL}
        if [[ $? != 0 ]]; then
            log_error "Couldn't make rc.local file executable"
            return 9
        fi
    elif no_entry_exists "${HUGEPAGE_ENABLED}" "${OS_RC_LOCAL}" ; then
        log_info "Updating rc.local entries"
        ${CAT} ${RC_LOCAL} >> ${OS_RC_LOCAL:-/tmp/s64_remove_me}
        if [[ $? != 0 ]]; then
            log_error "Couldn't update rc.local entries"
            return 10
        fi
    fi

    if [[ ! -f ${OS_UDEV_RULES} ]]; then
        log_info "Updating udev rules"
        ${CP} ${UDEV_RULES} ${UDEV_RULES_DIR:-/tmp/s64_remove_me}
        if [[ $? != 0 ]]; then
            log_error "Couldn't update udev rules"
            return 11
        fi

        ${UDEVADM} control --reload-rules
        if [[ $? != 0 ]]; then
            log_error "Couldn't reload udev rules (udevadm control)"
            return 12
        fi

        ${UDEVADM} trigger
        if [[ $? != 0 ]]; then
            log_error "Couldn't reload udev rules (udevadm trigger)"
            return 13
        fi

    fi

    for DEV in ${DEVICES_LIST[@]}; do
        if [[ $(${STAT} -c '%a' ${DEV}) != 666 ]]; then
            log_warn "${DEV} has the wrong permissions, setting"
            ${CHMOD} 666 ${DEV}
            if [[ $? != 0 ]]; then
                log_error "${DEV} has the wrong permissions, can't set"
                return 14
            fi
        fi
    done

    for DEV in ${DEVICES_PORT_LIST[@]}; do
        if [[ $(${STAT} -c '%a' ${DEV}) != 666 ]]; then
            log_warn "${DEV} has the wrong permissions, setting"
            ${CHMOD} 666 ${DEV}
            if [[ $? != 0 ]]; then
                log_error "${DEV} has the wrong permissions, can't set"
                return 15
            fi
        fi
    done

    if [[ -f /tmp/s64_remove_me ]]; then
        rm /tmp/s64_remove_me
    fi

    log_success "System setup is correct"
    return 0
}
