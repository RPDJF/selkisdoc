#!/bin/bash

# Target directory (default: current)
DIR="/data/backups"

# Safety check: avoid deleting everything
cd "$DIR" || exit 1
TOTAL=$(ls -1t | wc -l)

if [ "$TOTAL" -le 7 ]; then
  echo "Only $TOTAL files found. Nothing to delete."
  exit 0
fi

# Get files to delete (everything except the 7 most recent)
FILES_TO_DELETE=$(ls -1t | tail -n +8)

# Delete them
for file in $FILES_TO_DELETE; do
  echo "Deleting: $file"
  rm -rf -- "$file"
done

