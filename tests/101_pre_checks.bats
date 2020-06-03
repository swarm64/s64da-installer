#!/usr/bin/env bats

setup() {
    . ./lib/101_pre_checks-all.sh
    S64DA_DIR="./s64-tests"
    mkdir ${S64DA_DIR}
    load bats-mock
    BATS_TMPDIR="${S64DA_DIR:-/tmp}"
    OS_VERSION="centos-release-7-7.1908.0.el7.centos.x86_64"
    OS_REGEX="release-([0-9]+)\-([0-9]+)"
}

teardown() {
    rm -rf ./s64-tests
}

@test "Not Super-User" {
    E_USER_ID=123
    run check_user_id
    [ "$status" -eq 0 ]
}

@test "Super-User" {
    E_USER_ID=0
    run check_user_id
    [ "$status" -eq 0 ]
}

@test "No editor" {
    EDITOR=""
    VIM_EDITOR=""
    run check_editor
    [ "$status" -eq 1 ]
}

@test "EDITOR set" {
    EDITOR="/usr/bin/nano"
    VIM_EDITOR=""
    run check_editor
    [ "$status" -eq 0 ]
}

@test "vim installed" {
    EDITOR=""
    VIM_EDITOR="/usr/bin/vim"
    run check_editor
    [ "$status" -eq 0 ]
}

@test "Flavour Ubuntu" {
    OS="ubuntu"
    MAJOR_VERSION=7
    MINOR_VERSION=4
    run check_os_version
    [ "$status" -eq 1 ]
}

@test "Flavour Centos" {
    OS="centos"
    OS_VERSION="centos-release-7-7.1908.0.el7.centos.x86_64"
    OS_REGEX="release-([0-9]+)\-([0-9]+)"
    run check_os_version
    [ "$status" -eq 0 ]
}

@test "Old Minor Version" {
    OS="centos"
    OS_VERSION="centos-release-7-3.1908.0.el7.centos.x86_64"
    OS_REGEX="release-([0-9]+)\-([0-9]+)"
    run check_os_version
    [ "$status" -eq 3 ]
}

@test "New Version" {
    OS="centos"
    OS_VERSION="centos-release-8-3.1908.0.el7.centos.x86_64"
    OS_REGEX="release-([0-9]+)\-([0-9]+)"
    run check_os_version
    [ "$status" -eq 0 ]
}

@test "Old Major Version" {
    OS="centos"
    OS_VERSION="centos-release-6-3.1908.0.el7.centos.x86_64"
    OS_REGEX="release-([0-9]+)\-([0-9]+)"
    run check_os_version
    [ "$status" -eq 2 ]
}

@test "Flavour Red Hat" {
    OS="rhel"
    OS_VERSION="redhat-release-server-7.5-8.el7.x86_64"
    OS_REGEX="server-([0-9]+)\.([0-9]+)"
    run check_os_version
    [ "$status" -eq 0 ]
}

@test "Flavour Arch" {
    OS="arch"
    run check_os_version
    [ "$status" -eq 1 ]
}

###########################################################

@test "No Docker Binary" {
    DOCKER_VERSION="not installed"
    DOCKER_REGEX="([0-9]+)\.([0-9]+)\.([0-9]+)"
    DOCKER_WITH_PATH=""
    DOCKER_BIN_NAME=""
    run check_docker_version
    [ "$status" -eq 1 ]
}

@test "Docker Old Major Version" {
    DOCKER_MINIMUM_MAJOR_VERSION=18                                                                                                                                          
    DOCKER_MINIMUM_MINOR_VERSION=03
    DOCKER_MINIMUM_PATCH=0
    DOCKER_VERSION="Docker version 17.13.12, build a872fc2f86"
    DOCKER_REGEX="([0-9]+)\.([0-9]+)\.([0-9]+)"
    DOCKER_WITH_PATH="/usr/bin/docker"

    run check_docker_version
    [ "$status" -eq 2 ]
} 

@test "Docker Old Minor Version" {
    DOCKER_MINIMUM_MAJOR_VERSION=18                                                                                                                                          
    DOCKER_MINIMUM_MINOR_VERSION=03
    DOCKER_MINIMUM_PATCH=0
    DOCKER_VERSION="Docker version 18.01.12, build a872fc2f86"
    DOCKER_REGEX="([0-9]+)\.([0-9]+)\.([0-9]+)"
    DOCKER_WITH_PATH="/usr/bin/docker"

    run check_docker_version
    [ "$status" -eq 3 ]
} 
 
@test "Docker Not Running" {
    DOCKER_VERSION="Docker version 19.03.3, build a872fc2f86"
    DOCKER_REGEX="([0-9]+)\.([0-9]+)\.([0-9]+)"
    DOCKER_WITH_PATH="/usr/bin/docker"
    LOG="${S64DA_DIR}/bats.log"

    DOCKER=$(mock_create)
    mock_set_status ${DOCKER} 1

    run check_docker_version
    [ "$status" -eq 4 ]
}

@test "Docker Binary" {
    DOCKER_VERSION="Docker version 19.03.3, build a872fc2f86"
    DOCKER_REGEX="([0-9]+)\.([0-9]+)\.([0-9]+)"
    DOCKER_WITH_PATH="/usr/bin/docker"
    LOG="${S64DA_DIR}/bats.log"

    DOCKER=$(mock_create)

    run check_docker_version
    [ "$status" -eq 0 ]
}

###########################################################
 
@test "No Docker-Compose Binary" {
    DOCKER_COMPOSE_WITH_PATH=""

    run check_docker_compose_version
    [ "$status" -eq 3 ]
}
 
@test "Docker-Compose Binary" {
    DOCKER_COMPOSE_WITH_PATH="/usr/local/bin/docker-compose"

    run check_docker_compose_version
    [ "$status" -eq 3 ]
}
