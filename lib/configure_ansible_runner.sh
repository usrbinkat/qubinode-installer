#!/bin/bash 

# Install ansible runner 
function install_ansible_runner_service(){
    if [ ! -d /usr/share/ansible-runner-service ];
    then
        mkdir -p /home/"${USER}"/qubinode-installer/env
        cd /tmp
        git clone https://github.com/ansible/ansible-runner-service.git
        sudo  mkdir -p /etc/ansible-runner-service
        sudo mkdir -p /usr/share/ansible-runner-service/{artifacts,env,project,inventory,client_cert}
        sudo cp /tmp/ansible-runner-service/*.py   /usr/share/ansible-runner-service/
        sudo cp /tmp/ansible-runner-service/*.yaml   /usr/share/ansible-runner-service/
        sudo cp -r /tmp/ansible-runner-service/runner_service /usr/share/ansible-runner-service/runner_service
        sudo cp  /tmp/ansible-runner-service/ansible_runner_service /usr/bin/
        #sudo  python3 setup.py install --record installed_files --single-version-externally-managed
        #sudo ansible_runner_service
    fi 
}

function configure_ansible_runner_systemd(){
    if [ ! -f /usr/share/ansible-runner-service ];
    then
      sudo cp /tmp/ansible-runner-service/misc/systemd/ansible-runner-service.service /etc/systemd/system
      sudo systemctl enable ansible-runner-service.service
      sudo systemctl start ansible-runner-service.service
      sudo systemctl status ansible-runner-service.service
    fi
}

# Change valut key path in ansible.cfg file
function update_ansible_cfg(){
    if [ -f /home/"${USER}"/qubinode-installer/ansible.cfg ];
    then 
      sed -i 's/vault_password_file  = ~\/.vaultkey/vault_password_file  = \/home\/'"${USER}"'\/.vaultkey/g'  /home/"${USER}"/qubinode-installer/ansible.cfg
    fi 
}