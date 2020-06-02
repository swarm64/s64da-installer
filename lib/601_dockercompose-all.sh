#!/bin/bash

function show_edit_docker_compose_init {
    EDIT_FILE='edit_file'
    CONTAINER_NAME='swarm64da_container'
    DOCKER_COMPOSE_YML='docker-compose.yml'
    REPO="repo.swarm64.com"
    # Only for testing release candidates
    #RELEASE_CANDIDATE_PREVIEW_TAG="-preview"
    #RELEASE_CANDIDATE_VERSION_TAG="-rc1"
    SWARM64DA_VERSION=${SWARM64DA_RELEASE_VERSION}${RELEASE_CANDIDATE_VERSION_TAG}
    DEFAULT_DATA_DIR="/mnt/data"

    case ${TARGET_DEVICE} in
        "pac-a10")
            SWARM64DA_IMAGE="swarm64da-${TARGET_DEVICE}-psql-11${RELEASE_CANDIDATE_PREVIEW_TAG}"
            DOCKER_COMPOSE_TEMPLATE='templates/docker-compose-fpga.template'
            ;;
        "u50"|"u200"|"u250")
            SWARM64DA_IMAGE="swarm64da-alveo-${TARGET_DEVICE}-psql-11${RELEASE_CANDIDATE_PREVIEW_TAG}"
            DOCKER_COMPOSE_TEMPLATE='templates/docker-compose-fpga.template'
            ;;
        "smartssd")
            SWARM64DA_IMAGE="swarm64da-samsung-${TARGET_DEVICE}-psql-11${RELEASE_CANDIDATE_PREVIEW_TAG}"
            DOCKER_COMPOSE_TEMPLATE='templates/docker-compose-fpga.template'
            ;;            
        "cpu")
            SWARM64DA_IMAGE="swarm64da-cpu-psql-11${RELEASE_CANDIDATE_PREVIEW_TAG}"
            DOCKER_COMPOSE_TEMPLATE='templates/docker-compose-cpu.template'
            ;;
        *)
            log_error "Problem finding image ${SWARM64DA_IMAGE} version ${SWARM64DA_VERSION}, exiting"
            ;;
    esac

    DOCKER_COMPOSE_YML="docker-compose-${SWARM64DA_IMAGE}.yml"

    echo
    read -p "Enter the directory to use for the data, or leave empty for the default (${DEFAULT_DATA_DIR}): " DATA_DIR
    if [[ -z ${DATA_DIR} ]]; then
        log_info "No data directory given. Using the default: ${DEFAULT_DATA_DIR}"
        DATA_DIR=${DEFAULT_DATA_DIR}
    fi

    if [[ ! ${DATA_DIR} =~ ^/.+ ]]; then
        log_error "Data directory path must be absolute"
        return 2
    fi

    if ! stat -t $(dirname ${DATA_DIR}) > /dev/null 2>&1; then
        log_error "Data directory must be in an existing path"
        return 3
    fi

    # Do the replacements

    sed "s#__DATA_DIR__#${DATA_DIR}#g; s#__CONTAINER_NAME__#${CONTAINER_NAME}#g; s#__DB_IMAGE_S64DA__#${REPO}/${SWARM64DA_IMAGE}:${SWARM64DA_VERSION}#g" \
    "${DOCKER_COMPOSE_TEMPLATE}" > ${DOCKER_COMPOSE_TEMPLATE}.tmp

    local BUFFER='      - \'
    local IDX_START=$(expr ${#DEVICES_BDF_LIST[@]} - 1)
    for IDX in $(seq ${IDX_START} -1 0); do
        insert_after 'volumes:' "${BUFFER}${DEVICES_BDF_LIST[${IDX}]}:${DEVICES_BDF_LIST[${IDX}]}" ${DOCKER_COMPOSE_TEMPLATE}.tmp
    done

    IDX_START=$(expr ${#DEVICES_PORT_LIST[@]} - 1)
    for IDX in $(seq ${IDX_START} -1 0); do
        insert_after 'devices:' "${BUFFER}${DEVICES_PORT_LIST[${IDX}]}:${DEVICES_PORT_LIST[${IDX}]}" ${DOCKER_COMPOSE_TEMPLATE}.tmp
        insert_after 'devices:' "${BUFFER}${DEVICES_LIST[${IDX}]}:${DEVICES_LIST[${IDX}]}" ${DOCKER_COMPOSE_TEMPLATE}.tmp
    done

    return 0
}


function show_edit_docker_compose {
    # Editing docker compose disabled for now
    #${EDIT_FILE} ${DOCKER_COMPOSE_YML} ${DOCKER_COMPOSE_TEMPLATE}.tmp
    #if [[ $? -ne 0 ]]; then
    #    return 1
    #fi
    mv ${DOCKER_COMPOSE_TEMPLATE}.tmp config/${DOCKER_COMPOSE_YML} 2>>${LOG}

    return 0
}
