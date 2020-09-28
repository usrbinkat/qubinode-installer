#!/usr/bin/env bash
set -e

if  [ ! -d /home/${$USER}/qubinode-installer ];
then 
  if [ ! -x /usr/bin/wget ] ; then
    echo "using wget to download quninode installer"
  elif [ ! -x /usr/bin/curl ] ; then
    echo "using curl to download qubinode installer"
  else 
    echo "wget or curl not found on system."
    echo "Please install curl or wget to continue with install"
    exit 1
  fi
fi