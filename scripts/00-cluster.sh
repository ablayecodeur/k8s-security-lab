#!/usr/bin/env bash
# Crée le cluster du lab dans un profil Minikube séparé, sans toucher au
# contexte kubectl courant (--keep-context). Calico est le plugin réseau :
# c'est lui qui appliquera les NetworkPolicy à l'étape de correction réseau.
set -euo pipefail
# --keep-context ne suffit pas lors d'un redémarrage : on mémorise le contexte
# courant et on le rétablit après coup.
CONTEXTE_AVANT="$(kubectl config current-context 2>/dev/null || true)"
minikube start -p k8s-security-lab --driver=docker --cni=calico \
  --cpus=2 --memory=3072 --keep-context
if [ -n "$CONTEXTE_AVANT" ] && [ "$CONTEXTE_AVANT" != "k8s-security-lab" ]; then
  kubectl config use-context "$CONTEXTE_AVANT" >/dev/null
fi
kubectl --context k8s-security-lab wait --for=condition=Ready nodes --all --timeout=180s
