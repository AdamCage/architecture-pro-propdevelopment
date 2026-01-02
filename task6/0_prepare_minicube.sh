#!/usr/bin/env bash
minikube stop
minikube delete

mkdir -p ~/.minikube/files/etc/ssl/certs

cp "./audit-policy.yaml" ~/.minikube/files/etc/ssl/certs/audit-policy.yaml

minikube start --driver=docker --cpus=4 --memory=6g \
  --extra-config=apiserver.audit-log-path=- \
  --extra-config=apiserver.audit-policy-file=/etc/ssl/certs/audit-policy.yaml

minikube addons enable metrics-server
minikube addons enable default-storageclass
minikube addons enable storage-provisioner

minikube status
