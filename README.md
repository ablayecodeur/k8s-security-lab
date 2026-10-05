# K8s Security Lab

Un mini-cluster Kubernetes **volontairement mal sécurisé**, audité puis corrigé
faille par faille, avec la preuve avant/après à chaque étape. Tout tourne en
local sur Minikube, dans un profil séparé : aucun coût, aucun autre cluster
touché.

> Les manifests du dossier `avant/` sont dangereux par construction. Ils ne
> doivent jamais être appliqués ailleurs que dans ce lab.

## Le scénario

Deux équipes partagent un cluster :

- `boutique` : l'application qu'on audite ;
- `paie` : une API interne, son traitement, et le secret de sa base de données.

L'audit se place **à l'intérieur du pod de la boutique**, comme quelqu'un qui
aurait pris la main sur l'application, et regarde jusqu'où il peut aller.

## Les trois failles

| # | Faille | Correction | État |
|---|---|---|---|
| 1 | RBAC trop large : le compte de service de la boutique est `cluster-admin` | `correction/01-rbac.yaml` | Corrigée |
| 2 | Aucune NetworkPolicy : la boutique joint l'API de la paie | `correction/02-reseau.yaml` | Corrigée |
| 3 | Mot de passe en clair dans le manifest | `correction/03-secret.yaml` | Corrigée |

## Rejouer le lab

Prérequis : Docker, Minikube, kubectl, openssl.

```bash
bash scripts/00-cluster.sh                                # cluster dédié (profil k8s-security-lab)
bash scripts/01-deployer-avant.sh                         # l'état mal sécurisé
bash scripts/02-audit.sh > preuves/0-avant.txt            # les trois failles, constatées

bash scripts/03-corriger-rbac.sh                          # faille 1
bash scripts/02-audit.sh > preuves/1-apres-rbac.txt

bash scripts/04-corriger-reseau.sh                        # faille 2
bash scripts/02-audit.sh > preuves/2-apres-reseau.txt

bash scripts/05-corriger-secret.sh                        # faille 3
bash scripts/02-audit.sh > preuves/3-apres-secret.txt

bash scripts/98-reinitialiser.sh                          # revenir à zéro, cluster conservé
bash scripts/99-nettoyer.sh                               # supprimer le cluster du lab
```

Le même script d'audit est rejoué après chaque correction : on voit ce qui
change, et ce qui ne doit pas changer. Chaque commande utilise
`--context k8s-security-lab` ; le contexte kubectl courant n'est pas modifié.

## Ce que l'audit a montré

Chaque correction est jugée sur deux critères : l'accès abusif est fermé, et
**l'usage légitime marche toujours**.

### Faille 1 — les droits

| Depuis le pod de la boutique | Avant | Après |
|---|---|---|
| Lister tous les secrets du cluster | `200` | `403` |
| Lire le secret de la base de la paie | identifiant et mot de passe affichés | `403 Forbidden` |
| Lire sa propre ConfigMap (usage légitime) | `200` | `200` |

Le `ClusterRoleBinding` vers `cluster-admin` est remplacé par un `Role` limité à
un seul droit : `get` sur la ConfigMap `web-config`, dans le namespace `boutique`.

### Faille 2 — le réseau

| Appel vers l'API de la paie | Avant | Après |
|---|---|---|
| Depuis la boutique | `200` | `000` (délai dépassé) |
| Depuis le traitement de paie (usage légitime) | `200` | `200` |

Deux `NetworkPolicy` dans le namespace `paie` : tout refuser en entrée, puis
autoriser uniquement les pods de la paie vers son API. Elles n'ont d'effet que
parce que le cluster utilise Calico : sans plugin réseau qui les applique, ces
objets sont acceptés par l'API et ignorés.

### Faille 3 — le secret

| Vérification | Avant | Après |
|---|---|---|
| Lecture du Deployment | mot de passe en clair | une référence `secretKeyRef` |
| L'application a son mot de passe | oui | oui |
| Le compte de service peut lire les Secrets | oui | non |

Le mot de passe est déplacé dans un `Secret` Kubernetes, créé par script et
absent de tout fichier. Comme l'ancien avait été committé, un **nouveau** mot de
passe est généré : celui de l'historique Git doit être considéré comme compromis.

Les sorties complètes sont dans `preuves/`.

## Limites

- Un `Secret` Kubernetes est encodé en base64, pas chiffré. Sans chiffrement au
  repos ni gestionnaire de secrets externe, il reste lisible par quiconque a le
  droit de le lire dans le namespace. La correction 1 retire ce droit au compte
  de service de la boutique.
- Les règles réseau ne filtrent que les **entrées** de la paie. Les sorties de
  la boutique vers Internet ne sont pas restreintes.
- L'image `nginx:1.27` n'est ni analysée ni épinglée par son empreinte.
