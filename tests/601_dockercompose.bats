#!/usr/bin/env bats

setup() {
    . ./lib/601_dockercompose-all.sh
    . ./lib/base.sh
    S64DA_DIR="./s64-tests"
    mkdir ${S64DA_DIR}
    load bats-mock
    BATS_TMPDIR="${S64DA_DIR:-/tmp}"
}

teardown() {
    rm -rf ./s64-tests
}


@test "Docker-compose Edit Failed" {
    EDIT_FILE=$(mock_create)
    mock_set_status ${EDIT_FILE} 1

    run show_edit_docker_compose
    
    [ "$status" -eq 1 ]
}

@test "Docker-compose Edit Passed" {
    EDIT_FILE=$(mock_create)
    mock_set_status ${EDIT_FILE} 0

    run show_edit_docker_compose
    
    [ "$status" -eq 0 ]
}
