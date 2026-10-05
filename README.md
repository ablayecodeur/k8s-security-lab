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
- `paie` : une API interne et le secret de sa base de données.

L'audit se place **à l'intérieur du pod de la boutique**, comme quelqu'un qui
aurait pris la main sur l'application, et regarde jusqu'où il peut aller.

## Les trois failles

| # | Faille | Où | État |
|---|---|---|---|
| 1 | RBAC trop large : le compte de service de la boutique est `cluster-admin` | `avant/20-boutique.yaml` | **Corrigée** (`correction/01-rbac.yaml`) |
| 2 | Aucune NetworkPolicy : la boutique joint l'API de la paie | tout le cluster | À corriger |
| 3 | Mot de passe en clair dans le manifest | `avant/20-boutique.yaml` | À corriger |

## Rejouer le lab

Prérequis : Docker, Minikube, kubectl.

```bash
bash scripts/00-cluster.sh                          # cluster dédié (profil k8s-security-lab)
bash scripts/01-deployer-avant.sh                   # l'état mal sécurisé
bash scripts/02-audit.sh > preuves/avant.txt        # les trois failles, constatées
bash scripts/03-corriger-rbac.sh                    # correction de la faille 1
bash scripts/02-audit.sh > preuves/apres-rbac.txt   # le même audit, après
diff preuves/avant.txt preuves/apres-rbac.txt
bash scripts/99-nettoyer.sh                         # supprime le cluster du lab
```

Chaque commande utilise `--context k8s-security-lab` : le contexte kubectl
courant n'est jamais modifié.

## Faille 1 — ce que l'audit a montré

Avant la correction, depuis le pod de la boutique :

| Action | Avant | Après |
|---|---|---|
| Lister tous les secrets du cluster | `200` | `403` |
| Lire le secret de la base de la paie | identifiant et mot de passe affichés | `403 Forbidden` |
| Lire sa propre ConfigMap (l'usage légitime) | `200` | `200` |

La correction remplace le `ClusterRoleBinding` vers `cluster-admin` par un
`Role` limité à un seul droit : `get` sur la ConfigMap `web-config`, dans le
namespace `boutique`. L'application garde ce dont elle a besoin, et rien d'autre.

Les sorties complètes sont dans `preuves/`.

## Ce qui reste ouvert

Le même audit, après la correction RBAC, montre que les failles 2 et 3 sont
toujours là : la boutique joint encore l'API de la paie (`200`), et le mot de
passe est toujours lisible dans le Deployment. Ce sont les deux prochaines
étapes.
