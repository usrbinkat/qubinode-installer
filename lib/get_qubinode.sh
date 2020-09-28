#!/usr/bin/env bash
set -e
function extract_quibnode_installer(){
    echo "${1}"
    unzip "$HOME/${1}"
    rm "$HOME/${1}"
    NAMED_RELEASE=$(echo ${1} | sed -e 's/.zip//')
    mv qubinode-installer-${NAMED_RELEASE} qubinode-installer
}

function curl_download(){
    if [ -x /usr/bin/curl ] ; then
        cd $HOME
        #wget https://github.com/Qubinode/qubinode-installer/archive/master.zip
        #extract_quibnode_installer master.zip
        wget https://github.com/tosin2013/qubinode-installer/archive/release-2.4.3.zip
        extract_quibnode_installer release-2.4.3.zip
    fi 
}

function start_qubinode_install(){
    cd $HOME/qubinode-installer/
    ./qubinode-installerv2.sh
}

function wget_download(){
    cd $HOME
    #wget https://github.com/Qubinode/qubinode-installer/archive/master.zip
    #extract_quibnode_installer master.zip
    wget https://github.com/tosin2013/qubinode-installer/archive/release-2.4.3.zip
    extract_quibnode_installer release-2.4.3.zip
}

if  [ ! -d /home/${USER}/qubinode-installer ];
then 
  if [ ! -x /usr/bin/unzip ] ; then
    echo "unzip found on system."
    echo "Please install unzip to continue with install"
    exit 1
  fi

  if [ -x /usr/bin/curl ] ; then
    curl_download
    start_qubinode_install
  elif [ -x /usr/bin/wget ] ; then
    wget_download
    start_qubinode_install
  else 
    echo "wget or curl not found on system."
    echo "Please install curl or wget to continue with install"
    exit 1
  fi
fi


