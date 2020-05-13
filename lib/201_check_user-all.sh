#!/bin/bash

function check_user_init {
    log_info "Checking REPO.SWARM64.COM to access ${PRODUCT_NAME} mandatory packages"
    REPO_FILE='/etc/yum.repos.d/s64da-install-artifactory.repo'
    REPO_ID='s64da-installer'
    REQUIRE_LOGIN='TRUE'

    if [[ -f ${REPO_FILE} ]] ; then
        read -r -p "Found existing repository file for repo.swarm64.com at ${REPO_FILE}. Would you like to use this login ? [y/N] " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            REQUIRE_LOGIN='FALSE'
            USERNAME=$( grep -oE :.*@ ${REPO_FILE} | grep -oE [a-Z0-9]+ | head -1 )
            PASSWORD=$( grep -oE :.*@ ${REPO_FILE} | grep -oE [a-Z0-9]+ | tail -1 )
        fi
    fi

    if [[ ${REQUIRE_LOGIN} == 'TRUE' ]]; then
        read -p "Enter username: " USERNAME
        read -s -p "Enter password: " PASSWORD
        echo
    fi

    BASEURL="https://${USERNAME}:${PASSWORD}@repo.swarm64.com/artifactory/s64-public-rpm/"
    REPO_CHECK=$(curl -I -s -o /dev/null -w %{http_code} ${BASEURL})

    return 0
}


function check_user {
    if [[ ${IS_SUPER_USER} == "TRUE" ]]; then
        cat templates/swarm64-temporary.template > ${REPO_FILE}
        sed -i "s#__REPO_ID__#${REPO_ID}#g" "${REPO_FILE}"
        sed -i "s#__BASEURL__#${BASEURL}#g" "${REPO_FILE}"

        if [[ ! -f ${REPO_FILE} ]]; then
            log_error "The file ${REPO_FILE} could not be written"
            return 1
        else
            log_info "Added Swarm64 repository file at ${REPO_FILE}"
        fi
    else
        log_info "Not a super user. Skip adding Swarm64 repository file"
    fi
    if [[ ${REPO_CHECK} != "200" ]]; then
        log_error "Syncing with the repo failed, please check username and password or contact support@swarm64.com"
        rm ${REPO_FILE}
        return 2
    fi
    log_success "Repo authentication successful, installing packages"

    return 0
}
