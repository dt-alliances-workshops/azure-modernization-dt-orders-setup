#!/bin/bash

source ./_provision-scripts.lib

echo "=========================================================="
echo "Starting app on k8"
echo "=========================================================="

echo "=========================================================="
echo "Start App #1 - Hipster shop"
echo "=========================================================="
./start-k8-hipstershop.sh


echo "=========================================================="
echo "Start App#2 - DT Orders"
echo "=========================================================="

echo "----------------------------------------------------------"
echo "kubectl create namespace staging"
echo "----------------------------------------------------------"
kubectl create ns staging

echo "----------------------------------------------------------"
echo "kubectl create -f manifests/dynatrace-oneagent-metadata-viewer.yaml"
echo "----------------------------------------------------------"
kubectl create -f manifests/dynatrace-oneagent-metadata-viewer.yaml

echo "----------------------------------------------------------"
echo "kubectl -n staging apply -f catalog-service.yml"
echo "----------------------------------------------------------"
kubectl -n staging apply -f manifests/catalog-service.yml

echo "----------------------------------------------------------"
echo "kubectl -n staging apply -f manifests/customer-service.yml"
echo "----------------------------------------------------------"
kubectl -n staging apply -f manifests/customer-service.yml

echo "----------------------------------------------------------"
echo "kubectl -n staging apply -f manifests/order-service.yml"
echo "----------------------------------------------------------"
kubectl -n staging apply -f manifests/order-service.yml

echo "----------------------------------------------------------"
echo "kubectl -n staging apply -f manifests/frontend.yml"
echo "----------------------------------------------------------"
kubectl -n staging apply -f manifests/frontend.yml

echo "----------------------------------------------------------"
echo "kubectl -n staging apply -f manifests/browser-traffic.yml"
echo "----------------------------------------------------------"
kubectl -n staging apply -f manifests/browser-traffic.yml

echo "----------------------------------------------------------"
echo "kubectl -n staging apply -f manifests/load-traffic.yml"
echo "----------------------------------------------------------"
kubectl -n staging apply -f manifests/load-traffic.yml

echo "----------------------------------------------------------"
echo "kubectl -n staging get pods"
echo "----------------------------------------------------------"
sleep 5
kubectl -n staging get pods
POD_NAMES=$(kubectl -n staging get pods --no-headers -o custom-columns=":metadata.name")
PROVISIONING_STEP="11-Provisioning app on k8-DTOrders"
JSON_EVENT='{"id":"1","step":"'"$PROVISIONING_STEP"'","event.provider":"azure-workshop-provisioning","event.category":"azure-workshop","user":"'"$EMAIL"'","event.type":"provisioning-step","k8pods-staging":"'"$POD_NAMES"'","DT_ENVIRONMENT_ID":"'"$DT_ENVIRONMENT_ID"'"}'
DT_SEND_EVENT=$(curl -s -X POST https://dt-event-send-dteve5duhvdddbea.eastus2-01.azurewebsites.net/api/send-event \
     -H "Content-Type: application/json" \
     -d "$JSON_EVENT")