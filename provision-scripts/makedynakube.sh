#!/bin/bash

create_dynakube()
{
  # reference: https://www.dynatrace.com/support/help/technology-support/container-platforms/kubernetes/monitor-kubernetes-environments/

  DYNAKUBE_TEMPLATE_FILE="dynakube.yaml.template"
  DYNAKUBE_GEN_FILE="../gen/dynakube.yaml"

if [ -f "$DYNAKUBE_GEN_FILE" ]
then
  rm -rf $DYNAKUBE_GEN_FILE
  DT_API_TOKEN_ENCODED=$(echo -n $DT_API_TOKEN | base64 -w 0)
  cat $DYNAKUBE_TEMPLATE_FILE | \
  sed 's~DT_API_TOKEN_PLACEHOLDER~'"$DT_API_TOKEN_ENCODED"'~' | \
  sed 's~DT_BASEURL_PLACEHOLDER~'"$DT_BASEURL"'~' | \
  sed 's~AZURE_AKS_CLUSTER_NAME_PLACEHOLDER~'"$AZURE_AKS_CLUSTER_NAME"'~' >> $DYNAKUBE_GEN_FILE
else
  # create new file from the template with learner Dynatrace tenant information
  DT_API_TOKEN_ENCODED=$(echo -n $DT_API_TOKEN | base64 -w 0)
  cat $DYNAKUBE_TEMPLATE_FILE | \
  sed 's~DT_API_TOKEN_PLACEHOLDER~'"$DT_API_TOKEN_ENCODED"'~' | \
  sed 's~DT_BASEURL_PLACEHOLDER~'"$DT_BASEURL"'~' | \
  sed 's~AZURE_AKS_CLUSTER_NAME_PLACEHOLDER~'"$AZURE_AKS_CLUSTER_NAME"'~' >> $DYNAKUBE_GEN_FILE
fi

  
  echo "Saved dynatrace operator secrets file to: $DYNAKUBE_GEN_FILE"
}

CREDS_FILE="../gen/workshop-credentials.json"
PROVISIONING_STEP="10-Make-Dynakube-file"
if [ -f "$CREDS_FILE" ]
then
    DT_BASEURL=$(cat $CREDS_FILE | jq -r '.DT_BASEURL')
    DT_API_TOKEN=$(cat $CREDS_FILE | jq -r '.DT_API_TOKEN')
    DT_PAAS_TOKEN=$(cat $CREDS_FILE | jq -r '.DT_PAAS_TOKEN')
    DT_ENVIRONMENT_ID=$(cat $CREDS_FILE | jq -r '.DT_ENVIRONMENT_ID')
    AZURE_RESOURCE_GROUP=$(cat $CREDS_FILE | jq -r '.AZURE_RESOURCE_GROUP')
    AZURE_SUBSCRIPTION=$(cat $CREDS_FILE | jq -r '.AZURE_SUBSCRIPTION')
    AZURE_LOCATION=$(cat $CREDS_FILE | jq -r '.AZURE_LOCATION')
    RESOURCE_PREFIX=$(cat $CREDS_FILE | jq -r '.RESOURCE_PREFIX')
    AZURE_AKS_CLUSTER_NAME=$(cat $CREDS_FILE | jq -r '.AZURE_AKS_CLUSTER_NAME')
    EMAIL=$(cat $CREDS_FILE | jq -r '.EMAIL')

    JSON_EVENT=$(cat <<EOF
{
  "id": "1",
  "step": "$PROVISIONING_STEP",
  "event.provider": "azure-workshop-provisioning",
  "event.category": "azure-workshop",
  "user": "$EMAIL",
  "event.type": "provisioning-step",
  "DT_ENVIRONMENT_ID": "$DT_ENVIRONMENT_ID"
}
EOF
)

    DT_SEND_EVENT=$(curl -s -X POST https://dt-event-send-dteve5duhvdddbea.eastus2-01.azurewebsites.net/api/send-event \
     -H "Content-Type: application/json" \
     -d "$JSON_EVENT")
else
  echo "ABORT: CREDS_FILE: $CREDS_FILE not found"
  exit 1
fi

create_dynakube
