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

PROVISIONING_STEP="99-Workshop Cleaned up"
JSON_EVENT='{"id":"1","step":"'"$PROVISIONING_STEP"'","event.provider":"azure-workshop-provisioning","event.category":"azure-workshop","user":"'"$EMAIL"'","event.type":"provisioning-step","DT_ENVIRONMENT_ID":"'"$DT_ENVIRONMENT_ID"'"}'
DT_SEND_EVENT=$(curl -s -X POST https://dt-event-send-dteve5duhvdddbea.eastus2-01.azurewebsites.net/api/send-event \
     -H "Content-Type: application/json" \
     -d "$JSON_EVENT")

echo ""
echo "============================================="
echo "Deleting workshop resources COMPLETE"
echo "End: $(date)"
echo "============================================="
echo ""