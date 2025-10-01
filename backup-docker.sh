#!/bin/bash
# please use this script as a root user
datef=$(date +"%Y%m%d_%H%M")
dest="/home/docker/backups/docker_backup_$datef.tar"

# Create tarball with /data and /home/docker/infrastructure
tar -cf "$dest" -C / data/containers -C /home/docker infrastructure
chmod o-rx $dest
chown docker:docker $dest

echo "Backup completed successfully. Archive created at: $dest"

echo "Cleaning old backups"

exec /home/docker/infrastructure/backup-rotation.sh
