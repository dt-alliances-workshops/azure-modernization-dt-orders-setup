#!/bin/bash

# contains functions called in this script
source ./_provision-scripts.lib

# optional argument.  If not based, then the base workshop is setup.
# setup types are for additional features like kubernetes
SETUP_TYPE=$1

setup_workshop_config()
{
    # this scripts will add workshop config like tags, dashboard, MZ
    # need to change directories so that the generated monaco files
    # are in the right folder
    cd ../workshop-config
    ./setup-workshop-config.sh $1
    cd ../provision-scripts
}

echo "==================================================================="
echo "About to Provision Workshop - $SETUP_TYPE"
echo "==================================================================="
read -p "Proceed? (y/n) : " REPLY;
if [ "$REPLY" != "y" ]; then exit 0; fi
echo ""
echo "=========================================="
echo "Provisioning workshop resources"
echo "Starting   : $(date)"
echo "=========================================="

case "$SETUP_TYPE" in
    "k8") 
        echo "Setup type = $SETUP_TYPE"
        setup_workshop_config k8
        create_aks_cluster
        ;;
    "services-vm") 
        echo "Setup type = $SETUP_TYPE"
        setup_workshop_config services-vm
        createhost services
        ;;
    *)
        echo "Setup type = base workshop"
        createhost active-gate
        createhost monolith
        create_azure_service_principal
        setup_workshop_config
        ;;
esac

echo ""
echo "============================================="
echo "Provisioning workshop resources COMPLETE"
echo "End: $(date)"
echo "============================================="
echo ""