#!/usr/bin/env bash
# Audit des trois failles, depuis l'INTÉRIEUR du pod de la boutique : on se
# met à la place de quelqu'un qui aurait pris la main sur l'application.
# Usage : bash scripts/02-audit.sh > preuves/avant.txt
set -uo pipefail
K="kubectl --context k8s-security-lab"
IN="$K -n boutique exec deploy/web --"
API="https://kubernetes.default.svc"
# Le jeton du compte de service, monté automatiquement dans chaque pod.
AUTH='Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)'

echo "=== FAILLE 1 — RBAC : que peut faire le compte de service de la boutique ?"
echo "\$ kubectl auth can-i list secrets --all-namespaces --as=system:serviceaccount:boutique:web"
$K auth can-i list secrets --all-namespaces --as=system:serviceaccount:boutique:web
echo
echo "Depuis le pod : lister tous les secrets du cluster (code HTTP)"
$IN sh -c "curl -sk -o /dev/null -w '%{http_code}\n' -H \"$AUTH\" $API/api/v1/secrets"
echo
echo "Depuis le pod : lire le secret de la paie"
$IN sh -c "curl -sk -H \"$AUTH\" $API/api/v1/namespaces/paie/secrets/paie-db" \
  | python3 -c "
import sys, json, base64
d = json.load(sys.stdin)
if d.get('kind') == 'Secret':
    for k, v in d['data'].items():
        print(f'  {k} = {base64.b64decode(v).decode()}')
else:
    print(f\"  refusé : {d.get('code')} {d.get('reason')} — {d.get('message')}\")
"
echo
echo "Depuis le pod : lire sa propre ConfigMap (l'usage légitime, code HTTP)"
$IN sh -c "curl -sk -o /dev/null -w '%{http_code}\n' -H \"$AUTH\" $API/api/v1/namespaces/boutique/configmaps/web-config"
echo
echo "=== FAILLE 2 — Réseau : la boutique peut-elle joindre l'API de la paie ?"
echo "Depuis le pod : GET http://paie-api.paie.svc.cluster.local (code HTTP, 000 = injoignable)"
$IN sh -c "curl -s -m 5 -o /dev/null -w '%{http_code}\n' http://paie-api.paie.svc.cluster.local"
echo "NetworkPolicy présentes dans le cluster :"
$K get networkpolicy --all-namespaces 2>&1
echo
echo "=== FAILLE 3 — Secret en clair : que voit-on en lisant le Deployment ?"
echo "\$ kubectl -n boutique get deploy web -o jsonpath='{.spec.template.spec.containers[0].env}'"
$K -n boutique get deploy web -o jsonpath='{.spec.template.spec.containers[0].env}'
echo
