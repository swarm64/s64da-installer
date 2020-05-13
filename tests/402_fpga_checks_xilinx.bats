#!/usr/bin/env bats                                                                                                                                                                  

setup() {
    S64DA_DIR="./s64-tests"
    . ./lib/402_fpga_checks-xilinx.sh
    . ./lib/base.sh
    load bats-mock
    mkdir -p ${S64DA_DIR}
    BATS_TMPDIR="${S64DA_DIR:-/tmp}"
}

teardown() {
    rm -rf ./s64-tests
}

@test "Mgmt devices not loaded" {
    LEN_DEVICES_LIST=0
    run check_xilinx_device_files
    [ "$status" -eq 1 ]
}

@test "Port devices not loaded" {
    LEN_DEVICES_LIST=1
    LEN_PORT_LIST=0
    run check_xilinx_device_files
    [ "$status" -eq 2 ]
}

@test "Xbutil not found" {
    LEN_DEVICES_LIST=1
    LEN_PORT_LIST=1
    run check_xilinx_device_files
    [ "$status" -eq 3 ]
}

@test "Xbmgmt not found" {
    LEN_DEVICES_LIST=1
    LEN_PORT_LIST=1
    XBUTIL=$(mock_create)
    run check_xilinx_device_files
    [ "$status" -eq 4 ]
}

@test "Not Usable" {
    LEN_DEVICES_LIST=1
    LEN_PORT_LIST=1
    XBUTIL=$(mock_create)
    XBMGMT=$(mock_create)
    FPGAS_TOTAL=1
    FPGAS_USABLE=0
    run check_xilinx_device_files
    [ "$status" -eq 5 ]
}

@test "Devices mismatch" {
    LEN_DEVICES_LIST=2
    LEN_PORT_LIST=1
    XBUTIL=$(mock_create)
    XBMGMT=$(mock_create)
    FPGAS_TOTAL=1
    FPGAS_USABLE=1
    run check_xilinx_device_files
    [ "$status" -eq 6 ]
}

@test "Mgmt Port mismatch" {
    LEN_DEVICES_LIST=1
    LEN_PORT_LIST=1
    XBUTIL=$(mock_create)
    XBMGMT=$(mock_create)
    FPGAS_TOTAL=1
    FPGAS_USABLE=1
    DEVICES_LIST=( /tmp/xctlmgmt/999 )
    LS=$(mock_create)
    mock_set_status ${LS} 1
    run check_xilinx_device_files
    [ "$status" -eq 7 ]
}

@test "Xilinx devs Ok" {
    LEN_DEVICES_LIST=1
    LEN_PORT_LIST=1
    XBUTIL=$(mock_create)
    XBMGMT=$(mock_create)
    FPGAS_TOTAL=1
    FPGAS_USABLE=1
    DEVICES_LIST=( /tmp/xctlmgmt/999 )
    LS=$(mock_create)
    mock_set_status ${LS} 0
    run check_xilinx_device_files
    [ "$status" -eq 0 ]
}
