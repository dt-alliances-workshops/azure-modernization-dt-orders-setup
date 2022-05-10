#!/bin/bash

# contains functions called in this script
#source ./_provision-scripts.lib

# optional argument.  If not based, then the base workshop is setup.
# setup types are for additional features like kubernetes
#SETUP_TYPE=$1

#

#auto provision changes begin #
DT_BASEURL=$1
DT_API_TOKEN=$2
DASHBOARD_OWNER_EMAIL=$3  # required is making monaco dashboards SETUP_TYPE=all.
                          # Otherwise optional or any "dummy" value if you need to pass
                          # in SETUP_TYPE and KEYPAIR_NAME parameters
SETUP_TYPE=$4             # optional argument. values are: all, monolith-vm, services-vm.  default is all
                          # this allows to just recreate the cloudformation stack is one VM stack fails
                          # this allows to override for testing outside of AWS event engine account

if [ -z $DT_BASEURL ]; then
  echo "ABORT: missing DT_BASEURL parameter"
  exit 1
fi

if [ -z $DT_API_TOKEN ]; then
  echo "ABORT: missing DT_API_TOKEN parameter"
  exit 1
fi

if [ -z $SETUP_TYPE ]; then
  SETUP_TYPE=all
fi


make_creds_file() {

  CREDS_TEMPLATE_FILE="./workshop-credentials.template"
  CREDS_FILE="../gen/workshop-credentials.json"
  echo "Making $CREDS_FILE"

  DT_ENVIRONMENT_ID=$(echo $DT_BASEURL | awk -F"." '{ print $1 }' | awk -F"https://" '{ print $2 }')
  HOSTNAME_MONOLITH=dt-orders-monolith
  HOSTNAME_SERVICES=dt-orders-services
  CLUSTER_NAME=dynatrace-workshop-cluster
  AZURE_RESOURCE_GROUP=dynatrace-azure-modernize-workshop
  AZURE_SUBSCRIPTION=$(az account list --all --query "[?isDefault].id" --output tsv)

  # pull out the DT_ENVIRONMENT_ID. DT_BASEURL will be one of these patterns
  if [[ $(echo $DT_BASEURL | grep "/e/" | wc -l) == *"1"* ]]; then
    #echo "Matched pattern: https://{your-domain}/e/{your-environment-id}"
    DT_ENVIRONMENT_ID=$(echo $DT_BASEURL | awk -F"/e/" '{ print $2 }')
  elif [[ $(echo $DT_BASEURL | grep ".live." | wc -l) == *"1"* ]]; then
    #echo "Matched pattern: https://{your-environment-id}.live.dynatrace.com"
    DT_ENVIRONMENT_ID=$(echo $DT_BASEURL | awk -F"." '{ print $1 }' | awk -F"https://" '{ print $2 }')
  elif [[ $(echo $DT_BASEURL | grep ".sprint." | wc -l) == *"1"* ]]; then
    #echo "Matched pattern: https://{your-environment-id}.sprint.dynatracelabs.com"
    DT_ENVIRONMENT_ID=$(echo $DT_BASEURL | awk -F"." '{ print $1 }' | awk -F"https://" '{ print $2 }')
  else
    echo "ERROR: No DT_ENVIRONMENT_ID pattern match to $DT_BASEURL"
    exit 1
  fi

  #remove trailing / if the have it
  if [ "${DT_BASEURL: -1}" == "/" ]; then
    echo "removing / from DT_BASEURL"
    DT_BASEURL="$(echo ${DT_BASEURL%?})"
  fi

  cat $CREDS_TEMPLATE_FILE | \
  sed 's~DT_BASEURL_PLACEHOLDER~'"$DT_BASEURL"'~' | \
  sed 's~AZURE_RESOURCE_GROUP_PLACEHOLDER~'"$AZURE_RESOURCE_GROUP"'~' | \
  sed 's~HOSTNAME_MONOLITH_PLACEHOLDER~'"$HOSTNAME_MONOLITH"'~' | \
  sed 's~HOSTNAME_SERVICES_PLACEHOLDER~'"$HOSTNAME_SERVICES"'~' | \
  sed 's~AZURE_AKS_CLUSTER_NAME_PLACEHOLDER~'"$CLUSTER_NAME"'~' | \
  sed 's~DT_API_TOKEN_PLACEHOLDER~'"$DT_API_TOKEN"'~' | \
  sed 's~AZURE_SUBSCRIPTION_PLACEHOLDER~'"$AZURE_SUBSCRIPTION"'~' | \
  sed 's~DT_ENVIRONMENT_ID_PLACEHOLDER~'"$DT_ENVIRONMENT_ID"'~' | \
  sed 's~DT_DASHBOARD_OWNER_EMAIL_PLACEHOLDER~'"$DASHBOARD_OWNER_EMAIL"'~' | \
  sed 's~DT_PAAS_TOKEN_PLACEHOLDER~'"$DT_API_TOKEN"'~' > $CREDS_FILE

}

#auto provision changes end

setup_workshop_config()
{
    # this scripts will add workshop config like tags, dashboard, MZ
    # need to change directories so that the generated monaco files
    # are in the right folder

    cd ../workshop-config
    ./setup-workshop-config.sh
    ./setup-workshop-config.sh k8
    ./setup-workshop-config.sh dashboard $DASHBOARD_OWNER_EMAIL
    cd ../provision-scripts
}

echo "==================================================================="
echo "About to Provision Workshop" 
echo "Dynatrace Managed Server:$DT_BASEURL"
echo "Setup Type: $SETUP_TYPE"
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
        ./makedynakube.sh:
        ;;
    "services-vm")
        echo "Setup type = $SETUP_TYPE"
        setup_workshop_config services-vm
        createhost services
        ;;
    "all")
        echo "Setup type = $SETUP_TYPE"
        make_creds_file
        # contains functions called in this script
        source ./_provision-scripts.lib
        createhost active-gate
        createhost monolith
        create_azure_service_principal
        #setup_workshop_config       
        create_aks_cluster
        setup_workshop_config
        ./makedynakube.sh
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