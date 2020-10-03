#!/bin/bash 
#set -xe 

function generate_sshkey(){
   ssh-keygen -f "/home/${USER}/.ssh/id_rsa" -q -N '' 
}

# setting ansible config enviornment for ansible runner 
function set_ansible_config_env(){
    export ANSIBLE_CONFIG="/home/admin/qubinode-installer/ansible.cfg"
    echo 'export ANSIBLE_CONFIG="/home/admin/qubinode-installer/ansible.cfg"' >> /home/${USER}/.bashrc
}