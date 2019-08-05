#!/usr/bin/env bash
# This script will start the automated depoyment of openshift home lab

# Uncomment for debugging
#export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
#set -x

function display_help() {
    SCRIPT=$(basename "${BASH_SOURCE[0]}")

    cat << EOH >&2
Basic usage: ${SCRIPT} [options]
    -p      Deploy okd or ocp: default is ocp
                   ---    ---             ---
    -s      Skip DNS server deployment
    -u      Skip creating DNS entries
    -h      Display this help menu
EOH
}

function check_args () {
    if [[ $OPTARG =~ ^-[h/p/u/s]$ ]]
    then
      echo "Invalid option argument $OPTARG, check that each argument has a value." >&2
      exit 1
    fi
}

function deploy_dns_server () {
    if [ "A${skip_dns}" != "Atrue" ]; then
        kvm_inventory=$1
        
        env_check
        validation $2
        addssh
        configurednsforopenshift $2 centos
        configure_dns_for_arecord $2 centos
    else
        # this assumes you are providing your own dns server
        # we need to be able to do a nsupdate against your dns server
        # to verify the required dns entries are available
        echo "Do run fuction to verify dns"
        configure_dns_for_arecord $2 centos
   fi
}

# validate product pass by user
function validate_product_by_user () {
    for item in $(echo "$VALID_PRODUCTS")
    do
        if [ "A${product}" == "A${item}" ];
        then
            product="${product}"
            break
        else
            product="${DEFAULT_PRODUCT}"
        fi
    done
}

config_err_msg () {
    cat << EOH >&2
  Could not find start_deployment.conf in the current path ${project_dir}. 
  Please make sure you are in the openshift-home-lab-directory."
EOH
}

# check for openshift-home-lab-directory and setup paths
function setup_required_paths () {
    current_dir=$(pwd)
    script_dir=$(dirname ${BASH_SOURCE[0]})
    current_dir_config="${current_dir}/inventory/group_vars/all"
    script_dir_config="${script_dir}/inventory/group_vars/all"

    if [ -f "${current_dir_config}" ]; then
        project_dir="${current_dir}"
        config_file="${current_dir_config}"
    elif [ ! -f "${script_dir_config}" ]; then
        project_dir="${script_dir}"
        config_file="${script_dir_config}"
    else
        config_err_msg; exit 1
    fi
}

function read_sensitive_data () {
    prompt="$1"
    while IFS= read -p "$prompt" -r -s -n 1 char
    do
        if [[ $char == $'\0' ]]
        then
            break
        fi
        prompt='*'
        input+="$char"
    done
    echo "$input"
}

function rhsm_register () {
    is_registered_tmp=$(mktemp)
    sudo subscription-manager identity > "${is_registered_tmp}" 2>&1
    is_registered=$(grep -o 'This system is not yet registered' "${is_registered_tmp}")
    if [ "A${is_registered}" == "A" ]; then
        echo "$(hostname) is registered to RHSM."
    else
        if [ "A${rhsm_reg_method}" == "Aupass" ]; 
        then
            sudo subscription-manager register --username="$rhsm_username" --password="$rhsm_password" --force > /dev/null 2>&1
        elif [ "A${rhsm_reg_method}" == "Aakey" ]; 
        then
            sudo subscription-manager register --org="$rhsm_org" --activationkey="$rhsm_activationkey" --force > /dev/null 2>&1
        else
            echo -n "Unknown issue: cannot register system!"
            exit 1
        fi
    
        # validate registration
        is_registered_tmp=$(mktemp)
        sudo subscription-manager identity > "${is_registered_tmp}" 2>&1
        is_registered=$(grep -o 'This system is not yet registered' "${is_registered_tmp}")
        if [ "A${is_registered}" == "A" ]; then
            echo "Successfully registered $(hostname) to RHSM."
        else
            echo "Unsuccessfully registered $(hostname) to RHSM."
            exit 1
        fi
    
    fi
}

function setup_ansible () {
    vaultfile=$1

    # install python
    if [ ! -f /usr/bin/python ];
    then
       echo "installing python"
       sudo yum install -y -q -e 0 python python3-pip python2-pip
    else
       echo "python is installed"
    fi

    # install ansible
    if [ ! -f /usr/bin/ansible ];
    then
       if ! sudo subscription-manager repos --list-enabled | grep -q "${ANSIBLE_REPO}"
       then
           sudo subscription-manager repos --enable="${ANSIBLE_REPO}"
       fi
       sudo yum install -y -q -e 0 ansible
    else
       echo "ansible is installed"
    fi
    
    # setup vault
    if [ -f /usr/bin/ansible ];
    then
        if [ ! -f "${vault_key_file}" ]
        then
            echo "Create ansible-vault password file ${vault_key_file}"
            openssl rand -base64 512|xargs > "${vault_key_file}"
        fi
    
        if cat "${vaultfile}" | grep -q VAULT 
        then
            echo "${vaultfile} is encrypted"
        else
            echo "Encrypting ${vaultfile}"
            ansible-vault encrypt "${vaultfile}"
        fi

        # Ensure roles are downloaded
        echo "Downloading required roles"
        #ansible-galaxy install -r "${project_dir}/playbooks/requirements.yml" > /dev/null 2>&1
        ansible-galaxy install --force -r "${project_dir}/playbooks/requirements.yml"

        # Ensure required modules are downloaded
        if [ ! -f "${project_dir}/modules/redhat_repositories.py" ]
        then
            test -d "${project_dir}/modules" || mkdir "${project_dir}/modules"
            CURRENT_DIR=$(pwd)
            cd "${project_dir}/modules/"
            wget https://raw.githubusercontent.com/jfenal/ansible-modules-jfenal/master/packaging/os/redhat_repositories.py
            cd "${CURRENT_DIR}"
        fi
    else
        echo "Ansible not found, please install and retry."
        exit 1
    fi
        
}


function ask_for_values () {
    varsfile=$1

    if grep '""' "${varsfile}"|grep -q domain
    then
        read -p "Enter your dns domain or press [ENTER] for the default [lab.example]: " domain
        domain=${domain:-lab.example}
        sed -i "s/domain: \"\"/domain: "$domain"/g" "${varsfile}"
    fi

    if grep '""' "${varsfile}"|grep -q dns_server_public
    then
        read -p "Enter a upstream DNS server or press [ENTER] for the default [1.1.1.1]: " dns_server_public
        dns_server_public=${dns_server_public:-1.1.1.1}
        sed -i "s/dns_server_public: \"\"/dns_server_public: "$dns_server_public"/g" "${varsfile}"
    fi

    if cat "${varsfile}"|grep -q changeme.in-addr.arpa
    then
        read -p "Enter your IP Network or press [ENTER] for the default [$NETWORK]: " network
        network=${network:-"${NETWORK}"}
        PTR=$(echo "$NETWORK" | awk -F . '{print $4"."$3"."$2"."$1".in-addr.arpa"}'|sed 's/0.//g')
        sed -i "s/changeme.in-addr.arpa/"$PTR"/g" "${varsfile}"
    fi
}

function ask_for_vault_values () {
    vaultfile=$1

cat << EOH >&2

 The following prompts will ask you values that are required for the installation
 to continue. If you make a mistake when entering passwords, pressing the Backspace 
 key will not fix it. Just hit Ctrl+c to cancel and run this script again.

EOH

    if cat "${vaultfile}"| grep -q VAULT
    then
        test -f /usr/bin/ansible-vault && ansible-vault decrypt "${vaultfile}"
        ansible_encrypt=yes
    fi

    if grep '""' "${vaultfile}"|grep -q idm_dm_pwd
    then
        idm_dm_pwd=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
        sed -i "s/idm_dm_pwd: \"\"/idm_dm_pwd: "$idm_dm_pwd"/g" "${vaultfile}"
    fi

    if grep '""' "${vaultfile}"|grep -q root_user_pass
    then
        unset root_user_pass
        prompt='Enter a password for the root user and press [ENTER]: '
        root_user_pass=$(read_sensitive_data "${prompt}")
        sed -i "s/root_user_pass: \"\"/root_user_pass: "$root_user_pass"/g" "${vaultfile}"
        echo ""
    fi

    if grep '""' "${vaultfile}"|grep -q idm_admin_pwd
    then
        unset idm_admin_pwd
        prompt='Enter a password for the IDM server console and press [ENTER]: '
        idm_admin_pwd=$(read_sensitive_data "${prompt}")
        sed -i "s/idm_admin_pwd: \"\"/idm_admin_pwd: "$idm_admin_pwd"/g" "${vaultfile}"
        echo ""
    fi

    if grep '""' "${vaultfile}"|grep -q rhsm_reg_method
    then
        echo ""
        PS3="Which option are you using to register the system 'Activation Key' (akey) or Username/Pass (upass): "
        options=("akey" "upass")
        select opt in akey upass
        do
            case $opt in
                akey)
                    rhsm_reg_method="$opt"
                    break
                    ;;
                upass)
                    rhsm_reg_method="$opt"
                    break
                    ;;
                *)
                    echo "Error: Please try again";;
                esac
            done
        
            if [ "A${rhsm_reg_method}" == "Aupass" ]; 
            then
                echo -n "Enter your RHSM username and press [ENTER]: "
                read rhsm_username
                unset rhsm_password
                prompt='Enter your RHSM password and press [ENTER]: '
                rhsm_password=$(read_sensitive_data "${prompt}")
                sed -i "s/rhsm_username: \"\"/rhsm_username: "$rhsm_username"/g" "${vaultfile}"
                sed -i "s/rhsm_password: \"\"/rhsm_password: "$rhsm_password"/g" "${vaultfile}"
                echo
            elif [ "A${rhsm_reg_method}" == "Aakey" ]; 
            then
                echo -n "Enter your RHSM activation key and press [ENTER]: "
                read rhsm_activationkey
                unset rhsm_org
                prompt='Enter your RHSM ORG ID and press [ENTER]: '
                rhsm_org=$(read_sensitive_data "${prompt}")
                sed -i "s/rhsm_org: \"\"/rhsm_org: "$rhsm_org"/g" "${vaultfile}"
                sed -i "s/rhsm_activationkey: \"\"/rhsm_activationkey: "$rhsm_activationkey"/g" "${vaultfile}"
                echo
            fi
            sed -i "s/rhsm_reg_method: \"\"/rhsm_reg_method: "$rhsm_reg_method"/g" "${vaultfile}"
    fi

    if [ "A${ansible_encrypt}" == "Ayes" ]
    then
        test -f /usr/bin/ansible-vault && ansible-vault encrypt "${vaultfile}"
    fi
}

while getopts ":hip:" opt;
do
    case $opt in
        h) display_help
           exit 1
           ;;
        i) check_args; generate_inventory=true;;
        p) check_args
           product=$OPTARG
           ;;
        s) check_args; skip_dns=true;;
       --) shift; break;;
       -*) echo Unrecognized flag : "$1" >&2
           display_help
           exit 1
           ;;
       \?) echo Unrecognized flag : "$1" >&2
           display_help
           exit 1
           ;;
    esac
done
shift "$((OPTIND-1))"

CURRENT_USER=$(whoami)
if [ "A${CURRENT_USER}" != "Aroot" ]
then
    echo "Checking if password less suoders is setup for ${CURRENT_USER}."
    sudo test -f "/etc/sudoers.d/${CURRENT_USER}"
    if [ "A$?" != "A0" ]
    then
        echo "Setting up /etc/sudoers.d/${CURRENT_USER}"
        echo "Please enter the password for the root user at the prompt."
        echo ""
        su root -c "echo '${CURRENT_USER} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${CURRENT_USER}"
   fi
fi

IPADDR=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
NETWORK=$(ip route | awk -F'/' "/$IPADDR/ {print \$1}")
PTR=$(echo "$NETWORK" | awk -F . '{print $4"."$3"."$2"."$1".in-addr.arpa"}'|sed 's/0.//g')
ANSIBLE_REPO=rhel-7-server-ansible-2-rpms

setup_required_paths
# setup ansible vaults varaibles
vault_key_file="/home/${CURRENT_USER}/.vaultkey"
vault_vars_file="${project_dir}/playbooks/vars/vault.yml"
vars_file="${project_dir}/playbooks/vars/all.yml"
hosts_inventory_file="${project_dir}/inventory/hosts"

# copy sample vars file to playbook/vars directory
if [ ! -f "${vars_file}" ]
then
  cp "${project_dir}/samples/all.yml" "${vars_file}"
  sed -i "s/inventory_file: \"\"/inventory_file: "$hosts_inventory_file"/g" "${vars_file}"
fi

# create vault vars file
if [ ! -f "${vault_vars_file}" ]
then
    cat > "${vault_vars_file}" <<EOF
rhsm_username: ""
rhsm_password: ""
rhsm_org: ""
rhsm_activationkey: ""
rhsm_reg_method: ""
root_user_pass: ""
idm_ssh_user: root
idm_dm_pwd: ""
idm_admin_pwd: ""
EOF
fi

# create ansible inventory file
if [ ! -f "${hosts_inventory_file}" ]
then
    cat > "${hosts_inventory_file}" <<EOF
localhost               ansible_connection=local ansible_user=root
EOF
fi

# Run main functions
ask_for_values "${vars_file}"
ask_for_vault_values "${vault_vars_file}"
rhsm_register
setup_ansible "${vault_vars_file}"

echo "${vars_file}"

# Run playbook to setup host
#ansible-playbook "${project_dir}/playbooks/setup_kvmhost.yml"

# Deploy VMS
#ansible-playbook "${project_dir}/playbooks/deploy_vms.yml"

# Deploy IDM server
if [ "A${skip_dns}" != "Atrue" ]
then
    echo "UPDATING idm_public_ip"
    SRV_IP=$(awk -F'=' '/dns01/ {print $2}' "${project_dir}/inventory/hosts")
    sed -i "s/idm_public_ip: \"\"/idm_public_ip: "$SRV_IP"/g" "${vars_file}"
    exit
    ansible-playbook "${project_dir}/playbooks/idm_server.yml"
fi


# validate user provided options
validate_product_by_user
   
echo "project_dir: $project_dir"
echo "config_file: $config_file"
