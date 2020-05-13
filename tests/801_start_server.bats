

setup() {
    . ./lib/801_start_server-all.sh
    . ./lib/base.sh
    S64DA_DIR="./s64-tests"
    mkdir -p ${S64DA_DIR}
    load bats-mock
    BATS_TMPDIR="${S64DA_DIR:-/tmp}"
}

teardown() {
    rm -rf ./s64-tests
}


@test "Docker Login Fail" {
    DOCKER=$(mock_create)
    mock_set_status ${DOCKER} 1 1

    run start_server
    [ "$status" -eq 1 ]
    [ $(mock_get_call_num ${DOCKER}) -eq 1 ]
}

@test "Docker Pull Fail" {
    SPINNER=$(mock_create)
    DOCKER=$(mock_create)
    WC=$(mock_create)
    mock_set_output ${WC} "0"

    run start_server
    [ "$status" -eq 2 ]
    [ $(mock_get_call_num ${DOCKER}) -eq 3 ]
}

@test "Docker-Compose Start Fail" {
    SPINNER=$(mock_create)
    DOCKER=$(mock_create)
    WC=$(mock_create)
    DOCKER_COMPOSE=$(mock_create)
    mock_set_output ${WC} "1"
    mock_set_status ${DOCKER_COMPOSE} 1 1

    run start_server
    [ "$status" -eq 3 ]
    [ $(mock_get_call_num ${DOCKER_COMPOSE}) -eq 1 ]
}

@test "Can't Create DB" {
    DELAY=0
    DOCKER=$(mock_create)
    WC=$(mock_create)
    mock_set_output ${WC} "1"
    mock_set_status ${DOCKER} 1 5
    DOCKER_COMPOSE=$(mock_create)

    run start_server
    [ "$status" -eq 5 ]
    [ $(mock_get_call_num ${DOCKER_COMPOSE}) -eq 1 ]
    [ $(mock_get_call_num ${DOCKER}) -eq 5 ]
}

@test "Can't Create Extension" {
    DELAY=0
    DOCKER=$(mock_create)
    mock_set_status ${DOCKER} 1 6
    WC=$(mock_create)
    mock_set_output ${WC} "1"
    DOCKER_COMPOSE=$(mock_create)

    run start_server
    [ "$status" -eq 6 ]
    [ $(mock_get_call_num ${DOCKER_COMPOSE}) -eq 1 ]
    [ $(mock_get_call_num ${DOCKER}) -eq 6 ]
}

@test "Can't Create Table" {
    DELAY=0
    DOCKER=$(mock_create)
    mock_set_status ${DOCKER} 1 7
    WC=$(mock_create)
    mock_set_output ${WC} "1"
    DOCKER_COMPOSE=$(mock_create)

    run start_server
    [ "$status" -eq 7 ]
    [ $(mock_get_call_num ${DOCKER_COMPOSE}) -eq 1 ]
    [ $(mock_get_call_num ${DOCKER}) -eq 7 ]
}

@test "Can't Find Table" {
    DELAY=0
    DOCKER=$(mock_create)
    mock_set_status ${DOCKER} 1 8
    WC=$(mock_create)
    mock_set_output ${WC} "1"
    DOCKER_COMPOSE=$(mock_create)

    run start_server
    [ "$status" -eq 8 ]
    [ $(mock_get_call_num ${DOCKER_COMPOSE}) -eq 1 ]
    [ $(mock_get_call_num ${DOCKER}) -eq 8 ]
}

@test "Server Started, All OK" {
    DELAY=0
    DOCKER=$(mock_create)
    WC=$(mock_create)
    mock_set_output ${WC} "1"
    DOCKER_COMPOSE=$(mock_create)

    run start_server
    [ "$status" -eq 0 ]
    [ $(mock_get_call_num ${DOCKER_COMPOSE}) -eq 1 ]
    echo $(mock_get_call_num ${DOCKER})
    [ $(mock_get_call_num ${DOCKER}) -eq 9 ]
}
