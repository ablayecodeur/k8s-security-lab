#!/usr/bin/env bash
# Corrige la FAILLE 3 : le mot de passe sort du manifest.
#
# L'ancien mot de passe a été committé : il reste dans l'historique Git et
# doit être considéré comme compromis. On en génère donc un NOUVEAU, qui
# n'est écrit dans aucun fichier.
set -euo pipefail
cd "$(dirname "$0")/.."
K="kubectl --context k8s-security-lab"
if ! $K -n boutique get secret boutique-db >/dev/null 2>&1; then
  $K -n boutique create secret generic boutique-db \
    --from-literal=mot-de-passe="$(openssl rand -hex 24)"
fi
$K apply -f correction/03-secret.yaml
$K -n boutique rollout status deploy/web --timeout=180s
