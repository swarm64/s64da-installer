#!/usr/bin/env bats

setup() {
    . ./lib/302_install_drivers-xilinx.sh
    . ./lib/base.sh
    S64DA_DIR="./s64-tests"
    mkdir ${S64DA_DIR}
    load bats-mock
    BATS_TMPDIR="${S64DA_DIR:-/tmp}"
}

teardown() {
    rm -rf ./s64-tests
}


@test "Xilinx-u200 missing" {
    XILINX_PACKAGES="xilinx-u200-xdma xrt"
    PACKAGES=(xrt )

    YUM=$(mock_create)
    SPINNER=$(mock_create)
    WC=$(mock_create)
    mock_set_output ${WC} "1"

    run install_xilinx_drivers
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "xilinx-u200-xdma not found in yum repo" ]
}

@test "Xrt missing" {
    XILINX_PACKAGES="xilinx-u200-xdma xrt"
    PACKAGES=(xilinx-u200-xdma )

    YUM=$(mock_create)
    SPINNER=$(mock_create)
    WC=$(mock_create)
    mock_set_output ${WC} "1"

    run install_xilinx_drivers
    [ "$status" -eq 1 ]
    [ "${lines[3]}" = "xrt not found in yum repo" ]
}

@test "Xilinx Package install failed" {
    XILINX_PACKAGES="xilinx-u200-xdma xrt"
    PACKAGES=(xilinx-u200-xdma xrt)

    YUM=$(mock_create)
    SPINNER=$(mock_create)
    WC=$(mock_create)
    mock_set_output ${WC} "1"
    mock_set_output ${WC} "0" 2

    run install_xilinx_drivers
    [ "$status" -eq 2 ]
    echo ${lines[5]}
    [ "${lines[5]}" = "Installation of xrt failed / Package not available" ]
}

@test "Xilinx Package installs passed" {
    XILINX_PACKAGES="xilinx-u200-xdma xrt"
    PACKAGES=(xilinx-u200-xdma xrt)

    IS_SUPER_USER="TRUE"
    YUM=$(mock_create)
    SPINNER=$(mock_create)
    WC=$(mock_create)
    mock_set_output ${WC} "1"

    run install_xilinx_drivers
    [ "$status" -eq 0 ]
    [ "${lines[3]}" = "Installed Xilinx drivers and packages" ]
}