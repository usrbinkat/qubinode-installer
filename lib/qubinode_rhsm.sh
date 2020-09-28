#!/bin/bash 
set -xe 

# this function checks if the system is registered to RHSM
# validate the registration or register the system
# if it's not registered
function qubinode_rhsm_register () {
    sudo subscription-manager register
}

# Check the Red Hat identity
function check_rhsm_identity(){
    IS_REGISTERED_tmp=$(mktemp)
    sudo subscription-manager  identity > "${IS_REGISTERED_tmp}" 2>&1
    IS_REGISTERED=$(grep -o 'This system is not yet registered' "${IS_REGISTERED_tmp}")
    {
        IS_REGISTERED_tmp=$(mktemp)
        sudo subscription-manager  identity > "${IS_REGISTERED_tmp}" 2>&1
        IS_REGISTERED=$(grep -o 'This system is not yet registered' "${IS_REGISTERED_tmp}")

        if [ "A${IS_REGISTERED}" == "AThis system is not yet registered" ]
        then
            printf "%s\n" " ${red}This system is not yet registered to Red Hat.${end}"
            printf "%s\n\n" " Please check your server status for ${HOSTNAME} at : ${grn}https://access.redhat.com/management/systems${end}"
            printf "%s\n\n" " Please run: ${grn}./qubinode-installer -m clean && ./qubinode-installer -m rhsm${end}"
            qubinode_rhsm_register
        else
          printf "%s\n\n${grn}The system is registered${end}"
        fi
    } || {
        printf "%s\n" " ${red}This system is not yet registered to Red Hat.${end}"
        printf "%s\n\n" " Please check your server status for ${HOSTNAME} at : ${grn}https://access.redhat.com/management/systems${end}"
        printf "%s\n\n" " Please run: ${grn}./qubinode-installer -m clean && ./qubinode-installer -m rhsm${end}"
        exit 1
    }

}

# This function checks the status of RHSM registration
function check_rhsm_status () {
    {
        IS_REGISTERED_tmp=$(mktemp)
        sudo subscription-manager refresh
        sudo subscription-manager status > "${IS_REGISTERED_tmp}" 2>&1
        
        IS_IDENTITY_CORRECT_tmp=$(mktemp)
        sudo subscription-manager identity > "${IS_IDENTITY_CORRECT_tmp}" 2>&1

        if  cat ${IS_REGISTERED_tmp}  | grep 'Overall Status: Current' > /dev/null 2>&1  &&  cat ${IS_IDENTITY_CORRECT_tmp}  | grep 'system identity:' > /dev/null 2>&1;
        then
            printf "%s\n\n${grn}The system is registered${end}"
            printf "%s\n\n" " Your ${HOSTNAME}: ${grn}Overall Status: Current${end}"
        elif cat ${IS_REGISTERED_tmp}  | grep 'Overall Status: Current' > /dev/null 2>&1  &&  cat ${IS_IDENTITY_CORRECT_tmp}  | grep 'has been deleted' > /dev/null 2>&1; 
        then
            printf "%s\n" " ${red}This system is not yet registered to Red Hat.${end}"
            printf "%s\n\n" " Please check your server status for ${HOSTNAME} at : ${grn}https://access.redhat.com/management/systems${end}"
            printf "%s\n\n" " Please run: ${grn}./qubinode-installer -m clean && ./qubinode-installer -m rhsm${end}"
            sudo subscription-manager clean
            sudo subscription-manager refresh
            qubinode_rhsm_register
        elif cat ${IS_REGISTERED_tmp}  | grep 'Overall Status: Invalid' > /dev/null 2>&1  &&  cat ${IS_IDENTITY_CORRECT_tmp}  | grep 'has been deleted' > /dev/null 2>&1; 
        then 
            printf "%s\n" " ${red}This system is not yet registered to Red Hat.${end}"
            printf "%s\n\n" " Please check your server status for ${HOSTNAME} at : ${grn}https://access.redhat.com/management/systems${end}"
            printf "%s\n\n" " Please run: ${grn}./qubinode-installer -m clean && ./qubinode-installer -m rhsm${end}"
            sudo subscription-manager clean
            sudo subscription-manager refresh
            sudo subscription-manager register --force 
        elif cat ${IS_REGISTERED_tmp}  | grep 'Overall Status: Invalid' > /dev/null 2>&1  &&  cat ${IS_IDENTITY_CORRECT_tmp}  | grep 'system identity' > /dev/null 2>&1; 
        then 
            printf "%s\n" " ${red}This system is not yet registered to Red Hat.${end}"
            printf "%s\n\n" " Please check your server status for ${HOSTNAME} at : ${grn}https://access.redhat.com/management/systems${end}"
            printf "%s\n\n" " You may also run subscription-manager attach --auto && ./qubinode-installerv2.sh . If the machine is reported as not attached${end}"    
            exit 1
        else
            printf "%s\n" " ${red}This system is not yet registered to Red Hat.${end}"
            printf "%s\n\n" " Please check your server status for ${HOSTNAME} at : ${grn}https://access.redhat.com/management/systems${end}"
            printf "%s\n\n" " Please run: ${grn}./qubinode-installer -m clean && ./qubinode-installer -m rhsm${end}"
            exit 1
        fi
    } ||
    {
        echo "Testing"
    }
    
}




