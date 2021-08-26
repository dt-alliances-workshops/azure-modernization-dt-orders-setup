#!/bin/bash

# contains functions called in this script
source ./_provision-scripts.lib

cleanup_workshop_config()
{
  # this scripts will remove workshop config like tags, dashboard, MZ
  # need to be in folder to that paths used in scripts work properly
  cd ../workshop-config
  # run with the no prompt option
  ./cleanup-workshop-config.sh Y
  cd ../provision-scripts
}

echo "==================================================================="
echo "About to Delete Workshop resources"
echo "==================================================================="
read -p "Proceed? (y/n) : " CONDITION;
if [ "$CONDITION" != "y" ]; then exit 0; fi

echo ""
echo "=========================================="
echo "Deleting workshop resources"
echo "Starting: $(date)"
echo "=========================================="

delete_resource_group
delete_azure_service_principal
cleanup_workshop_config

echo ""
echo "============================================="
echo "Deleting workshop resources COMPLETE"
echo "End: $(date)"
echo "============================================="
echo ""