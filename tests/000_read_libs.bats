#!/usr/bin/env bats

setup() {
    # We store the names of the loaded functions in an array here 
    # in order to check that they are loaded.
    FUNCTION_NAMES=()

    # This code is the same as the readlib function in install.sh
    # and is loaded here to check the loading of the functions.
    for file in lib/*.sh; do 
        if [ -f "$file" ]; then 
            . "$file"
        fi
    done

    # Load the shell's function names into the array so we can check 
    # for their presence
    for FUNCTION_NAME in $(typeset -F | awk '/declare/ {print $3}'); do
        FUNCTION_NAMES+=($FUNCTION_NAME)
    done
}

@test "Check OS Version Function Loaded" {
    [[ " ${FUNCTION_NAMES[@]} " =~ "check_os_version" ]]
    [[ " ${FUNCTION_NAMES[@]} " =~ "check_os_version_init" ]]
}

@test "Check Docker Version Function Loaded" {
    [[ " ${FUNCTION_NAMES[@]} " =~ "check_docker_version" ]]
    [[ " ${FUNCTION_NAMES[@]} " =~ "check_docker_version_init" ]]
}
