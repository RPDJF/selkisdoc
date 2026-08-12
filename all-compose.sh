#!/bin/bash

# Définir le chemin de base
path="/home/docker/infrastructure"

# Définir les fichiers de composition Docker
compose_files=(
  "compose-vaultwarden.yml"
  "compose-watchtower.yml"
  "compose-goofyn.yml"
)

# Arguments à passer à la commande docker compose
args="$@"

# Boucle sur chaque fichier de composition et exécute la commande avec les arguments
for file in "${compose_files[@]}"; do
  docker compose -f "$path/$file" $args
done

