#!/bin/bash
# Orson: run this after editing todos.json. Pushes and verifies the build.
set -e
cd "$(dirname "$0")"
git pull --rebase --quiet || true
git add todos.json
git commit -m "todos: $(date '+%Y-%m-%d %H:%M')" || echo "Nothing new to publish."
git push

# Verify the build succeeds (wait up to 90 seconds)
echo "Verifying Pages build..."
for i in $(seq 1 6); do
  sleep 15
  STATUS=$(/opt/homebrew/bin/gh api repos/lizandcarle/today-x7k3q/pages/builds --jq '.[0].status' 2>/dev/null)
  if [ "$STATUS" = "built" ]; then
    echo "Published and verified."
    exit 0
  elif [ "$STATUS" = "errored" ]; then
    echo "Build failed. Retrying..."
    echo "<!-- retry $(date) -->" >> index.html
    git add -A && git commit -m "retry build" && git push
  fi
done
echo "WARNING: Build not confirmed after 90 seconds."
