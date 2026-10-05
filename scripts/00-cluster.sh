#!/usr/bin/env bash
# Crée le cluster du lab dans un profil Minikube séparé, sans toucher au
# contexte kubectl courant (--keep-context). Calico est le plugin réseau :
# c'est lui qui appliquera les NetworkPolicy à l'étape de correction réseau.
set -euo pipefail
minikube start -p k8s-security-lab --driver=docker --cni=calico \
  --cpus=2 --memory=3072 --keep-context
kubectl --context k8s-security-lab wait --for=condition=Ready nodes --all --timeout=180s
