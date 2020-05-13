#!/usr/bin/env bats

setup() {
    . ./lib/301_install_drivers-intel.sh
    . ./lib/base.sh
    S64DA_DIR="./s64-tests"
    mkdir ${S64DA_DIR}
    load bats-mock
    BATS_TMPDIR="${S64DA_DIR:-/tmp}"
}

teardown() {
    rm -rf ./s64-tests
}


@test "Opae libs missing" {
    OPAE_PACKAGES="opae-libs opae-devel opae-tools opae-intel-fpga-driver"
    PACKAGES=(opae-devel opae-tools opae-intel-fpga-driver)

    YUM=$(mock_create)
    SPINNER=$(mock_create)
    WC=$(mock_create)
    mock_set_output ${WC} "1"

    run install_intel_drivers
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "opae-libs not found in yum repo" ]
}

@test "Opae devel missing" {
    OPAE_PACKAGES="opae-libs opae-devel opae-tools opae-intel-fpga-driver"
    PACKAGES=(opae-libs opae-tools opae-intel-fpga-driver)

    YUM=$(mock_create)
    SPINNER=$(mock_create)
    WC=$(mock_create)
    mock_set_output ${WC} "1"

    run install_intel_drivers
    echo ${lines[@]}
    [ "$status" -eq 1 ]
    [ "${lines[3]}" = "opae-devel not found in yum repo" ]
}

@test "Opae tools missing" {
    OPAE_PACKAGES="opae-libs opae-devel opae-tools opae-intel-fpga-driver"
    PACKAGES=(opae-libs opae-devel opae-intel-fpga-driver)

    YUM=$(mock_create)
    SPINNER=$(mock_create)
    WC=$(mock_create)
    mock_set_output ${WC} "1"

    run install_intel_drivers
    [ "$status" -eq 1 ]
    [ "${lines[5]}" = "opae-tools not found in yum repo" ]
}

@test "Opae intel-fpga-driver missing" {
    OPAE_PACKAGES="opae-libs opae-devel opae-tools opae-intel-fpga-driver"
    PACKAGES=(opae-libs opae-devel opae-tools )

    YUM=$(mock_create)
    SPINNER=$(mock_create)
    WC=$(mock_create)
    mock_set_output ${WC} "1"

    run install_intel_drivers
    [ "$status" -eq 1 ]
    [ "${lines[7]}" = "opae-intel-fpga-driver not found in yum repo" ]
}

@test "Intel Package install failed" {
    OPAE_PACKAGES="opae-libs opae-devel opae-tools opae-intel-fpga-driver"
    PACKAGES=(opae-libs opae-devel opae-tools opae-intel-fpga-driver)

    YUM=$(mock_create)
    SPINNER=$(mock_create)
    WC=$(mock_create)
    mock_set_output ${WC} "1"
    mock_set_output ${WC} "0" 4

    run install_intel_drivers
    [ "$status" -eq 2 ]
    [ "${lines[9]}" = "Installation of opae-intel-fpga-driver failed / Package not available" ]
}

@test "Intel Package installs passed" {
    OPAE_PACKAGES="opae-libs opae-devel opae-tools"
    PACKAGES=(opae-libs opae-devel opae-tools opae-intel-fpga-driver)

    YUM=$(mock_create)
    SPINNER=$(mock_create)
    WC=$(mock_create)
    mock_set_output ${WC} "1"

    run install_intel_drivers
    [ "$status" -eq 0 ]
    [ "${lines[7]}" = "Installed Intel drivers and packages" ]
}
