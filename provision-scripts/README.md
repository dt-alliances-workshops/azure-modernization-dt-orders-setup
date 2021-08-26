# Overview

This folder contains a script for a learner to provision the workshop if not setup in advance for them.

## input-credentials.sh

This script will prompt for entry of information such as Dynatrace URL and Azure subscription. This information then read by the scripts and other script then provisions and sets up the workshop Azure compute resources.

The credentials files format is taken from `workshop-credentials.template` and written to a file in the `gen` subfolder with the entered values called `workshop-credentials.json`.  This file will then be copied to `../gen/workshop-credentials.json` where other scripts expect it to be found.  Note that `workshop-credentials.json` is part of the `.gitignore` to prevent it from being checked in.

This script can over and over and it will read in existing values from `../gen/workshop-credentials.json` and allow the user to enter new ones.

## provision-workshop.sh

This script reads in the values from `../gen/workshop-credentials.json` and does the following: 

1. Create an Azure Service Principal used by Azure monitor integration. The Service Principal secrets are written to a file in the `gen` subfolder called `workshop-azure-service-principal.json`.  This file will then be copied to `../gen/workshop-azure-service-principal.json` where it is referenced when the `./workshop-config/setup-workshop-config.sh` is called.  Note that `workshop-credentials.json` is part of the `.gitignore` to prevent it from being checked in.

1. Provision a VM with an Dynatrace ActiveGate used for the Azure monitor integration.  Before active gate provisioning, a `../gen/workshop-active-gate-cloud-init.txt` is first created with the Dynatrace installer script and then defined within the cloud-init file.

1. Provision two VMs with OneAgent. One VM has the monolith version and one with the services version of the dt-orders application. These two VMs use the `cloud-init-monolith.txt` and `cloud-init-services` for their cloud init files. 
    * The cloud init script will create a user called `workshop` as part of the `sudo` group
    * These cloud init files will install GIT and then GIT CLONE this repo to the `/home/workshop` folder on the VM so that the VM has all the scripts to complete the setup
    * Once cloned, the cloud init files will next call the `provision-scripts/_setup_host.sh` script to complete the VM setup.  
    * On the VM, a setup log is written to `/tmp/workshop-setup-host.log`
    * One can login to the created VMs with `ssh workshop@PUBLIC_IP`.  The password for this user is defined in the `cloud-init-XXX` files.

1. Call the `./workshop-config/setup-workshop-config.sh` script that creates the Dynatrace configuration.