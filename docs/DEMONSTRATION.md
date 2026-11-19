# Démonstration de la soutenance — du code à la production, avec la supervision

Durée : **environ 7 minutes**. Les commandes se lancent depuis le **poste Ubuntu** (`kubectl` déjà
configuré par `outils/acces-poste/installer.sh`).

| Adresse | Rôle |
|---|---|
| https://dev.elyse-cloud.duckdns.org/api/ | Application, environnement dev |
| https://staging.elyse-cloud.duckdns.org/api/ | Application, environnement staging |
| https://prod.elyse-cloud.duckdns.org/api/ | Application, environnement prod |
| https://argocd.elyse-cloud.duckdns.org | ArgoCD (déploiement GitOps) |
| https://grafana.elyse-cloud.duckdns.org | Grafana (tableaux de bord) |
| https://prometheus.elyse-cloud.duckdns.org | Prometheus (métriques) |
| https://github.com/cloudarmelpro | Les trois dépôts du projet |

---

## A. Préparation (30 minutes avant)

**A1. Vérifier le cluster et ArgoCD**

```bash
kubectl get nodes
kubectl -n argocd get applications
```

Attendu : 3 nœuds « Ready », toutes les applications « Synced » et « Healthy ».

**A2. Récupérer les mots de passe** (les noter sur papier, ne pas les publier)

ArgoCD (utilisateur `admin`) :

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

Grafana (utilisateur `admin`) :

```bash
kubectl -n monitoring get secret supervision-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

Prometheus (utilisateur, puis mot de passe) :

```bash
kubectl -n monitoring get secret prometheus-acces -o jsonpath='{.data.username}' | base64 -d; echo
kubectl -n monitoring get secret prometheus-acces -o jsonpath='{.data.password}' | base64 -d; echo
```

**A3. Ouvrir et connecter les 6 onglets**, dans cet ordre

| N° | Onglet | Adresse |
|---|---|---|
| 1 | Application | https://dev.elyse-cloud.duckdns.org/api/ |
| 2 | Code | https://github.com/cloudarmelpro/uaa-portal-api/blob/main/src/main.py |
| 3 | Pipeline | https://github.com/cloudarmelpro/uaa-portal-api/actions |
| 4 | ArgoCD | https://argocd.elyse-cloud.duckdns.org (ouvrir la tuile **portal-api-dev**) |
| 5 | Grafana | https://grafana.elyse-cloud.duckdns.org |
| 6 | Prometheus | https://prometheus.elyse-cloud.duckdns.org |

**A4. Préparer Grafana**

1. Menu **Dashboards** → chercher **« Kubernetes / Compute Resources / Namespace (Pods) »**.
2. En haut : **namespace = portal-api-dev**, période **Last 15 minutes**.

**A5. Préparer Prometheus**

Onglet **Query**, coller la requête suivante sans encore cliquer sur *Execute* :

```
kube_pod_container_info{namespace="portal-api-dev"}
```

**A6. Préparer le terminal**

Agrandir la police, puis taper **sans appuyer sur Entrée** :

```bash
kubectl -n portal-api-dev get pods -w
```

**A7. Répétition**

Faire une fois les étapes B2 à B5 avec un message de test : les 3 jobs doivent passer au vert et le
message doit changer en ligne.

---

## B. Pendant la soutenance

### B1. L'application actuelle (30 s)

Onglet 1 : recharger la page, le message actuel s'affiche.

> « Voici l'application de l'université, déployée automatiquement sur notre cluster Kubernetes dans AWS.
> Nous allons modifier son code devant vous. »

### B2. Modifier le code (1 min)

1. Onglet 2 : cliquer sur le **crayon ✏️**.
2. Sur la ligne `"message":`, remplacer le texte entre guillemets par :
   `Bonjour au jury de l'ENI - soutenance du 19 novembre 2026`
   (garder les guillemets et la virgule).
3. **Commit changes…** → **Propose changes** → **Create pull request**
   (la branche `main` est protégée : toute modification passe par une demande de fusion).
4. Attendre que les contrôles de la pull request passent au vert (**analyses-code** et **image**,
   environ 1 minute), puis **Merge pull request** → **Confirm merge**.
   **C'est la seule validation à faire** : aucune approbation n'est demandée pour l'environnement dev.

> « Je n'ai touché à aucun serveur : j'ai seulement proposé une modification du code. Elle est testée
> avant d'être acceptée, et c'est la fusion qui déclenche le déploiement. »

### B3. Le pipeline CI/CD (1 min 30)

Onglet 3 : ouvrir l'exécution lancée par la fusion (en haut de la liste, branche `main`).
Les 3 jobs s'enchaînent en environ 75 secondes, sans aucune action à faire :

1. **analyses-code** : tests et contrôles du code ;
2. **image** : construction de l'image Docker, envoi dans Amazon ECR avec l'étiquette `sha-` + début du commit ;
3. **maj-gitops** : écriture de la nouvelle version dans le dépôt de configuration.

> « La chaîne d'intégration ne touche jamais au cluster : elle écrit seulement la nouvelle version dans Git. »

### B4. ArgoCD déploie (1 min)

1. Dès que **maj-gitops** est vert : appuyer sur **Entrée** dans le terminal.
2. Onglet 4 : **Refresh** dans portal-api-dev.
3. Montrer le nouveau pod qui démarre (ArgoCD et terminal), puis l'ancien qui s'arrête. **Ctrl+C**.

> « ArgoCD a vu la nouvelle version dans Git et l'a appliquée. L'ancienne version reste en service tant
> que la nouvelle n'est pas prête : aucune interruption. »

### B5. Voir le changement (30 s)

Onglet 1 : **Ctrl+F5**, le nouveau message s'affiche.

> « En moins de trois minutes, la modification est en ligne, sans aucune intervention manuelle. »

### B6. Prometheus : la nouvelle version est mesurée (45 s)

1. Onglet 6 : **Execute**. Le résultat montre l'image en service `…/uaa/portal-api:sha-xxxxxxx`,
   avec le numéro du commit que l'on vient de faire.
2. Remplacer la requête, puis **Execute** :

   ```
   kube_deployment_status_replicas_available{namespace=~"portal-api.*"}
   ```

   Réplicas disponibles par environnement : 1 en dev, 1 en staging, 2 en production.

> « Prometheus collecte en permanence l'état du cluster : la version déployée correspond bien au
> commit, et chaque environnement a ses réplicas disponibles. »

### B7. Grafana : le tableau de bord (45 s)

1. Onglet 5 : tableau de bord **Namespace (Pods)**, réglé sur **portal-api-dev**.
2. Montrer les courbes de CPU et de mémoire : au moment du déploiement, le nouveau pod apparaît et
   l'ancien disparaît.
3. Passer le namespace à **portal-api-prod** : les 2 pods de la production.

> « Grafana présente ces mesures sous forme de tableaux de bord : l'équipe de la DSIN peut suivre la
> consommation de chaque application et repérer un problème après un déploiement. »

### Conclusion (15 s)

> « Une modification du code est testée, construite, déployée et surveillée automatiquement. Tout passe
> par Git : chaque déploiement est traçable et réversible. »

---

## C. Si le jury demande plus

**C1. Correction automatique d'une modification faite à la main (30 s)**

```bash
kubectl -n portal-api-dev scale deployment portal-api --replicas=5
kubectl -n portal-api-dev get deployment portal-api -w
```

Les réplicas repassent de 5 à 1 en environ 2 secondes (Ctrl+C pour arrêter).

> « C'est Git qui fait foi : ArgoCD annule toute modification faite à la main. »

**C2. Promotion vers staging (1 min)**

1. https://github.com/cloudarmelpro/uaa-platform-gitops/actions → workflow **promotion** → **Run workflow**.
2. Choisir `portal-api` et `staging` → **Run workflow**.
3. Une fois vert : **Refresh** dans ArgoCD (portal-api-staging), puis ouvrir
   https://staging.elyse-cloud.duckdns.org/api/

> « On ne reconstruit pas l'image : on promeut la version déjà validée. »

Staging ne demande aucune approbation. Pour la **production** (seulement si le jury le demande) :
même workflow avec `prod` ; l'exécution s'arrête sur **Review deployments** → cocher **prod** →
**Approve and deploy**. C'est la seule approbation de toute la plateforme.

> « La production exige l'approbation d'une personne autorisée : GitHub garde son nom et la date. »

**C3. Les cibles surveillées par Prometheus**

Onglet 6 → **Status** → **Target health** : toutes les sources de mesures sont « UP ».

---

## D. Si quelque chose bloque

| Problème | Que faire |
|---|---|
| Un job est rouge | L'ouvrir et montrer l'erreur : « le pipeline s'arrête avant le déploiement, une version défectueuse n'arrive jamais en ligne » |
| Le message ne change pas | **Refresh** dans ArgoCD, attendre 30 s, puis Ctrl+F5 |
| Grafana demande de se reconnecter | Utilisateur `admin` et le mot de passe noté en A2 |
| Prometheus n'affiche rien | Vérifier la requête, période 15 minutes, puis Execute |
| kubectl ne répond pas | Faire toute la démo dans le navigateur ; le terminal n'est qu'un bonus |

---

## E. Après la soutenance

1. Remettre le message d'origine sur GitHub (comme en B2) :
   `Bonjour depuis la plateforme GitOps de l'Université d'Androy`
2. Détruire le cluster (environ 0,30 USD par heure), depuis le poste d'Armel :

   ```bash
   bash /d/SOUTENANCE/uaa-plateforme/outils/arreter-session.sh
   ```
