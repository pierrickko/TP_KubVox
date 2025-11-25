# Image de base légère (Alpine Linux)
FROM alpine:3.18

# Métadonnées
LABEL maintainer="Expert Infra Cloud <votre.email@example.com>"
LABEL description="Conteneur Asterisk pour le projet KubVox"

# Installation d'Asterisk et des dépendances nécessaires
# asterisk-sample-config : utile pour avoir les fichiers de base si nécessaire (mais on va les écraser)
# asterisk-sounds-en : sons de base
RUN apk add --no-cache \
    asterisk \
    asterisk-sample-config \
    asterisk-sounds-en \
    asterisk-speex \
    asterisk-srtp \
    sox

# Création des dossiers nécessaires s'ils n'existent pas (par précaution)
RUN mkdir -p /etc/asterisk /var/spool/asterisk /var/lib/asterisk /var/log/asterisk

# Nettoyage des fichiers de conf par défaut pour éviter les conflits avec nos ConfigMaps
# On garde asterisk.conf par sécurité si on ne le monte pas, mais ici nous le fournissons.
RUN rm -rf /etc/asterisk/*

# Exposition des ports
# 5060: Signalisation SIP (UDP/TCP)
# 10000-10050: Plage RTP pour l'audio (réduite pour l'exemple, à adapter selon rtp.conf)
EXPOSE 5060/udp 5060/tcp
EXPOSE 10000-10050/udp

# Démarrage d'Asterisk au premier plan (-f) et très verbeux (-vvv) pour le debug logs docker
ENTRYPOINT ["/usr/sbin/asterisk", "-f", "-vvv"]
