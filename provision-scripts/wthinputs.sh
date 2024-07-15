#!/bin/bash

YLW='\033[1;33m'
NC='\033[0m'
COLOR_BLUE='\e[0;34m'
COLOR_LIGHT_BLUE='\e[1;34m'
COLOR_RED='\e[0;31m'

CREDS_TEMPLATE_FILE="./workshop-credentials.template"
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
fi

if [ -z "$AZURE_SUBSCRIPTION" ]; then
    AZURE_SUBSCRIPTION_ID=$(az account list --all --query "[?isDefault].id" --output tsv)
    AZURE_SUBSCRIPTION_NAME=$(az account list --all --query "[?isDefault].name" --output tsv)
    AZURE_SUBSCRIPTION=$AZURE_SUBSCRIPTION_ID
fi

clear
echo "==================================================================="
echo -e "${COLOR_LIGHT_BLUE}Welcome to Dynatrace on Azure WhatTheHack ${NC}"
echo -e "${YLW}Please enter the inputs needed below for the hack: ${NC}"
echo "NOTE: You can just Press <enter> to keep the current value"
echo "==================================================================="
read -p "Your last name           (current: $RESOURCE_PREFIX) : " RESOURCE_PREFIX_NEW
echo    "Dynatrace Base URL       (ex. https://ABC.apps.dynatrace.com) "
read -p "                         (current: $DT_BASEURL) : " DT_BASEURL_NEW
#read -p "Dynatrace PaaS Token    (current: $DT_PAAS_TOKEN) : " DT_PAAS_TOKEN_NEW
echo    "Dynatrace Access API Token   (ex. dtco01.ABC1244213413213AADASDD) "  
read -p "                         (current: $DT_ACCESS_API_TOKEN) : " DT_ACCESS_API_TOKEN_NEW
#echo "Azure Subscription ID "
echo -e "${COLOR_RED}NOTE:${NC} The current subscription ID was automatically derived below"
read -p "Azure Subscription ID    (current: $AZURE_SUBSCRIPTION) : " AZURE_SUBSCRIPTION_NEW
echo "==================================================================="
echo ""

# set value to new input or default to current value
RESOURCE_PREFIX=${RESOURCE_PREFIX_NEW:-$RESOURCE_PREFIX}
DT_BASEURL=${DT_BASEURL_NEW:-$DT_BASEURL}
DT_ACCESS_API_TOKEN=${DT_ACCESS_API_TOKEN_NEW:-$DT_ACCESS_API_TOKEN}
DT_API_TOKEN=${DT_API_TOKEN_NEW:-$DT_API_TOKEN}
DT_PAAS_TOKEN=${DT_PAAS_TOKEN_NEW:-$DT_PAAS_TOKEN}
AZURE_RESOURCE_GROUP=${AZURE_RESOURCE_GROUP_NEW:-$AZURE_RESOURCE_GROUP}
AZURE_SUBSCRIPTION=${AZURE_SUBSCRIPTION_NEW:-$AZURE_SUBSCRIPTION}
AZURE_LOCATION=${AZURE_LOCATION_NEW:-$AZURE_LOCATION}
# append a prefix to resource group
#AZURE_RESOURCE_GROUP="$RESOURCE_PREFIX-dynatrace-azure-modernize"
AZURE_RESOURCE_GROUP="$RESOURCE_PREFIX-dynatrace-azure-grail-modernize-wth"
AZURE_AKS_CLUSTER_NAME="dynatrace-azure-grail-wth"
EMAIL=$(az account show --query user.name --output tsv)
EMAIL=$(echo $EMAIL | cut -d'#' -f 2)

# pull out the DT_ENVIRONMENT_ID. DT_BASEURL will be one of these patterns
if [[ $(echo $DT_BASEURL | grep "/e/" | wc -l) == *"1"* ]]; then
  #echo "Matched pattern: https://{your-domain}/e/{your-environment-id}"
  DT_ENVIRONMENT_ID=$(echo $DT_BASEURL | awk -F"/e/" '{ print $2 }')
elif [[ $(echo $DT_BASEURL | grep ".live." | wc -l) == *"1"* ]]; then
  #echo "Matched pattern: https://{your-environment-id}.live.dynatrace.com"
  DT_ENVIRONMENT_ID=$(echo $DT_BASEURL | awk -F"." '{ print $1 }' | awk -F"https://" '{ print $2 }')
  DT_GEN2=true
elif [[ $(echo $DT_BASEURL | grep ".sprint." | wc -l) == *"1"* ]]; then
  #echo "Matched pattern: https://{your-environment-id}.sprint.dynatracelabs.com"
  DT_ENVIRONMENT_ID=$(echo $DT_BASEURL | awk -F"." '{ print $1 }' | awk -F"https://" '{ print $2 }')
elif [[ $(echo $DT_BASEURL | grep ".apps." | wc -l) == *"1"* ]]; then
  DT_ENVIRONMENT_ID=$(echo $DT_BASEURL | awk -F"." '{ print $1 }' | awk -F"https://" '{ print $2 }')
  DT_GEN3=true
else
  echo "ERROR: No DT_ENVIRONMENT_ID pattern match to $DT_BASEURL"
  exit 1
fi

if $DT_GEN2 ; then
   DT_BASEURL_GEN2="https://$DT_ENVIRONMENT_ID.live.dynatrace.com"
fi
if $DT_GEN3 ; then
   DT_BASEURL_GEN3="https://$DT_ENVIRONMENT_ID.apps.dynatrace.com"
fi

#remove trailing / if the have it
if [ "${DT_BASEURL: -1}" == "/" ]; then
  #echo "removing / from DT_BASEURL"
  DT_BASEURL="$(echo ${DT_BASEURL%?})"
fi

DT_TOKEN=$(curl --silent -X POST "https://$DT_ENVIRONMENT_ID.live.dynatrace.com/api/v2/apiTokens" -H "accept: application/json; charset=utf-8" -H "Content-Type: application/json; charset=utf-8" -d "{\"scopes\":[\"slo.read\",\"slo.write\",\"settings.read\",\"events.read\",\"events.ingest\",\"settings.write\",\"ReadConfig\",\"WriteConfig\",\"activeGateTokenManagement.create\",\"metrics.ingest\",\"logs.ingest\",\"entities.read\",\"DataExport\",\"InstallerDownload\",\"SupportAlert\"],\"name\":\"azure-workshop-auto\"}" -H "Authorization: Api-Token $DT_ACCESS_API_TOKEN")

DT_WORKSHOP_TOKEN=$(echo $DT_TOKEN | jq -r .token)

echo -e "Please confirm all are correct:"
echo "--------------------------------------------------"
#echo "Your last name                 : $RESOURCE_PREFIX"
echo "Dynatrace Base URL             : $DT_BASEURL"
#echo "Dynatrace PaaS Token          : $DT_PAAS_TOKEN"
echo "Dynatrace Access API Token     : $DT_ACCESS_API_TOKEN"
echo "Azure Subscription ID          : $AZURE_SUBSCRIPTION"
echo "--------------------------------------------------"
echo "derived values"
echo "--------------------------------------------------"
echo "Azure Resource Group     : $AZURE_RESOURCE_GROUP"
echo "Azure AKS Cluster Name       : $AZURE_AKS_CLUSTER_NAME"
echo "Dynatrace Environment ID : $DT_ENVIRONMENT_ID"
#echo "Dynatrace Gen2 BaseURL   : https://$DT_ENVIRONMENT_ID.live.dynatrace.com"
#echo "DT Workshop API Token    : $DT_WORKSHOP_TOKEN"
#echo "Your email               : $EMAIL"
echo "==================================================================="
read -p "Is this all correct? (y/n) : " REPLY;
if [ "$REPLY" != "y" ]; then exit 0; fi
echo ""
echo "==================================================================="
# make a backup
cp $CREDS_FILE $CREDS_FILE.bak 2> /dev/null
rm $CREDS_FILE 2> /dev/null

# create new file from the template
cat $CREDS_TEMPLATE_FILE | \
  sed 's~RESOURCE_PREFIX_PLACEHOLDER~'"$RESOURCE_PREFIX"'~' | \
  sed 's~AZURE_RESOURCE_GROUP_PLACEHOLDER~'"$AZURE_RESOURCE_GROUP"'~' | \
  sed 's~AZURE_AKS_CLUSTER_NAME_PLACEHOLDER~'"$AZURE_AKS_CLUSTER_NAME"'~' | \
  sed 's~AZURE_SUBSCRIPTION_PLACEHOLDER~'"$AZURE_SUBSCRIPTION"'~' | \
  sed 's~AZURE_LOCATION_PLACEHOLDER~'"$AZURE_LOCATION"'~' | \
  sed 's~DT_ENVIRONMENT_ID_PLACEHOLDER~'"$DT_ENVIRONMENT_ID"'~' | \
  sed 's~DT_BASEURL_PLACEHOLDER~'"$DT_BASEURL_GEN2"'~' | \
  sed 's~DT_API_TOKEN_PLACEHOLDER~'"$DT_WORKSHOP_TOKEN"'~' | \
  sed 's~DT_DASHBOARD_OWNER_EMAIL_PLACEHOLDER~'"$EMAIL"'~' | \
  sed 's~EMAIL_PLACEHOLDER~'"$EMAIL"'~' | \
  sed 's~DT_ACCESS_API_TOKEN_PLACEHOLDER~'"$DT_ACCESS_API_TOKEN"'~' | \
  sed 's~DT_PAAS_TOKEN_PLACEHOLDER~'"$DT_WORKSHOP_TOKEN"'~' > $CREDS_FILE

echo "Saved credential to: $CREDS_FILE"
echo " "
echo " "
echo "========================================================================================================"
echo -e "${YLW}***** Please save the values below in a notepad for Challenge 02 when we install the Dynatrace Operator on AKS Cluster ***** ${NC}"
echo "--------------------------------------------------------------------------------------"
echo "Dynatrace Operator & Data Ingest Token 	:	$DT_WORKSHOP_TOKEN"
echo "API URL for Dynatrace Tenant	     	:	https://$DT_ENVIRONMENT_ID.live.dynatrace.com/api"
echo "========================================================================================================="

#cat $CREDS_FILE