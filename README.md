# 📞 KubeVox : Le PBX Auto-Réparateur sur Kubernetes

**KubeVox** est un projet de démonstration technique montrant comment déployer un serveur de téléphonie **Asterisk** conteneurisé sur un cluster **Kubernetes**.

Le système est conçu pour être **"Self-Healing"** (auto-réparateur) : si le service de téléphonie plante, Kubernetes le redémarre automatiquement, garantissant une haute disponibilité basique.

---

## 🏗️ Architecture

Le projet repose sur les composants suivants :

* **OS Base :** Alpine Linux (pour une image Docker ultra-légère < 500MB).
* **Moteur VoIP :** Asterisk.
* **Orchestration :** Kubernetes (Deployment + Service NodePort).
* **Configuration :** Injection dynamique via `ConfigMap` (aucun fichier de configuration n'est "hardcodé" dans l'image).

![Architecture KubeVox](https://github.com/user-attachments/assets/3ba53f92-9bc5-4cef-8d82-416664a54855)

```plaintext
kubvox/
├── Dockerfile
├── README.md
├── asterisk_config/
│   ├── asterisk.conf
│   ├── pjsip.conf
│   ├── extensions.conf
│   └── rtp.conf
└── k8s/
    ├── deployment.yaml
    └── service.yaml
```
# 1. Dockerfile
Ce Dockerfile est optimisé pour créer une image Asterisk légère basée sur Alpine Linux.

```dockerfile
# Image de base légère
FROM alpine:3.18

# Installation d'Asterisk et des dépendances essentielles
# asterisk-sample-config : pour avoir la structure de base (que nous écraserons)
# asterisk-sounds-en : sons de base (vous pouvez ajouter fr)
# sox : pour la manipulation audio
RUN apk add --no-cache \
    asterisk \
    asterisk-sample-config \
    asterisk-sounds-en \
    asterisk-speex \
    asterisk-srtp \
    sox
```
# Suppression des configurations par défaut pour s'assurer que nous utilisons nos ConfigMaps montées via Kubernetes
RUN rm -rf /etc/asterisk/*

# Exposition des ports SIP (Signalisation) et RTP (Audio)
EXPOSE 5060/udp 5060/tcp
EXPOSE 10000-10050/udp

# Démarrage d'Asterisk au premier plan (-f) pour que le conteneur reste actif
ENTRYPOINT ["/usr/sbin/asterisk", "-f"]

### 2. Déploiement Kubernetes (`k8s/deployment.yaml`)
Cette configuration utilise `hostNetwork: true` pour simplifier la gestion complexe du NAT/RTP propre à la VoIP.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubvox-asterisk
  labels:
    app: kubvox
spec:
  replicas: 3 # Nombre de pods (instances) Asterisk
  selector:
    matchLabels:
      app: kubvox
  template:
    metadata:
      labels:
        app: kubvox
    spec:
      # hostNetwork est souvent requis pour la VoIP afin d'éviter le double NAT
      # et permettre au trafic audio (RTP) de passer correctement.
      hostNetwork: true
      containers:
      - name: asterisk
        image: kubvox:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5060
          protocol: UDP
        # Montage des fichiers de configuration depuis le ConfigMap
        volumeMounts:
        - name: asterisk-config
          mountPath: /etc/asterisk
      volumes:
      - name: asterisk-config
        configMap:
          name: asterisk-configmap
```
### 3. Service Kubernetes (`k8s/service.yaml`)
Si vous n'utilisez pas `hostNetwork`, vous utiliseriez un NodePort ou un LoadBalancer pour exposer le service.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubvox-service
spec:
  selector:
    app: kubvox
  # NodePort expose le service sur un port statique de chaque nœud du cluster
  type: NodePort
  ports:
    - name: sip-udp
      protocol: UDP
      port: 5060
      targetPort: 5060
      nodePort: 30060 # Port externe accessible
```
### 4. README.md

```markdown
# KubVox

**KubVox** est une solution de VoIP conteneurisée qui orchestre des instances Asterisk à l'aide de Kubernetes. Ce projet a été conçu dans le cadre d'une alternance en Master Informatique pour répondre aux défis d'évolutivité et de haute disponibilité des infrastructures téléphoniques traditionnelles.
```
## Prérequis
*   Docker installé
*   Minikube ou un Cluster Kubernetes (v1.24+)
*   `kubectl` configuré

## Démarrage Rapide

1.  **Construire l'image Docker :**
```bash
    docker build -t kubvox:latest .
```
2.  **Créer la ConfigMap (Exemple) :**
    Cette étape charge vos fichiers de configuration Asterisk dans le cluster.
```bash
    kubectl create configmap asterisk-configmap --from-file=asterisk_config/
```
3.  **Déployer sur Kubernetes :**
```bash
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
```
4.  **Vérifier les Pods :**
    Assurez-vous que les instances tournent correctement.
 ```bash
    kubectl get pods -o wide
```
## Architecture
KubVox exécute des pods Asterisk "sans état" (stateless). L'état d'enregistrement SIP est géré de manière externe (par exemple, via une base de données Redis) ou via des sessions persistantes au niveau du répartiteur de charge (Kamailio/OpenSIPS).
