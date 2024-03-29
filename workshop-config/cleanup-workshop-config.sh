#!/bin/bash

source ./_workshop-config.lib

run_monaco_delete() {
    # run monaco as code script
    PROJECT_BASE_PATH=./monaco-files/projects
    PROJECT=$1    
    CREDS_FILE="../gen/workshop-credentials.json"    
    DASHBOARD_OWNER=$(cat $CREDS_FILE | jq -r '.DT_DASHBOARD_OWNER_EMAIL')
    ENVIONMENT_FILE=./monaco-files/environments.yaml

    echo "-------------------------------------------------------------------"
    echo "Deleting project: $PROJECT"
    echo "-------------------------------------------------------------------"
    cp $PROJECT_BASE_PATH/$PROJECT/delete.txt $PROJECT_BASE_PATH/delete.yaml 
    export NEW_CLI=1 && export DT_BASEURL=$DT_BASEURL && export DT_API_TOKEN=$DT_API_TOKEN && export OWNER=$DASHBOARD_OWNER && ./monaco deploy --environments $ENVIONMENT_FILE --project $PROJECT $PROJECT_BASE_PATH
    #rm $PROJECT_BASE_PATH/delete.yaml 
}

reset_custom_dynatrace_config() {
    setFrequentIssueDetectionOn
    setServiceAnomalyDetection ./custom/service-anomalydetectionDefault.json
}

# this supports the clean up to run without a prompt.  
# Just pass in an argument ./cleanup-workshop-config.sh Y
if [ -z $1 ]; then
    echo "==================================================================="
    echo "About to Delete Workshop configuration on $DT_BASEURL"
    echo "==================================================================="
    read -p "Proceed? (y/n) : " REPLY;
else
    REPLY=$1
fi

if [[ $REPLY =~ ^[Yy]$ ]]; then

    echo ""
    echo "*** Removing Dynatrace config ***"
    echo

    run_monaco_delete workshop
    run_monaco_delete k8
    #run_monaco_delete services-vm
    #run_monaco_delete synthetics
    run_monaco_delete db $DASHBOARD_OWNER_EMAIL

    reset_custom_dynatrace_config

    echo ""
    echo "*** Done Removing Dynatrace config ***"
    echo ""
fi