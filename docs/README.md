#  Qubinode Overview

A Qubinode is a bare metal node that uses the qubinode-installer to configure RHEL to function as a KVM host. The qubinode-installer can then be used to deploy additional Red Hat products as VMs running atop the Qubinode. 

# Getting Started

The first step is to get RHEL installed on your hardware

## Get Subscriptions

-  Get your [No-cost developer subscription](https://developers.redhat.com/articles/faqs-no-cost-red-hat-enterprise-linux/) for RHEL.
-  Get a Red Hat OpenShift Container Platform (OCP) [60-day evalution subscription](https://www.redhat.com/en/technologies/cloud-computing/openshift/try-it?intcmp=701f2000000RQykAAG&extIdCarryOver=true&sc_cid=701f2000001OH74AAG).

## Install Red Hat Enterprise Linux
A bare metal system running RHEL. Follow the [RHEL Installation Walkthrough](https://developers.redhat.com/products/rhel/hello-world#fndtn-rhel) to get RHEL installed on your hardware. When installing RHEL, for the software selection, **Base Environment** choose one of the following:

1. Virtualization Host
2. Server with GUI

If you choose **Server with GUI**, make sure from the **Add-ons for Selected Evironment** you select the following:

- Virtualization Hypervisor 
- Virtualization Tools

**_TIPS_**
> * If using the recommend storage of one ssd and one NVME, install RHEL on the ssd, not the NVME. 
>  * The RHEL installer will delicate the majority of your storage to /home,  you can choose **"I will configure partitioning"** to have control over this.
>  * Set root password and create admin user with sudo privilege

### The qubinode-installer for python development

Download and extract the qubinode-installer as a non root user.

### Register first, then attach a subscription in the Customer Portal
```
subscription-manager register
```
### Attach a specific subscription through the Customer Portal
```
subscription-manager refresh
```
  
### Attach a subscription from any available that match the system
```
subscription-manager attach --auto
```

### Register repos
```
sudo subscription-manager repos --enable=rhel-8-for-x86_64-appstream-rpms --enable=rhel-8-for-x86_64-baseos-rpms --enable ansible-2.9-for-rhel-8-x86_64-rpms
```

### Install python3-pip ansible git vim 
 ```
dnf install python3-pip ansible git vim  python3-devel -y 
```

## Clone the qubinode repo 
```
git clone https://github.com/tosin2013/qubinode-installer.git

```

## CD into qubinode-installer folder
```
 cd qubinode-installer/
```

## Switch to python-build branch
```
git checkout python-build
```

## Install python modules requirements
```
cd lib 
pip3 install -r lib/requirements.txt 
cd ..
```

### Qubinode Setup

1. start with the configure_secerts.yml 
```
cat >env/extravars<<EOF
{
   "configure_secerts": true,
   "rhsm_username": "yourusername",
   "rhsm_password": "changeme",
   "rhsm_pass": "{{ rhsm_password }}",
   "rhsm_org": "",
   "rhsm_activationkey": "",
   "admin_user_password": "changeme",
   "idm_ssh_user": "yourusername",
   "idm_dm_pwd": 'thisisaveryL0ngpaSSw0rd',
   "idm_admin_pwd": "changeme"
}
EOF
sudo python3 lib/qubinode_ansible_runner.py  qubinode-config-management.yml
rm extra_vars.json
```


Install ansible roles 
```
 ansible-galaxy install -r  project/requirements.yml
```


## Deploy a Red Hat Product

Most products depends on the latest rhel 7, 8 qcow image. You can either manually download them or provide your RHSM api token and the installer will download these files for you.

#### Getting the RHEL Qcow Image
<table>
  <tr>
   <td>Using Token
   </td>
   <td>Downloading
   </td>
  </tr>
  <tr>
   <td>Navigate to <a href="https://access.redhat.com/management/api">RHSM API</a> to generate a token and save it as <strong>rhsm_token</strong>. This token will be used to download the rhel qcow image. 
   </td>
   <td>From your web browser, navigate to <a href="https://access.redhat.com/downloads/content/69/ver=/rhel---7/7.8/x86_64/product-software">Download Red Hat Enterprise Linux</a>. Download the qcow image matching this checksum the below checksum.
   </td>
  </tr>
</table>

If you are using tokens it should be:
```
* $HOME/qubinode-installer/rhsm_token
```

If you downloaded the files instead it should be:
```
* $HOME/qubinode-installer/rhel-server-7.8-x86_64-kvm.qcow2
* $HOME/qubinode-installer/rhel-8.2-x86_64-kvm.qcow2
```

**Optional Install Cockpit**  
**In order to manage and view cluster from a web ui on RHEL 7**  
```
subscription-manager repos --enable=rhel-7-server-extras-rpms
subscription-manager repos --enable=rhel-7-server-optional-rpms
sudo yum install  cockpit cockpit-networkmanager cockpit-dashboard \
  cockpit-storaged cockpit-packagekit cockpit-machines cockpit-sosreport \
  cockpit-pcp cockpit-bridge -y
sudo systemctl start cockpit
sudo systemctl enable cockpit.socket
sudo firewall-cmd --add-service=cockpit
sudo firewall-cmd --add-service=cockpit --permanent
sudo firewall-cmd --reload
```
**In order to manage and view cluster from a web ui on RHEL 8** 
```
$ sudo systemctl enable --now cockpit.socket
```

**go to your servers url for cockpit ui**
```
https://SERVER_IP:9090
```


At this point you refer to the [documentation](#Currently-Supported-Products) for the product you want to install.

## Currently Supported Products
* [Red Hat OpenShift Platform](qubinode/openshift4_installation_steps.md)
* [OKD - The Community Distribution of Kubernetes](qubinode/okd4_installation_steps.md)
* [Red Hat Identity Managment](qubinode/idm.md)
* [Red Hat Enterprise Linux](qubinode/rhel_vms.md)

## Products in Development
* [Ansible Automation Platform](qubinode/ansible_platform.md)
* [Red Hat Satellite](qubinode/qubinode_satellite_install.md)