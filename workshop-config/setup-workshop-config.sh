#!/bin/bash

source ./_workshop-config.lib

# optional argument.  If not based, then the base workshop is setup.
# setup types are for additional features like kubernetes
SETUP_TYPE=$1
DASHBOARD_OWNER_EMAIL=$2    # This is required for the dashboard monaco project
                            # Otherwise it is not required
MONACO_PROJECT_BASE_PATH=./monaco-files/projects
MONACO_ENVIONMENT_FILE=./monaco-files/environments.yaml

create_service_principal_monaco_config() {

    AZURE_SP_JSON_FILE="../gen/workshop-azure-service-principal.json"

    MONACO_WORSHOP_PROJECT=workshop
    MONACO_CONFIG_FOLDER="$MONACO_PROJECT_BASE_PATH/$MONACO_WORSHOP_PROJECT"

    MONACO_JSON_FILE="$MONACO_CONFIG_FOLDER/azure-credentials/azure-credentials.json"
    MONACO_CONFIG_FILE="$MONACO_CONFIG_FOLDER/azure-credentials/config.yaml"

    AZURE_SP_APP_ID=$(cat $AZURE_SP_JSON_FILE | jq -r '.appId')
    AZURE_SP_DIRECTORY_ID=$(cat $AZURE_SP_JSON_FILE | jq -r '.tenant')
    AZURE_SP_KEY=$(cat $AZURE_SP_JSON_FILE | jq -r '.password')

    # A user maynot have permissions to make an Azure service principal
    # so only make the monaco config if they do
    if ! [ -z "$AZURE_SP_APP_ID" ]; then
        mkdir -p "$MONACO_CONFIG_FOLDER/azure-credentials"

        echo "*** Generating $MONACO_CONFIG_FILE file used by monaco ***"
        echo "config:" > $MONACO_CONFIG_FILE
        echo "- credentials: \"azure-credentials.json\"" >> $MONACO_CONFIG_FILE
        echo "" >> $MONACO_CONFIG_FILE
        echo "credentials:" >> $MONACO_CONFIG_FILE
        echo "- name: \"azure-modernize-workshop\"" >> $MONACO_CONFIG_FILE
        echo "- appId: \"$AZURE_SP_APP_ID\"" >> $MONACO_CONFIG_FILE
        echo "- directoryId: \"$AZURE_SP_DIRECTORY_ID\"" >> $MONACO_CONFIG_FILE
        echo "- key: \"$AZURE_SP_KEY\"" >> $MONACO_CONFIG_FILE
        
        echo ""
        echo "*** Generated $MONACO_CONFIG_FILE file contents ***"
        cat $MONACO_CONFIG_FILE

        echo "*** Generating $MONACO_JSON_FILE file used by monaco ***"
        echo "{" > $MONACO_JSON_FILE
        echo "\"label\": \"{{ .name }}\"," >> $MONACO_JSON_FILE
        echo "\"appId\": \"{{ .appId }}\"," >> $MONACO_JSON_FILE
        echo "\"directoryId\": \"{{ .directoryId }}\"," >> $MONACO_JSON_FILE
        echo "\"active\": true," >> $MONACO_JSON_FILE
        echo "\"key\": \"{{ .key }}\"," >> $MONACO_JSON_FILE
        echo "\"autoTagging\": true," >> $MONACO_JSON_FILE
        echo "\"monitorOnlyTaggedEntities\": false," >> $MONACO_JSON_FILE
        echo "\"monitorOnlyTagPairs\": []" >> $MONACO_JSON_FILE
        echo "}" >> $MONACO_JSON_FILE

        echo ""
        echo "*** Generated $MONACO_JSON_FILE file contents ***"
        cat $MONACO_JSON_FILE
    else
        echo ""
        echo "*** Skipping Azure monitor setup due to invalid service principal file ***"
        echo ""
        echo "cat $AZURE_SP_JSON_FILE"
        cat $AZURE_SP_JSON_FILE
        echo ""
    fi
}

download_monaco() {
    if [ $(uname -s) == "Darwin" ]
    then
        MONACO_BINARY="v1.6.0/monaco-darwin-10.12-amd64"
    else
        MONACO_BINARY="v1.6.0/monaco-linux-amd64"
    fi
    echo "Getting MONACO_BINARY = $MONACO_BINARY"
    rm -f monaco
    wget -q -O monaco https://github.com/dynatrace-oss/dynatrace-monitoring-as-code/releases/download/$MONACO_BINARY
    chmod +x monaco
    echo "Installed monaco version: $(./monaco --version | tail -1)"
}

run_monaco() {
    MONACO_PROJECT=$1
    DASHBOARD_OWNER=$2
    if [ -z "$1" ]; then
        MONACO_PROJECT=workshop
    else
        MONACO_PROJECT=$1
    fi

    echo "Running monaco for project = $MONACO_PROJECT"
    echo "monaco deploy -v --environments $MONACO_ENVIONMENT_FILE --project $MONACO_PROJECT $MONACO_PROJECT_BASE_PATH"

    # add the --dry-run argument during testing
    export NEW_CLI=1 && export DT_BASEURL=$DT_BASEURL && export DT_API_TOKEN=$DT_API_TOKEN && \
        ./monaco deploy -v \
        --environments $MONACO_ENVIONMENT_FILE \
        --project $MONACO_PROJECT \
        $MONACO_PROJECT_BASE_PATH
}

run_custom_dynatrace_config() {
    setFrequentIssueDetectionOff
    setServiceAnomalyDetection ./custom/service-anomalydetection.json
}

echo ""
echo "-----------------------------------------------------------------------------------"
echo "Setting up Workshop config"
echo "Dynatrace  : $DT_BASEURL"
echo "Starting   : $(date)"
echo "-----------------------------------------------------------------------------------"
echo ""

case "$SETUP_TYPE" in
    "cluster") 
        echo "Setup type = cluster"
        download_monaco
        run_monaco cluster
        echo "-----------------------------------------------------------------------------------"
        echo "Sometimes a timing issue with SLO creation, so will repeat in 10 seconds"
        echo "-----------------------------------------------------------------------------------"
        sleep 10
        run_monaco cluster
        ;;
    "services-vm") 
        echo "Setup type = services-vm"
        download_monaco
        run_monaco services-vm
        echo "-----------------------------------------------------------------------------------"
        echo "Sometimes a timing issue with SLO creation, so will repeat in 10 seconds"
        echo "-----------------------------------------------------------------------------------"
        sleep 10
        run_monaco services-vm
        run_custom_dynatrace_config
        ;;
    "synthetics") 
        echo "Setup type = synthetics"
        run_monaco synthetics
        ;;
    "dashboard") 
        if [ -z $DASHBOARD_OWNER_EMAIL ]; then
            echo "ABORT dashboard owner email is required argument"
            echo "syntax: ./setup-workshop-config.sh dashboard name@company.com"
            exit 1
        else
            echo "Setup type = dashboard"
            run_monaco db $DASHBOARD_OWNER_EMAIL
        fi
        ;;
    "monolith-vm")
        echo "Setup type = monolith-vm"
        download_monaco
        run_monaco monolith-vm
        echo "-----------------------------------------------------------------------------------"
        echo "Sometimes a timing issue with SLO creation, so will repeat in 10 seconds"
        echo "-----------------------------------------------------------------------------------"
        sleep 10
        run_monaco monolith-vm
        run_custom_dynatrace_config
        ;;
    *)
        echo ""
        echo "-----------------------------------------------------------------------------------"
        echo "ERROR: Missing or invalid SETUP_TYPE argument"
        echo "Valid values are: monolith-vm, services-vm, cluster, dashboard"
        echo ""
        exit 1
        ;;
esac
 
echo ""
echo "-----------------------------------------------------------------------------------"
echo "Done Setting up Workshop config"
echo "End: $(date)"
echo "-----------------------------------------------------------------------------------"
