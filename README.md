# Overview

The repo contains the setup and learner scripts to support [this Azure and Dynatrace workshop](http://azure-modernize-workshop.alliances.dynatracelabs.com/).

<img src="dt-azure.png" width="400"/> 

# Repo Structure

1. `provision-scripts/` - If not done in advance by the workshop instructor, this folder contains a script for a learner to enter in information such as Dynatrace URL and Azure subscription. This information is then read by the scripts that then provisions and setup the workshop Azure compute resources.
1. `app-scripts/` - These scripts are called by the scripts in `provision-scripts/` folder to install workshop sample applications.  A learner generally would not run these directly, but they could if they needed to start or stop the applications.
1. `workshop-config/` - If not done in advance by the workshop instructor, this folder contains the scripts to setup the Dynatrace configuration for the learners Dynatrace tenant.
1. `learner-scripts/` - This folder contains the scripts a learner would use in workshop labs.
1. `gen/` - This folder contains generated files.  The `.gitignore` excludes them from check in.

See the README files in the subfolders for additional details.

# Typical Usage

## Learner provider workshop environment

In this use case, a learner needs to provide Dynatrace tenant and Azure subscription.  

Within the Azure console, they learner uses the Azure Cloud Shell to would provision the workshop following these steps:
* `git clone https://github.com/dt-alliances-workshops/azure-modernization-dt-orders-setup.git` 
* `cd azure-modernization-dt-orders-setup/provision-scripts/`
* `./input-credentials.sh`
* `./provision-workshop.sh`
* `cd ../learner-scripts`
* `./show-app-urls.sh`

## Instructor provided workshop environment

In this use case, Dynatrace tenant and all the Azure resources would be pre-provisioned for the learner.

The learner would use a provided Bastion host VM that has a web-based cloud SSH shell. The learned would not log into the Azure web console.

On this Bastion VM, the workshop repo would already be cloned and the credentials file `/home/workshop/gen/workshop-credentials.json` would already exist and be populated with the information needed for their use. 

The learner would only then need to run any scripts in the `/home/workshop/learner-scripts/` folder.

# Feedback

Whether it's a bug report, new feature, correction, or additional documentation, we greatly value feedback and contributions.

You can share your feedback by opening a new issue [here](https://github.com/dt-alliances-workshops/azure-modernization-dt-orders-setup/issues).

Please ensure we have all the necessary information to effectively respond to your bug report or contribution such as:
* The URL to the page, file or script with an issue
* A reproducible test case or series of steps

# Maintainer

[Rob Jahn](https://www.linkedin.com/in/robjahn/) -- Email me @ rob.jahn@dynatrace.com with questions or more details.