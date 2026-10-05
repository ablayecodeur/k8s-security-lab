#!/usr/bin/env bash
# Corrige la FAILLE 2 : ferme le namespace de la paie aux autres équipes.
set -euo pipefail
cd "$(dirname "$0")/.."
K="kubectl --context k8s-security-lab"
$K apply -f correction/02-reseau.yaml
