#!/usr/bin/env bash
# Déploie l'état « avant » : l'application volontairement mal sécurisée.
set -euo pipefail
cd "$(dirname "$0")/.."
K="kubectl --context k8s-security-lab"
$K apply -f avant/
$K -n boutique rollout status deploy/web --timeout=180s
$K -n paie rollout status deploy/paie-api --timeout=180s
$K -n paie rollout status deploy/paie-traitement --timeout=180s
