#!/bin/bash

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
