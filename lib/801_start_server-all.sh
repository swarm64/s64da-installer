#!/bin/bash

function start_server_init {
    SPINNER='spinner'
    WC='wc'
    GREP='grep'
    DOCKER_PS="${DOCKER} ps"
    DELAY=10
    DB_NAME='swarm64da_test_db'
    TABLE_NAME='test_table'
    TABLE_COLUMNS='year DATE, name INT NOT NULL, col2 VARCHAR(30)'
    TABLE_OPTIONS="optimized_columns '    \"year\", \"name\"'"

    return 0
}


function start_server {
    log_info "Connecting to repo"
    ${DOCKER} login -u ${USERNAME} -p ${PASSWORD} ${REPO} 2>>${LOG}
    if [[ $? -ne 0 ]]; then
        log_error "Couldn't connect to repo ${REPO}"
        return 1
    fi

    IMAGE=${REPO}/${SWARM64DA_IMAGE}:${SWARM64DA_VERSION}
    log_info "Pulling image ${IMAGE}"
    ${DOCKER} pull ${IMAGE} >>${LOG} 2>&1 &
    ${SPINNER} $!

    IMAGE_PRESENT=$(${DOCKER} images -q ${REPO}/${SWARM64DA_IMAGE}:${SWARM64DA_VERSION} | ${WC} -l)
    if [[ ${IMAGE_PRESENT} == 0 ]]; then
        log_error "Failed to pull image ${REPO}/${SWARM64DA_IMAGE}:${SWARM64DA_VERSION}"
        return 2
    fi


    # Stop if a container with the same name is already running
    ${DOCKER_PS} | ${GREP} "CONTAINER_NAME"
    if [[ $? -eq 0 ]]; then
        log_error "A container with name ${CONTAINER_NAME} is already running"
        return 3
    fi

    COMPOSE_CMD="${DOCKER_COMPOSE} -f ${DOCKER_COMPOSE_YML} up -d"
    log_info "Starting ${PRODUCT_NAME_SHORT}"
    log_info "Command used is: $COMPOSE_CMD"
    ${COMPOSE_CMD} 2>>${LOG}
    if [[ $? -ne 0 ]]; then
        log_error "Couldn't start the ${PRODUCT_NAME_SHORT} docker container
You can try to start the container manually with:\n${COMPOSE_CMD}

Please verify your docker-compose installation. Consult the Swarm64 DA user-guide

In many cases the issue can likely be resolved by executing the following commands:
 sudo rpm -e --nodeps python-urllib3
 sudo rpm -e --nodeps python-requests
 sudo pip uninstall -y urllib3
 sudo yum install -y python-urllib3
 sudo yum install -y python-requests

Make sure all packages remove/install properly. If the problem persists, contact support@swarm64.com"
        return 3
    fi
    log_success "${PRODUCT_NAME_SHORT} instance with the name ${CONTAINER_NAME} started"

    local COUNT=0
    log_info "Container log files can be checked with \'docker logs ${CONTAINER_NAME}\'"
    log_info "Waiting for postgres.."
    while true; do

        # Check if the container is still there
        ${DOCKER_PS} | ${GREP} ${CONTAINER_NAME} > /dev/null
        if [[ $? -ne 0 ]]; then
            ${DOCKER} logs ${CONTAINER_NAME} >> ${LOG}
            log_error "Container ${CONTAINER_NAME} stopped unexpectedly"
            return 3
        fi

        # Try to connect to postgres
        ( ${DOCKER} exec -it ${CONTAINER_NAME} psql -U postgres -c "\l" -o /dev/null ) >>${LOG} && break
        sleep ${DELAY:-5} &
        ${SPINNER} $!
        let "COUNT++"
        if [[ ${COUNT} -ge 10 ]]; then 
            log_error "Couldn't contact ${DB_NAME} database"
            ${DOCKER} logs ${CONTAINER_NAME} >> ${LOG}
            return 4
        fi
    done

    log_success "Connection to postgres established. Running a smoke-test..."

    ${DOCKER} exec -it ${CONTAINER_NAME} psql -U postgres -c "CREATE DATABASE ${DB_NAME}" >>${LOG}
    if [[ $? -ne 0 ]]; then
        log_error "Couldn't create ${DB_NAME} database"
        return 5
    fi
    log_success "- test database ${DB_NAME} created"

    ${DOCKER} exec -it ${CONTAINER_NAME} psql -U postgres -d ${DB_NAME} -c "CREATE EXTENSION swarm64da" >>${LOG}
    if [[ $? -ne 0 ]]; then
        log_error "Couldn't create swarm64da extension"
        return 6
    fi
    log_success "- extension swarm64da created"

    ${DOCKER} exec -it ${CONTAINER_NAME} psql -U postgres -d ${DB_NAME} -c "CREATE FOREIGN TABLE ${TABLE_NAME} (${TABLE_COLUMNS}) SERVER swarm64da_server OPTIONS (${TABLE_OPTIONS})" >>${LOG}
    if [[ $? -ne 0 ]]; then
        log_error "Couldn't create test table on ${DB_NAME} database"
        return 7
    fi
    log_success "- table ${TABLE_NAME} created"

    ( ${DOCKER} exec -it ${CONTAINER_NAME} psql -U postgres -d ${DB_NAME} -c "SELECT '${TABLE_NAME}'::regclass" -o /dev/null ) >>${LOG}
    if [[ $? -ne 0 ]]; then
        log_error "Couldn't find test table on ${DB_NAME} database"
        return 8
    fi
    log_success "- table ${TABLE_NAME} checked"

    ${DOCKER} exec -it ${CONTAINER_NAME} psql -U postgres -c "DROP DATABASE ${DB_NAME}" >>${LOG}
    if [[ $? -ne 0 ]]; then
        log_error "Couldn't drop ${DB_NAME} database"
        return 8
    fi
    log_success "- test database ${DB_NAME} dropped"

    log_success "
***
${PRODUCT_NAME} instance started and verified
Check the status of the docker container with \'docker ps\'
Check the docker log files with \'docker logs ${CONTAINER_NAME}\'

Connect to PSQL eg. with \'psql -U postgres -h localhost\'
***"
    exit 0
}
