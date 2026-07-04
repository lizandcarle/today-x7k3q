#!/bin/bash
# Orson: run this after editing todos.json. Nothing else to remember.
set -e
cd "$(dirname "$0")"
git pull --rebase --quiet || true
git add todos.json
git commit -m "todos: $(date '+%Y-%m-%d %H:%M')" || echo "Nothing new to publish."
git push
echo "Published. GitHub Pages usually goes live within a minute."
