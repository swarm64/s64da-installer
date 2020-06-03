#!/usr/bin/env bats

setup() {
    S64DA_DIR="./s64-tests"
    . ./lib/701_system_config-all.sh
    . ./lib/base.sh
    mkdir -p ${S64DA_DIR}
    load bats-mock
    BATS_TMPDIR="${S64DA_DIR:-/tmp}"
    touch ${S64DA_DIR}/overcommit_memory
    touch ${S64DA_DIR}/hugepage_enabled
    touch ${S64DA_DIR}/hugepage_defrag
    touch ${S64DA_DIR}/rc.local
    touch ${S64DA_DIR}/rc.loc
    echo "${S64DA_DIR}/hugepage_enabled" >> ${S64DA_DIR}/rc.local
    touch ${S64DA_DIR}/udev_rules
    touch ${S64DA_DIR}/fme.0 && chmod 666 ${S64DA_DIR}/fme.0
    touch ${S64DA_DIR}/fme.1 && chmod 666 ${S64DA_DIR}/fme.1
    touch ${S64DA_DIR}/fme.2 && chmod 646 ${S64DA_DIR}/fme.2
    touch ${S64DA_DIR}/fme.3 && chmod 666 ${S64DA_DIR}/fme.3
    touch ${S64DA_DIR}/port.0 && chmod 666 ${S64DA_DIR}/port.0
    touch ${S64DA_DIR}/port.1 && chmod 666 ${S64DA_DIR}/port.1
    touch ${S64DA_DIR}/port.2 && chmod 666 ${S64DA_DIR}/port.2
    touch ${S64DA_DIR}/port.3 && chmod 664 ${S64DA_DIR}/port.3
}

teardown() {
    rm -rf ./s64-tests
}

@test "Huge Pages wrong" {
    NUM_HUGE_PAGES="12"
    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)

    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2

    run system_config
    [ "$status" -eq 2 ]
    [ "${lines[0]}" = "Huge pages must be at least 12" ]
    [ "$(mock_get_call_num ${SYSCTL})" -eq 2 ]
}

@test "shm group wrong" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"

    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 24" 3

    run system_config
    [ "$status" -eq 3 ]
    [ "${lines[0]}" = "Huge pages shm group not updated" ]
    [ "$(mock_get_call_num ${SYSCTL})" -eq 3 ]
}

@test "Ulimit not set" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"
    DESIRED_ULIMIT_V="unlimited"
    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    ULIMIT=$(mock_create)

    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 23" 3
    mock_set_output ${ULIMIT} "fail_unlimited" 1
    mock_set_status ${ULIMIT} 1 2

    run system_config
    [ "$status" -eq 4 ]
    [ "$(mock_get_call_num ${SYSCTL})" -eq 3 ]
    [ "$(mock_get_call_num ${ULIMIT})" -eq 2 ]
}

@test "Can't update overcommit_memory" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"
    DESIRED_ULIMIT_V="unlimited"
    PROC_OVERCOMMIT_MEM="${S64DA_DIR}/overcommit_memory"

    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    ULIMIT=$(mock_create)
    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 23" 3
    mock_set_output ${ULIMIT} "fail_unlimited"
    mock_set_status ${ULIMIT} 0
    ECHO=$(mock_create)
    mock_set_status ${ECHO} 1

    run system_config
    [ "$status" -eq 5 ]
}

@test "Can't update hugepage_enabled" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"
    DESIRED_ULIMIT_V="unlimited"
    PROC_OVERCOMMIT_MEM="${S64DA_DIR}/overcommit_memory"
    HUGEPAGE_ENABLED="${S64DA_DIR}/hugepage_enabled"

    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    ULIMIT=$(mock_create)
    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 23" 3
    mock_set_output ${ULIMIT} "fail_unlimited"
    mock_set_status ${ULIMIT} 0
    ECHO=$(mock_create)
    mock_set_status ${ECHO} 1 2

    run system_config
    [ "$status" -eq 6 ]
}

@test "Can't update hugepage_defrag" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"
    DESIRED_ULIMIT_V="unlimited"
    PROC_OVERCOMMIT_MEM="${S64DA_DIR}/overcommit_memory"
    HUGEPAGE_ENABLED="${S64DA_DIR}/hugepage_enabled"
    HUGEPAGE_DEFRAG="${S64DA_DIR}/hugepage_defrag"

    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    ULIMIT=$(mock_create)
    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 23" 3
    mock_set_output ${ULIMIT} "fail_unlimited"
    mock_set_status ${ULIMIT} 0
    ECHO=$(mock_create)
    mock_set_status ${ECHO} 1 3

    run system_config
    [ "$status" -eq 7 ]
}

@test "Can't update rc.local 1" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"
    DESIRED_ULIMIT_V="unlimited"
    PROC_OVERCOMMIT_MEM="${S64DA_DIR}/overcommit_memory"
    HUGEPAGE_ENABLED="${S64DA_DIR}/hugepage_enabled"
    HUGEPAGE_DEFRAG="${S64DA_DIR}/hugepage_defrag"
    OS_RC_LOCAL="${S64DA_DIR}/rc.loca"
    RC_LOCAL="${S64DA_DIR}/rc.loc"

    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    ULIMIT=$(mock_create)
    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 23" 3
    mock_set_output ${ULIMIT} "fail_unlimited"
    mock_set_status ${ULIMIT} 0
    ECHO=$(mock_create)
    mock_set_status ${CAT} 1 3

    run system_config
    [ "$status" -eq 8 ]
    [ "$(mock_get_call_num ${CAT})" -eq 3 ]
}

@test "Can't update rc.local 2" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"
    DESIRED_ULIMIT_V="unlimited"
    PROC_OVERCOMMIT_MEM="${S64DA_DIR}/overcommit_memory"
    HUGEPAGE_ENABLED="${S64DA_DIR}/hugepage_enabled"
    HUGEPAGE_DEFRAG="${S64DA_DIR}/hugepage_defrag"
    OS_RC_LOCAL="${S64DA_DIR}/rc.loca"
    RC_LOCAL="${S64DA_DIR}/rc.loc"

    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    ULIMIT=$(mock_create)
    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 23" 3
    mock_set_output ${ULIMIT} "fail_unlimited"
    mock_set_status ${ULIMIT} 0
    ECHO=$(mock_create)
    mock_set_status ${CHMOD} 1 2

    run system_config
    [ "$status" -eq 9 ]
    [ "$(mock_get_call_num ${CHMOD})" -eq 2 ]
}

@test "Can't update rc.local 3" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"
    DESIRED_ULIMIT_V="unlimited"
    PROC_OVERCOMMIT_MEM="${S64DA_DIR}/overcommit_memory"
    HUGEPAGE_ENABLED="${S64DA_DIR}/hugepage_enabled"
    HUGEPAGE_DEFRAG="${S64DA_DIR}/hugepage_defrag"
    OS_RC_LOCAL="${S64DA_DIR}/rc.loc"
    RC_LOCAL="${S64DA_DIR}/rc.loca"

    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    ULIMIT=$(mock_create)
    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 23" 3
    mock_set_output ${ULIMIT} "fail_unlimited"
    mock_set_status ${ULIMIT} 0
    ECHO=$(mock_create)
    mock_set_status ${CAT} 1 3

    run system_config
    [ "$status" -eq 10 ]
    [ "$(mock_get_call_num ${CAT})" -eq 3 ]
}

@test "Can't update udev rules" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"
    DESIRED_ULIMIT_V="unlimited"
    PROC_OVERCOMMIT_MEM="${S64DA_DIR}/overcommit_memory"
    HUGEPAGE_ENABLED="${S64DA_DIR}/hugepage_enabled"
    HUGEPAGE_DEFRAG="${S64DA_DIR}/hugepage_defrag"
    OS_RC_LOCAL="${S64DA_DIR}/rc.loc"
    RC_LOCAL="${S64DA_DIR}/rc.loca"

    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    ULIMIT=$(mock_create)
    CP=$(mock_create)
    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 23" 3
    mock_set_output ${ULIMIT} "fail_unlimited"
    mock_set_status ${ULIMIT} 0
    ECHO=$(mock_create)
    mock_set_status ${CP} 1

    run system_config
    [ "$status" -eq 11 ]
}

@test "Udev Reload Fails" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"
    DESIRED_ULIMIT_V="unlimited"
    PROC_OVERCOMMIT_MEM="${S64DA_DIR}/overcommit_memory"
    HUGEPAGE_ENABLED="${S64DA_DIR}/hugepage_enabled"
    HUGEPAGE_DEFRAG="${S64DA_DIR}/hugepage_defrag"
    OS_RC_LOCAL="${S64DA_DIR}/rc.loc"
    RC_LOCAL="${S64DA_DIR}/rc.loca"

    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    ULIMIT=$(mock_create)
    CP=$(mock_create)
    UDEVADM=$(mock_create)
    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 23" 3
    mock_set_output ${ULIMIT} "fail_unlimited"
    mock_set_status ${ULIMIT} 0
    ECHO=$(mock_create)
    mock_set_status ${UDEVADM} 1

    run system_config
    [ "$status" -eq 12 ]
}

@test "Udev Trigger Fails" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"
    DESIRED_ULIMIT_V="unlimited"
    PROC_OVERCOMMIT_MEM="${S64DA_DIR}/overcommit_memory"
    HUGEPAGE_ENABLED="${S64DA_DIR}/hugepage_enabled"
    HUGEPAGE_DEFRAG="${S64DA_DIR}/hugepage_defrag"
    OS_RC_LOCAL="${S64DA_DIR}/rc.loc"
    RC_LOCAL="${S64DA_DIR}/rc.loca"

    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    ULIMIT=$(mock_create)
    CP=$(mock_create)
    UDEVADM=$(mock_create)
    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 23" 3
    mock_set_output ${ULIMIT} "fail_unlimited"
    mock_set_status ${ULIMIT} 0
    ECHO=$(mock_create)
    mock_set_status ${UDEVADM} 1 2

    run system_config
    [ "$status" -eq 13 ]
}

@test "fme perms wrong" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"
    DESIRED_ULIMIT_V="unlimited"
    PROC_OVERCOMMIT_MEM="${S64DA_DIR}/overcommit_memory"
    HUGEPAGE_ENABLED="${S64DA_DIR}/hugepage_enabled"
    HUGEPAGE_DEFRAG="${S64DA_DIR}/hugepage_defrag"
    OS_RC_LOCAL="${S64DA_DIR}/rc.loc"
    RC_LOCAL="${S64DA_DIR}/rc.loca"
    DEVICES_LIST=(${S64DA_DIR}/fme.0 ${S64DA_DIR}/fme.1)

    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    ULIMIT=$(mock_create)
    CP=$(mock_create)
    UDEVADM=$(mock_create)
    STAT=$(mock_create)
    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 23" 3
    mock_set_output ${ULIMIT} "fail_unlimited"
    mock_set_status ${CHMOD} 1 2
    mock_set_status ${ULIMIT} 0
    ECHO=$(mock_create)
    mock_set_output ${STAT} "644"

    run system_config
    [ "$status" -eq 14 ]
}

@test "port perms wrong" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"
    DESIRED_ULIMIT_V="unlimited"
    PROC_OVERCOMMIT_MEM="${S64DA_DIR}/overcommit_memory"
    HUGEPAGE_ENABLED="${S64DA_DIR}/hugepage_enabled"
    HUGEPAGE_DEFRAG="${S64DA_DIR}/hugepage_defrag"
    OS_RC_LOCAL="${S64DA_DIR}/rc.loc"
    RC_LOCAL="${S64DA_DIR}/rc.loca"
    DEVICES_LIST=(${S64DA_DIR}/fme.0 ${S64DA_DIR}/fme.1)
    DEVICES_PORT_LIST=(${S64DA_DIR}/port.0 ${S64DA_DIR}/port.1)

    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    ULIMIT=$(mock_create)
    CP=$(mock_create)
    UDEVADM=$(mock_create)
    STAT=$(mock_create)
    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 23" 3
    mock_set_output ${ULIMIT} "fail_unlimited"
    mock_set_status ${CHMOD} 1 2
    mock_set_status ${ULIMIT} 0
    ECHO=$(mock_create)
    mock_set_output ${STAT} "666"
    mock_set_output ${STAT} "644" 4

    run system_config
    [ "$status" -eq 15 ]
}

@test "system changes all correct" {
    NUM_HUGE_PAGES="11"
    HUGE_SHM_GROUP="23"
    DESIRED_ULIMIT_V="unlimited"
    PROC_OVERCOMMIT_MEM="${S64DA_DIR}/overcommit_memory"
    HUGEPAGE_ENABLED="${S64DA_DIR}/hugepage_enabled"
    HUGEPAGE_DEFRAG="${S64DA_DIR}/hugepage_defrag"
    OS_RC_LOCAL="${S64DA_DIR}/rc.loc"
    RC_LOCAL="${S64DA_DIR}/rc.loca"
    DEVICES_LIST=(${S64DA_DIR}/fme.0 ${S64DA_DIR}/fme.1)
    DEVICES_PORT_LIST=(${S64DA_DIR}/port.0 ${S64DA_DIR}/port.1)

    EDIT_FILE=$(mock_create)
    CAT=$(mock_create)
    CHMOD=$(mock_create)
    SYSCTL=$(mock_create)
    ULIMIT=$(mock_create)
    CP=$(mock_create)
    UDEVADM=$(mock_create)
    STAT=$(mock_create)
    mock_set_output ${SYSCTL} "nr_hugepages = 11" 2
    mock_set_output ${SYSCTL} "nr_hugetlb_shm_group = 23" 3
    mock_set_output ${ULIMIT} "fail_unlimited"
    mock_set_status ${ULIMIT} 0
    ECHO=$(mock_create)
    mock_set_output ${STAT} "666"

    run system_config
    [ "$status" -eq 0 ]
}
