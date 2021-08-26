# Overview 

The folder contains scripts to setup the Dynatrace configuration for the learners Dynatrace tenant. 

The scripts use a combination of [Dynatrace Monitoring as Code](https://github.com/dynatrace-oss/dynatrace-monitoring-as-code) framework (a.k.a. monaco) and configuration using the [Dynatrace Configuration API](https://www.dynatrace.com/support/help/dynatrace-api/configuration-api/) for those few Dynatrace configurations not yet supported by monaco.  

# Prereqs

1. Assumes there is credentials files with value such as Dynatrace URL and Azure Subscription located at `/tmp/workshop-credentials.json`. See the `provision-scripts/input-credentials.sh` for how this file is created.

1. Assumes there is file with the Azure service principal details located at `tmp/workshop-azure-service-principal.json`. See `provision-scripts/_provison-scripts.lib` for details onhow this file should be created.

# Usage

1. `setup-workshop-config.sh` will read `/tmp/workshop-credentials.json` file for Dynatrace URL and API token and set environment variables used by the scripts and expected by monaco.  This script calls monaco and the Dynatrace API to add or delete the configuration expected by the workshop.  This setup script will also download [Dynatrace monoco binary version 1.5.0](https://github.com/dynatrace-oss/dynatrace-monitoring-as-code/releases/tag/v1.5.0)

1. `cleanup-workshop-config.sh` script will also call monaco and the Dynatrace API to remove the Dynatrace from the tenant read in from the `/tmp/workshop-credentials.json` file.
