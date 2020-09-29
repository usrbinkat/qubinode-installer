#!/bin/bash 

function install_ansible_runner_service(){
    if [ ! -d /opt/ansible-runner-service ];
    then
        git clone https://github.com/ansible/ansible-runner-service.git
        sudo mv ansible-runner-service /opt/ansible-runner-service
        cd /opt/ansible-runner-service 
        sudo  python3 setup.py install --record installed_files --single-version-externally-managed
        sudo ansible_runner_service
    fi 
}
