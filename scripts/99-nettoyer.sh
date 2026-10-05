#!/usr/bin/env bash
# Supprime entièrement le cluster du lab (et rien d'autre).
set -euo pipefail
minikube delete -p k8s-security-lab
