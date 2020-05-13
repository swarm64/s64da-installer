#!/bin/bash

function show_edit_pgconfig_init {
    EDIT_FILE='edit_file'
    PG_CONF='postgresql_env.conf'
    PG_CONF_TEMPLATE='templates/postgresql_env.conf.template'
    cp ${PG_CONF_TEMPLATE} ${PG_CONF_TEMPLATE}.tmp

    return 0
}


function show_edit_pgconfig {
    ${EDIT_FILE} ${PG_CONF} ${PG_CONF_TEMPLATE}.tmp
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    return 0
}
