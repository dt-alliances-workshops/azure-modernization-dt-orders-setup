#!/bin/bash

HOST_TYPE=$1
if [ -z "$HOST_TYPE" ]
then
    echo "Missing HOST_TYPE argument"
    exit 1
fi

APP_SCRIPTS_FULL_PATH=/home/workshop/azure-modernization-dt-orders-setup/app-scripts

setup_monolith() {
    echo "----------------------------------------------------"
    echo "Setup Tools"
    echo "----------------------------------------------------"
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    apt-get install -y jq
    apt install -y docker-compose

    echo "----------------------------------------------------"
    echo "Install OneAgent"
    echo "----------------------------------------------------"
    /bin/sh /tmp/Dynatrace-OneAgent-Linux.sh --set-app-log-content-access=true --set-infra-only=false --set-host-group=dt-orders-monolith

    echo "----------------------------------------------------"
    echo "Start Monolith App"
    echo "----------------------------------------------------"
    . $APP_SCRIPTS_FULL_PATH/start-monolith.sh
}

setup_services() {
    echo "----------------------------------------------------"
    echo "Setup Tools"
    echo "----------------------------------------------------"
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    apt-get install -y jq
    apt install -y docker-compose
  
    echo "----------------------------------------------------"
    echo "Install OneAgent"
    echo "----------------------------------------------------"
    /bin/sh /tmp/Dynatrace-OneAgent-Linux.sh --set-app-log-content-access=true --set-infra-only=false --set-host-group=dt-orders-services

    echo "----------------------------------------------------"
    echo "Start Services App"
    echo "----------------------------------------------------"
    . $APP_SCRIPTS_FULL_PATH/start-services.sh
}


case "$HOST_TYPE" in
    "dt-orders-monolith") 
        echo "===================================================="
        echo "Setting up: $HOST_TYPE" 
        echo "===================================================="
        setup_monolith
        ;;
    "dt-orders-services") 
        echo "===================================================="
        echo "Setting up: $HOST_TYPE" 
        echo "===================================================="
        setup_services
        ;;
    *) 
        echo "Invalid HOST_TYPE: $HOST_TYPE"
        exit 1
        ;;
esac

echo "===================================================="
echo "Setup Complete" 
echo "===================================================="
echo ""