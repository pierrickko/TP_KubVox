📞 KubeVox : Le PBX Auto-Réparateur sur Kubernetes
KubeVox est un projet de démonstration technique montrant comment déployer un serveur de téléphonie Asterisk conteneurisé sur un cluster Kubernetes. Le système est conçu pour être "Self-Healing" (auto-réparateur) : si le service de téléphonie plante, Kubernetes le redémarre automatiquement.

🏗️ Architecture
Le projet repose sur les composants suivants :
- OS Base : Alpine Linux (pour une image Docker < 500MB).
- Moteur VoIP : Asterisk.
- Orchestration : Kubernetes (Deployment + Service NodePort).
- Configuration : Injection dynamique via ConfigMap (pas de fichiers de config "hardcodés" dans l'image).

<img width="3999" height="2615" alt="image" src="https://github.com/user-attachments/assets/3ba53f92-9bc5-4cef-8d82-416664a54855" />

🚀 Prérequis
Pour lancer ce projet, vous avez besoin de :
- Docker (pour construire l'image).
- Kubernetes (Minikube, Docker Desktop K8s, ou un cluster Cloud).
- Python 3.x (uniquement pour générer la présentation PowerPoint).
- Un Softphone (ex: Zoiper, Linphone, MicroSIP) pour tester les appels.

🛠️ Installation Rapide
1. Générer les fichiers du projet
Si vous n'avez pas encore les fichiers, lancez le script d'installation fourni :

chmod +x install.sh
./install.sh

2. Construire l'image Docker
Placez-vous dans le dossier kubevox créé et construisez l'image :

cd kubevox
docker build -t kubevox:latest .

3. Charger l'image dans Kubernetes (Si local)
Si vous utilisez Minikube :

minikube image load kubevox:latest

Si vous utilisez Docker Desktop : L'image est déjà disponible localement.

4. Déployer sur Kubernetes
Appliquez les manifestes (ConfigMap, Deployment, Service) :

kubectl apply -f k8s/

Vérifiez que le pod tourne :

kubectl get pods

☎️ Utilisation (Test d'appel)
Le service est exposé via un NodePort sur le port UDP 30060.

Configuration du Softphone (Client SIP)
Configurez deux softphones (un sur votre PC, un sur votre mobile par exemple) avec les identifiants suivants :
Paramètre,Utilisateur A,Utilisateur B
IP du Serveur,localhost ou IP du Node K8s,localhost ou IP du Node K8s
Port,30060 (UDP),30060 (UDP)
Username,1001,1002
Password,password1001,password1002

Faire un appel
Depuis l'utilisateur 1001, composez le 1002.

📂 Structure des Fichiers

.
├── generate_ppt.py      # Script de génération du PowerPoint
├── install.sh           # Script d'initialisation du projet
├── README.md            # Ce fichier
└── kubevox/
    ├── Dockerfile       # Recette de l'image Docker
    ├── configs/
    │   ├── extensions.conf  # Plan de numérotation (Dialplan)
    │   └── sip.conf         # Comptes utilisateurs SIP
    └── k8s/
        ├── configmap.yaml   # Injection des configs
        └── deployment.yaml  # Définition du Pod et du Service

⚠️ Notes Techniques & Troubleshooting
- Audio (RTP) : Ce projet de démo expose une plage RTP réduite. Dans un environnement de production réel, la gestion du NAT et des ports RTP (10000-20000) dans Kubernetes nécessite souvent l'utilisation de HostNetwork: true ou d'un SBC (Session Border Controller) comme Kamailio en frontal.

- Persistance : Les logs et les enregistrements d'appels (voicemail) sont éphémères dans ce conteneur. Pour les garder, il faudrait ajouter un PersistentVolume.
