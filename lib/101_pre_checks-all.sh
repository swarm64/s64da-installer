#!/bin/bash


function check_user_id_init {
    E_USER_ID=$(id -u 2>>${LOG})
    if [[ ${E_USER_ID} == "0" ]]; then
        IS_SUPER_USER="TRUE"
    else
        # Currently only executing with sudo rights is supported
        log_error "Script must be run with sudo rights (sudo ./install.sh ...)"
        return 1
    fi
    return 0
}


function check_user_id {
    log_info "Checking UID"
    if [[ ${IS_SUPER_USER} != "TRUE" ]]; then
        log_success "Running installer as normal user. Yum packages will not be installed."
    else
        log_success "Running as Super-User"
    fi

    return 0
}

function setup_environment {
    log_info "Setting up Environment"
    PATH=$PATH:/usr/local/bin/
}

function check_editor_init {
    log_info "Checking for vim"
    VIM_EDITOR=$(which vim 2>>${LOG})
    return 0
}


function check_editor {
    if [[ "x${EDITOR}" == "x" && "x${VIM_EDITOR}" == "x" ]]; then
        log_error "The EDITOR variable is not set and vim cannot be found \
Set the EDITOR to the program you wish to use for editing the config files"
        return 1
    fi

    log_success "${EDITOR:-vim} will be used to edit files"
    return 0
}


function yum_dependencies {
    if [[ "${ACCELERATION}" != "cpu" ]]; then
        log_info "Installing required kernel packages and other dependencies"
        PACKAGES="epel-release kernel-devel kernel-headers"
        for PACKAGE in ${PACKAGES}; do
            log_info "Installing ${PACKAGE}"
            yum install -y "${PACKAGE}" &>> ${LOG} &
            spinner $!

            PACKAGE_PRESENT=$(yum list -q installed 2> ${LOG} | grep -E ${PACKAGE} | wc -l)
            if [[ "${PACKAGE_PRESENT}" == "0" ]]; then
                log_error "Installation of ${PACKAGE} failed"
                return 2
            fi

        done
    fi
}


function check_os_version_init {
    log_info "Checking OS version"
    OS=$(cat /etc/os-release | awk -F= '/^ID=/ {gsub(/"/, "", $2); print $2}')

    if [[ "${OS}" == "centos" ]]; then
        OS_VERSION=$(rpm -q centos-release 2>>${LOG})
        if [[ $? != 0 ]]; then
            log_error "Couldn't get OS version (centos)"
            return 1
        fi

        OS_REGEX="release-([0-9]+)[-.]+([0-9]+)"
    fi

    if [[ "${OS}" == "rhel" ]]; then
        OS_VERSION=$(rpm -q redhat-release-server 2>>${LOG})
        if [[ $? != 0 ]]; then
            log_error "Couldn't get OS version (rhel)"
            return 2
        fi

        OS_REGEX="server-([0-9]+)[-.]([0-9]+)"
    fi
    
    return 0
}


function check_os_version {
    [[ "$OS_VERSION" =~ $OS_REGEX ]]
    local MAJOR_VERSION=${BASH_REMATCH[1]}
    local MINOR_VERSION=${BASH_REMATCH[2]}

    local OS_MINIMUM_MAJOR_VERSION=7
    local OS_MINIMUM_MINOR_VERSION=4

    if [[ "${OS}" != "centos" && ${OS} != "rhel" ]]; then
        log_error "OS must be either CentOS or RHEL ${OS_MINIMUM_MAJOR_VERSION}.${OS_MINIMUM_MINOR_VERSION} or higher"
        return 1
    fi

    if [[ ${MAJOR_VERSION} -lt ${OS_MINIMUM_MAJOR_VERSION} ]]; then
        log_error "Wrong OS version detected: ${MAJOR_VERSION}.${MINOR_VERSION}, at least ${OS_MINIMUM_MAJOR_VERSION}.${OS_MINIMUM_MINOR_VERSION} is required"
        return 2
    fi

    if [[ ${MAJOR_VERSION} -eq ${OS_MINIMUM_MAJOR_VERSION} && ${MINOR_VERSION} -lt ${OS_MINIMUM_MINOR_VERSION} ]]; then
        log_error "Wrong OS version detected: ${MAJOR_VERSION}.${MINOR_VERSION}, at least ${OS_MINIMUM_MAJOR_VERSION}.${OS_MINIMUM_MINOR_VERSION} is required"
        return 3
    fi

    log_success "OS version OK (${OS_VERSION})"
    return 0
}


function check_docker_version_init {
    log_info 'Checking for Docker'

    DOCKER_MINIMUM_MAJOR_VERSION=18
    DOCKER_MINIMUM_MINOR_VERSION=03
    DOCKER_MINIMUM_PATCH=0

    DOCKER_WITH_PATH=$(which docker 2>>${LOG})
    if [[ $? != 0 ]]; then
        log_error "There was a problem finding the docker executable, docker \
${DOCKER_MINIMUM_MAJOR_VERSION}.${DOCKER_MINIMUM_MINOR_VERSION}.${DOCKER_MINIMUM_PATCH} minimum is required, exiting"
        return 1
    fi

    DOCKER=$(basename ${DOCKER_WITH_PATH} 2>>${LOG})
    DOCKER_REGEX="([0-9]+)\.([0-9]+)\.([0-9]+)"
    DOCKER_VERSION=$(docker --version 2>>${LOG})
    if [[ $? != 0 ]]; then
        log_error "There was a problem finding the docker version, docker \
${DOCKER_MINIMUM_MAJOR_VERSION}.${DOCKER_MINIMUM_MINOR_VERSION}.${DOCKER_MINIMUM_PATCH} minimum is required, exiting"
        return 2
    fi


    return 0
}


function check_docker_version {
    log_info 'Checking Docker version'

    [[ "${DOCKER_VERSION}" =~ ${DOCKER_REGEX} ]]
    local DOCKER_MAJOR_VERSION=${BASH_REMATCH[1]#0}
    local DOCKER_MINOR_VERSION=${BASH_REMATCH[2]#0}
    local DOCKER_PATCH=${BASH_REMATCH[3]}

    if [[ "x${DOCKER_WITH_PATH}" == "x" ]]; then
        log_error "Can't find docker in execution path"
        return 1
    fi

    if [[ ${DOCKER_MAJOR_VERSION} -lt ${DOCKER_MINIMUM_MAJOR_VERSION} ]]; then
        log_error "Wrong docker version detected: ${DOCKER_MAJOR_VERSION}.${DOCKER_MINOR_VERSION}.${DOCKER_PATCH} \
at least ${DOCKER_MINIMUM_MAJOR_VERSION}.${DOCKER_MINIMUM_MINOR_VERSION}.${DOCKER_MINIMUM_PATCH} is required"
        return 2
    fi

    if [[ ${DOCKER_MAJOR_VERSION} -eq ${DOCKER_MINIMUM_MAJOR_VERSION} && ${DOCKER_MINOR_VERSION} -lt ${DOCKER_MINIMUM_MINOR_VERSION} ]]; then
        log_error "Wrong docker version detected: ${DOCKER_MAJOR_VERSION}.${DOCKER_MINOR_VERSION}.${DOCKER_PATCH} \
at least ${DOCKER_MINIMUM_MAJOR_VERSION}.${DOCKER_MINIMUM_MINOR_VERSION}.${DOCKER_MINIMUM_PATCH} is required"
        return 3
    fi

    # Check that docker is running
    ${DOCKER} info &>>${LOG}
    if [[ $? -ne 0 ]]; then
        log_error 'The docker daemon is not running'
        return 4
    fi

    log_success "Docker version ok (${DOCKER_VERSION})"
    return 0
}

function check_docker_compose_version_init {
    log_info "Checking for Docker-Compose"
    DOCKER_COMPOSE_WITH_PATH=$(which docker-compose 2>>${LOG})
    if [[ $? != 0 ]]; then
        log_error 'There was a problem finding the docker-compose executable, exiting'
        return 1
    fi

    DOCKER_COMPOSE=$(basename ${DOCKER_COMPOSE_WITH_PATH} 2>>${LOG})
    if [[ $? != 0 ]]; then
        log_error "Couldn't get docker-compose name"
        return 2
    fi

    return 0
}


function check_docker_compose_version {
    log_info "Checking Docker-Compose version"

    $DOCKER_COMPOSE_WITH_PATH --version >>${LOG}
    if [[ $? != 0 ]]; then
        log_error "Couldn't get docker-compose version"
        return 3
    fi

    if [[ "x${DOCKER_COMPOSE_WITH_PATH}" == "x" ]]; then
        log_error "Can't find docker-compose in execution path"
        return 1
    fi

    log_success "Docker-Compose ok (${DOCKER_COMPOSE_WITH_PATH})"
    return 0
}
