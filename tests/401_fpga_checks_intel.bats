#!/usr/bin/env bats                                                                                                                                                                  

setup() {
    S64DA_DIR="./s64-tests"
    . ./lib/401_fpga_checks-intel.sh
    . ./lib/base.sh
    mkdir -p ${S64DA_DIR}
    load bats-mock
    BATS_TMPDIR="${S64DA_DIR:-/tmp}"
    touch ${S64DA_DIR}/intel-fpga-port.0
    touch ${S64DA_DIR}/intel-fpga-port.1
    touch ${S64DA_DIR}/intel-fpga-port.2
    touch ${S64DA_DIR}/intel-fpga-port.3
    touch ${S64DA_DIR}/intel-fpga-port.4
    touch ${S64DA_DIR}/intel-fpga-test.12:00:0
    ln -s ./intel-fpga-test.12:00:0 ${S64DA_DIR}/intel-fpga-dev.0
    touch ${S64DA_DIR}/intel-fpga-test.d8:00:0
    ln -s ./intel-fpga-test.d8:00:0 ${S64DA_DIR}/intel-fpga-dev.1
    touch ${S64DA_DIR}/intel-fpga-test.11:00:0
    ln -s ./intel-fpga-test.11:00:0 ${S64DA_DIR}/intel-fpga-dev.2
    touch ${S64DA_DIR}/intel-fpga-test.d3:00:0
    ln -s ./intel-fpga-test.d3:00:0 ${S64DA_DIR}/intel-fpga-dev.3
}

teardown() {
    rm -rf ./s64-tests
}


@test "No FPGAs" {
    DEVICES_LIST=()
    run check_intel_device_files
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "No Intel device entries found" ]
}

@test "One FPGA" {
    DEV_DIR="${S64DA_DIR}/"
    PORT_NAME="intel-fpga-port"
    BDF_LINK_PRE="${S64DA_DIR}/intel-fpga-dev"
    BDF_LINK_POST=""
    REGEX_DEV="\.(\w)"
    DEVICES_LIST=("${S64DA_DIR}/intel-fpga-fme.0")
    run check_intel_device_files
    [ "$status" -eq 0 ]
    [ "$output" = "Device entries for 1 Intel card(s) detected" ]
}

@test "Two FPGAs" {
    DEV_DIR="${S64DA_DIR}/"
    PORT_NAME="intel-fpga-port"
    BDF_LINK_PRE="${S64DA_DIR}/intel-fpga-dev"
    BDF_LINK_POST=""
    REGEX_DEV="\.(\w)"
    DEVICES_LIST=(${S64DA_DIR}/intel-fpga-fme.0 ${S64DA_DIR}/intel-fpga-fme.1)
    run check_intel_device_files
    [ "$status" -eq 0 ]
    [ "$output" = "Device entries for 2 Intel card(s) detected" ]
}

@test "Four FPGAs" {
    DEV_DIR="${S64DA_DIR}/"
    PORT_NAME="intel-fpga-port"
    BDF_LINK_PRE="${S64DA_DIR}/intel-fpga-dev"
    BDF_LINK_POST=""
    REGEX_DEV="\.(\w)"
    DEVICES_LIST=(${S64DA_DIR}/intel-fpga-fme.0 ${S64DA_DIR}/intel-fpga-fme.1 ${S64DA_DIR}/intel-fpga-fme.2 ${S64DA_DIR}/intel-fpga-fme.3)
    run check_intel_device_files
    [ "$status" -eq 0 ]
    [ "$output" = "Device entries for 4 Intel card(s) detected" ]
}

@test "Port missing" {
    DEV_DIR="${S64DA_DIR}/"
    PORT_NAME="intel-fpga-port"
    BDF_LINK_PRE="${S64DA_DIR}/intel-fpga-dev"
    BDF_LINK_POST=""
    REGEX_DEV="\.(\w)"
    DEVICES_LIST=(${S64DA_DIR}/intel-fpga-fme.5)
    run check_intel_device_files
    [ "$status" -eq 2 ]
    [ "${lines[0]}" = "Found ${S64DA_DIR}/intel-fpga-fme.5 but ${S64DA_DIR}/intel-fpga-port.5 is missing" ]
}

@test "BDF missing" {
    DEV_DIR="${S64DA_DIR}/"
    PORT_NAME="intel-fpga-port"
    BDF_LINK_PRE="${S64DA_DIR}/intel-fpga-dev"
    BDF_LINK_POST=""
    REGEX_DEV="\.(\w)"
    DEVICES_LIST=(${S64DA_DIR}/intel-fpga-fme.1 ${S64DA_DIR}/intel-fpga-fme.2 ${S64DA_DIR}/intel-fpga-fme.3 ${S64DA_DIR}/intel-fpga-fme.4)
    run check_intel_device_files
    [ "$status" -eq 3 ]
    [ "${lines[0]}" = "Found ${S64DA_DIR}/intel-fpga-fme.4 but ${S64DA_DIR}/intel-fpga-dev.4 is missing" ]
}
