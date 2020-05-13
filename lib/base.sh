#!/bin/bash
if [[ ! -e ./log ]]; then
    mkdir log
fi

PRODUCT_NAME="Swarm64 DA"
PRODUCT_NAME_SHORT="S64 DA"
INSTALLER_NAME="${PRODUCT_NAME} Installer"
LOG=log/$(date +"%Y-%m-%d_%H-%M-%S_s64da-installer.log")
echo "${INSTALLER_NAME}" > ${LOG}

function load_colours() {
    GREEN='\033[0;32m'
    BLUE='\033[0;36m'
    RED='\033[0;31m'
    YEL='\033[0;33m'
    NC='\033[0m'
}


function cleanup() {
    rm -f templates/*.tmp
    printf "${NC} Exiting\n"
    exit 1
}
trap cleanup  1 2 3 6


function log_info() {
    printf "${BLUE}${1}${NC}\n" | tee -a ${LOG}
}


function log_error() {
    printf "${RED}${1}\nFor More information revisit the log-file at: ${LOG}${NC}\n" | tee -a ${LOG}
    printf "${RED}If the issue appears after 'yum update' and/or driver installation, reboot and try again.${NC}\n" | tee -a ${LOG}
    printf "${RED}If the issue persists contact support@swarm64.com and provide the log file${NC}\n" | tee -a ${LOG}
    echo "==== START DUMP of GIT status and diff" >> ${LOG}
    git status >> ${LOG}
    git diff >> ${LOG}
    echo "==== END DUMP of GIT status and diff" >> ${LOG}
}


function log_warn() {
    printf "${YEL}${1}${NC}\n" | tee -a ${LOG}
}


function log_success() {
    printf "${GREEN}${1}${NC}\n" | tee -a ${LOG}
}


function load_tasks() {
    TASKS=()
    for FL in $(ls lib/ | grep -E '^[0-9]{1,3}_'); do 
        local TASKNAME=$(echo ${FL} | sed s/.sh$//)
        TASKS+=(${TASKNAME})
    done
}


function clear_stdin() {
  local DUMMY
  read -r -t 1 -n 100000 DUMMY
}


function no_entry_exists() {
    local ENTRY_EXISTS=$(awk -v device_entry="${1}" '$0 ~ device_entry {count++} END {print count}' ${2} 2>>${LOG})
    if [[ "x${ENTRY_EXISTS}" == "x" ]]; then
        return 0
    else
        return 1
    fi
}


function insert_after() {
    # Only add entry if it doesn't already exist
    if no_entry_exists "${2}" "${3}" ; then
        sed -i "/${1}/a\\${2}" ${3}
    fi
}


function spinner() {
    local SPIN='-\|/'

    local IDX=0
    while kill -0 $1 2>/dev/null
    do
      IDX=$(( (IDX+1) %4 ))
      printf "${GREEN}\r${SPIN:${IDX}:1}"
      printf "\033[1D"
      sleep .1
    done
    printf "\r"
}


function edit_file() {
    local CONFIG_FILE=${1}
    local TEMPLATE=${2}
    echo
    log_info "Editing ${CONFIG_FILE}, if you're happy with the entries just quit"
    log_info "If you want to make changes, save and quit after that"
    read -r -p "Do you want to edit this file? [y/N] " response

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        ${EDITOR:-vim} ${TEMPLATE}
    fi

    mv ${TEMPLATE} config/${CONFIG_FILE} 2>>${LOG}
    if [[ $? -ne 0 ]]; then
        log_error "There was a problem saving ${CONFIG_FILE} to the config directory.
Remove the file config/${CONFIG_FILE} if it already exists and try again."
        return 1
    fi

    return 0
}


function read_steps() {
    # Execute all functions in the numbered scripts except '-intel.sh' or '-xilinx.sh'
    if [[ ${1} == "cpu" ]]; then
        for FUNC_NAME in $(ls -d lib/* | grep -E [0-9]+ | grep -Ev 'intel|xilinx' | xargs awk '/function*/ {print $2}'); do
            ${FUNC_NAME} || exit 1
        done
        return 0
    fi
    # Execute all functions in the numbered scripts excluding '-xilinx.sh'
    if [[ ${1} == "intel" ]]; then
        for FUNC_NAME in $(ls -d lib/* | grep -E [0-9]+ | grep -Ev 'xilinx' | xargs awk '/function*/ {print $2}'); do
            ${FUNC_NAME} || exit 1
        done
        return 0
    fi
    # Execute all functions in the numbered scripts excluding '-intel.sh'
    if [[ ${1} == "xilinx" ]]; then
        for FUNC_NAME in $(ls -d lib/* | grep -E [0-9]+ | grep -Ev 'intel' | xargs awk '/function*/ {print $2}'); do
            ${FUNC_NAME} || exit 1
        done
        return 0
    fi

}


function tasks_list() {
    clear
    while true; do
        echo "################################"
        echo "#    ${INSTALLER_NAME}      #"
        echo "#    Tasks Sub-menu            #"
        echo "################################"
        echo

        clear_stdin
        PS3='Sub-Menu: Select an option: ' 
        local OPTIONS=( ${TASKS[*]} "Exit")

        select TASK in "${OPTIONS[@]}"; do
            case ${TASK} in
                "Exit")
                    break 3
                    ;; 
                *) 
                    if [[ "X${TASK}" != "X" ]]; then
                        for FUNC_NAME in $(ls -d lib/* | grep -E [0-9]+ | grep $TASK | xargs awk '/function*/ {print $2}'); do
                            ${FUNC_NAME} || exit 1
                        done
                    else
                        echo "Task not found"
                    fi
                    break
                    ;;
            esac
        done
        echo
        echo "Returning to Sub-Menu"
        sleep 5
        clear
    done
}


function main_menu() {
    clear
    load_colours
    while true; do
        echo "##################################"
        echo "#     ${INSTALLER_NAME}       #"
        echo "#     Main Menu                  #"
        echo "##################################"
        echo
   
        clear_stdin
        PS3='Main Menu: Select an option: ' 
        local OPTIONS=( "Run the installation" "Run single task" "Exit")
        load_tasks
       
        select OPT in "${OPTIONS[@]}"; do
            case ${OPT} in
                "Run the installation") 
                    echo "Installing ${PRODUCT_NAME} for ${ACCELERATION} ${TARGET_DEVICE}" 
                    echo
                    read_steps ${ACCELERATION}
                    break
                    ;;
                "Run single task")
                    tasks_list
                    break
                    ;;
                "Exit")
                    echo "Exiting ${PRODUCT_NAME} Installer"
                    exit 0
            esac
        done
        echo
        echo "Returning to Main Menu"
        clear
    done
}
