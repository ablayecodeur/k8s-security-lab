#!/usr/bin/env bash
# Corrige la FAILLE 1 : retire cluster-admin, applique le rôle minimal.
set -euo pipefail
cd "$(dirname "$0")/.."
K="kubectl --context k8s-security-lab"
$K delete clusterrolebinding boutique-web-admin
$K apply -f correction/01-rbac.yaml
