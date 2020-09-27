#!/usr/bin/env bash
set -E
set -o functrace
set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# Define colours
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
def=$'\e[1;49m'
end=$'\e[0m'

if [ -f /etc/redhat-release ];
then
  echo "Checking Red Hat Release Type"
  if cat /etc/redhat-release  | grep '8.[0-9]' > /dev/null 2>&1; then
   echo  "RHEL 8" 
   check_rhsm_status
  elif cat /etc/redhat-release  | grep '7.[0-9]' > /dev/null 2>&1; then
   echo "RHEL 7"
   check_rhsm_status
  elif cat /etc/redhat-release  | grep 'Fedora release 3[0-9]' > /dev/null 2>&1; then
   echo "Fedora Release"
  else
   echo "Unknown RHEL Based server"
   exit 1
  fi
else
  echo "Contiuning with deployment" 
fi 