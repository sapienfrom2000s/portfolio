#!/bin/bash

cd /Users/thirtyone/repos/notes || exit

while true
do
  git add .

  # Commit only if there are changes
  if ! git diff --cached --quiet; then
    git commit -m "Auto commit: $(date '+%Y-%m-%d %H:%M:%S')"
    git push
  else
    echo "No changes to commit"
  fi

  # Sleep for 6 hours (21600 seconds)
  sleep 21600
done
