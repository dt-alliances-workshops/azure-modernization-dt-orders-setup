create_dynakube()
{
  # reference: https://www.dynatrace.com/support/help/technology-support/container-platforms/kubernetes/monitor-kubernetes-environments/

  DYNAKUBE_TEMPLATE_FILE="dynakube.yaml.template"
  DYNAKUBE_GEN_FILE="../gen/dynakube.yaml"

  # create new file from the template with learner Dynatrace tenant information
  DT_API_TOKEN_ENCODED=$(echo -n $DT_API_TOKEN | base64 -w 0)
  cat $DYNAKUBE_TEMPLATE_FILE | \
    sed 's~DT_API_TOKEN_PLACEHOLDER~'"$DT_API_TOKEN_ENCODED"'~' | \
    sed 's~DT_BASEURL_PLACEHOLDER~'"$DT_BASEURL"'~' | \
    sed 's~AZURE_AKS_CLUSTER_NAME_PLACEHOLDER~'"$AZURE_AKS_CLUSTER_NAME"'~' >> $DYNAKUBE_GEN_FILE

  #chmod +x $DYNAKUBE_GEN_FILE
  echo "Saved dynatrace operator secrets file to: $DYNAKUBE_GEN_FILE"
}

CREDS_FILE="../gen/workshop-credentials.json"
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

else
  echo "ABORT: CREDS_FILE: $CREDS_FILE not found"
  exit 1
fi

create_dynakube