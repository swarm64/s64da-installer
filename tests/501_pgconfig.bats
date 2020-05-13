#!/usr/bin/env bats

setup() {
    . ./lib/501_pgconfig-all.sh
    . ./lib/base.sh
    S64DA_DIR="./s64-tests"
    mkdir ${S64DA_DIR}
    load bats-mock
    BATS_TMPDIR="${S64DA_DIR:-/tmp}"
}

teardown() {
    rm -rf ./s64-tests
}


@test "Pgconf Edit Failed" {
    EDIT_FILE=$(mock_create)
    mock_set_status ${EDIT_FILE} 1

    run show_edit_pgconfig
    
    [ "$status" -eq 1 ]
}

@test "Pgconf Edit Passed" {
    EDIT_FILE=$(mock_create)
    mock_set_status ${EDIT_FILE} 0

    run show_edit_pgconfig
    
    [ "$status" -eq 0 ]
}
