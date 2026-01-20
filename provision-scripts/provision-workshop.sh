#!/bin/bash

# contains functions called in this script
#source ./_provision-scripts.lib
YLW='\033[1;33m'
NC='\033[0m'
COLOR_BLUE='\e[0;34m'
COLOR_LIGHT_BLUE='\e[1;34m'
COLOR_RED='\e[0;31m'

# optional argument.  If not based, then the base workshop is setup.
# setup types are for additional features like kubernetes
#SETUP_TYPE=$1

#

#auto provision changes begin #
SETUP_TYPE=$1             # in SETUP_TYPE and KEYPAIR_NAME parameters
                          # optional argument. values are: all, monolith-vm, services-vm.  default is all
                          # this allows to just recreate the cloudformation stack is one VM stack fails
                          # this allows to override for testing outside of AWS event engine account
DT_BASEURL=$2
DT_API_TOKEN=$3
DASHBOARD_OWNER_EMAIL=$4  # required is making monaco dashboards SETUP_TYPE=all.
                          # Otherwise optional or any "dummy" value if you need to pass

#echo "SETUP="$SETUP_TYPE

#if [ "$SETUP_TYPE" == "wth" ]; then
#  source ./_provision-scripts.lib
#  PROVISION_MSG="About to setup Dynatrace ""What the Hack""\nDynatrace Server: "$DT_BASEURL
#  #else
#  #  PROVISION_MSG="About to setup Modernization Workshop\nDynatrace Managed Server: "$DT_BASEURL
#fi

#if [ "$SETUP_TYPE" == "grail" ]; then
#  source ./_provision-scripts.lib
#  PROVISION_MSG="About to setup Dynatrace Grail Workshop\nDynatrace Server: "$DT_BASEURL
#  else
#    PROVISION_MSG="About to setup Modernization Workshop\nDynatrace Managed Server: "$DT_BASEURL
#fi

if [[ "$SETUP_TYPE" == "grail" ]]; then
   source ./_provision-scripts.lib
   PROVISION_MSG="${YLW}About to setup Azure Resources for Dynatrace Grail Workshop\nTo point to Dynatrace SaaS Server: "$DT_BASEURL"${NC}"
   PROVISIONING_STEP="00-WorkshopProvisioning-BEGIN"
    JSON_EVENT=$(cat <<EOF
{
  "id": "1",
  "step": "$PROVISIONING_STEP",
  "event.provider": "azure-workshop-provisioning",
  "event.category": "azure-workshop",
  "user": "$EMAIL",
  "event.type": "provisioning-step",
  "provisioning.setup_type": "$SETUP_TYPE",
  "DT_ENVIRONMENT_ID": "$DT_ENVIRONMENT_ID"
}
EOF
)
   DT_SEND_EVENT=$(curl -s -X POST https://dt-event-send-dteve5duhvdddbea.eastus2-01.azurewebsites.net/api/send-event \
     -H "Content-Type: application/json" \
     -d "$JSON_EVENT")

elif [[ "$SETUP_TYPE" == "wth" ]]; then
   source ./_provision-scripts.lib
   PROVISION_MSG="${COLOR_BLUE}About to setup Azure Resources for Dynatrace on Azure What the Hack \nTo point to Dynatrace SaaS Server: "$DT_BASEURL"${NC}"
   PROVISION_MSG="${YLW}About to setup Azure Resources for Dynatrace Grail Workshop\nTo point to Dynatrace SaaS Server: "$DT_BASEURL"${NC}"
   PROVISIONING_STEP="00-WorkshopProvisioning-BEGIN"
    JSON_EVENT=$(cat <<EOF
{
  "id": "1",
  "step": "$PROVISIONING_STEP",
  "event.provider": "azure-workshop-provisioning",
  "event.category": "azure-workshop",
  "user": "$EMAIL",
  "event.type": "provisioning-step",
  "provisioning.setup_type": "$SETUP_TYPE",
  "DT_ENVIRONMENT_ID": "$DT_ENVIRONMENT_ID"
}
EOF
)
   DT_SEND_EVENT=$(curl -s -X POST https://dt-event-send-dteve5duhvdddbea.eastus2-01.azurewebsites.net/api/send-event \
     -H "Content-Type: application/json" \
     -d "$JSON_EVENT")
else 
  source ./_provision-scripts.lib
  PROVISION_MSG="About to setup Modernization Workshop\nDynatrace Managed Server: "$DT_BASEURL
fi


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
  PROVISIONING_STEP="00-WorkshopProvisioning-BEGIN"
    JSON_EVENT=$(cat <<EOF
{
  "id": "1",
  "step": "$PROVISIONING_STEP",
  "event.provider": "azure-workshop-provisioning",
  "event.category": "azure-workshop",
  "user": "$EMAIL",
  "event.type": "provisioning-step",
  "provisioning.setup_type": "$SETUP_TYPE",
  "DT_ENVIRONMENT_ID": "$DT_ENVIRONMENT_ID"
}
EOF
)
   DT_SEND_EVENT=$(curl -s -X POST https://dt-event-send-dteve5duhvdddbea.eastus2-01.azurewebsites.net/api/send-event \
     -H "Content-Type: application/json" \
     -d "$JSON_EVENT")
  
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
#echo -e "${COLOR_LIGHT_BLUE}$PROVISION_MSG ${NC}"
echo -e $PROVISION_MSG
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
        make_creds_file
        # contains functions called in this script
        source ./_provision-scripts.lib
        create_aks_cluster
        setup_workshop_config k8        
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
        register_azure_opsmgmt_resource_provider
        createhost active-gate
        createhost monolith
        #create_azure_service_principal        
        create_aks_cluster
        setup_workshop_config
        ./makedynakube.sh
        ;;
    "wth")
        echo "Setup type = $SETUP_TYPE"        
        # contains functions called in this script
        source ./_provision-scripts.lib
        register_azure_opsmgmt_resource_provider
	      register_azure_msinsights_resource_provider
        #createhost active-gate
        createhost monolith
        #create_azure_service_principal        
        create_aks_cluster
        #setup_workshop_config
	      setup_workshop_config k8
        #./makedynakube.sh
        ;;
    "grail")
	    echo "Setup type= $SETUP_TYPE"
	    source ./_provision-scripts.lib
	    register_azure_opsmgmt_resource_provider
      register_azure_msinsights_resource_provider
      register_azure_mscontainerservice_resource_provider            
	    createhost monolith
      create_aks_cluster
      provision_ai_foundry
	    setup_workshop_config
	    #setup_workshop_config k8
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

WORKSHOP_RESOURCE_COUNT=$(checkNumOfAzureResourcesInGroup)
if [ "$SETUP_TYPE" == "grail" ] && [ "$WORKSHOP_RESOURCE_COUNT" -lt 10 ]; then
  echo -e "${COLOR_RED}ERROR: Less than expected number of resources ($WORKSHOP_RESOURCE_COUNT) found in resource group $AZURE_RESOURCE_GROUP. Please check Azure Portal to verify if resources were created successfully. Re-run the provisioning script to create resources. ${NC}"
  PROVISIONING_STEP="98-WorkshopProvisioning-FAILED"
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
else
  PROVISIONING_STEP="99-WorkshopProvisioning-COMPLETE"
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
fi

echo ""
echo "============================================="
echo "Provisioning workshop resources COMPLETE"
echo "End: $(date)"
echo "============================================="
echo ""
DT_SEND_EVENT=$(curl -s -X POST https://dt-event-send-dteve5duhvdddbea.eastus2-01.azurewebsites.net/api/send-event \
     -H "Content-Type: application/json" \
     -d "$JSON_EVENT")

