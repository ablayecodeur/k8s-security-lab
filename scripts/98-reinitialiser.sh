#!/usr/bin/env bash
# Remet le lab à zéro (sans supprimer le cluster), pour le rejouer depuis
# l'état « avant ».
set -euo pipefail
K="kubectl --context k8s-security-lab"
$K delete namespace boutique paie --ignore-not-found --wait=true
$K delete clusterrolebinding boutique-web-admin --ignore-not-found
