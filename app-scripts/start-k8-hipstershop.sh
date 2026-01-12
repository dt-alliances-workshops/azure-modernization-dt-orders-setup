#!/bin/bash
source ./_provision-scripts.lib
echo "=========================================================="
echo "Starting app on k8"
echo "=========================================================="

echo "----------------------------------------------------------"
echo "kubectl create namespace hipstershop"
echo "----------------------------------------------------------"
kubectl create ns hipstershop

echo "----------------------------------------------------------"
echo "kubectl -n hipstershop apply -f ./manifests/hipstershop"
echo "----------------------------------------------------------"
kubectl -n hipstershop apply -f ./manifests/hipstershop-manifest.yaml

echo "----------------------------------------------------------"
echo "kubectl -n hipstershop get pods"
echo "----------------------------------------------------------"
sleep 5
kubectl -n hipstershop get pods
POD_NAMES=$(kubectl -n hipstershop get pods --no-headers -o custom-columns=":metadata.name")
PROVISIONING_STEP="11-Provisioning app on k8-Hipstershop"
JSON_EVENT='{"id":"1","step":"'"$PROVISIONING_STEP"'","event.provider":"azure-workshop-provisioning","event.category":"azure-workshop","user":"'"$EMAIL"'","event.type":"provisioning-step","k8pods-hipster":"'"$POD_NAMES"'","DT_ENVIRONMENT_ID":"'"$DT_ENVIRONMENT_ID"'"}'
DT_SEND_EVENT=$(curl -s -X POST https://dt-event-send-dteve5duhvdddbea.eastus2-01.azurewebsites.net/api/send-event \
     -H "Content-Type: application/json" \
     -d "$JSON_EVENT")