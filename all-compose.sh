#!/bin/bash

# Définir le chemin de base
path="/home/docker/infrastructure"

# Définir les fichiers de composition Docker
compose_files=(
  "compose-traefik.yml"
  "compose-vaultwarden.yml"
  "compose-watchtower.yml"
#  "compose-website.yml" now handled by github pages
  "compose-fv23.yml"
  "compose-discord-ruisbot.yml"
  "compose-kuma.yml"
  "compose-goofyn.yml"
  "compose-mcserver.yml"
  "compose-gitea.yml"
)

# Arguments à passer à la commande docker compose
args="$@"

# Boucle sur chaque fichier de composition et exécute la commande avec les arguments
for file in "${compose_files[@]}"; do
  docker compose -f "$path/$file" $args
done

