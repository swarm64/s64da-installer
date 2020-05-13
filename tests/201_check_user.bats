#!/usr/bin/env bats

setup() {
    . ./lib/201_check_user-all.sh
    S64DA_DIR="./s64-tests"
    mkdir ${S64DA_DIR}
    BATS_TMPDIR="${S64DA_DIR:-/tmp}"
}

teardown() {
    rm -rf ./s64-tests
}


@test "Successful login" {
    REPO_FILE='/tmp/s64da-temp-artifactory.repo'
    REPO_ID='s64da-installer'
    BASEURL=https://qwe.asd
    REPO_CHECK="200"
    run check_user
    [ "$status" -eq 0 ]
}

@test "Unsuccessful login" {
    REPO_FILE='/tmp/s64da-temp-artifactory.repo'
    REPO_ID='s64da-installer'
    BASEURL=https://qwe.asd
    REPO_CHECK="401"
    run check_user
    [ "$status" -eq 2 ]
}
