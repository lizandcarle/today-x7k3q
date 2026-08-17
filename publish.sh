#!/bin/bash
# Orson: run this after editing todos.json. Pushes and verifies the build.
set -e
cd "$(dirname "$0")"

# ── 2026-08-17: when a build does not confirm, say WHY. ───────────────────────
# A stuck Pages build and a GitHub-wide outage produce an identical warning here.
# On 17 Aug two builds sat in "building" for three hours during a Partial System
# Outage and the script just shrugged. Check the status page before blaming the repo.
check_github_status() {
    DESC=$(curl -s --max-time 10 https://www.githubstatus.com/api/v2/status.json 2>/dev/null \
           | python3 -c "import sys,json;print(json.load(sys.stdin)['status']['description'])" 2>/dev/null)
    [ -n "$DESC" ] && echo "publish: GitHub status says: $DESC"
    [ "$DESC" != "All Systems Operational" ] && echo "publish: ⚠️  Not our repo. Wait it out; the commit is already pushed."
}


# ── DATE GUARD (added 2026-08-16) ─────────────────────────────────────────────
# The date field is NOT cosmetic. index.html renders it as the page headline AND
# keys tick-state off it (lsKey = 'orsonTodo:' + data.date). On 16 Aug it was left
# at the 15th, so the page announced itself as Saturday's list all day and mef
# reported "I don't see a Sunday version". Refuse to publish a stale date.
JSON_DATE=$(python3 -c "import json;print(json.load(open('todos.json'))['date'])")
TODAY=$(TZ=America/Guatemala date '+%Y-%m-%d')
if [ "$JSON_DATE" != "$TODAY" ]; then
    echo "publish: 🔴 REFUSING. todos.json date is $JSON_DATE but today is $TODAY (Guatemala)."
    echo "publish:    Fix the date field, then publish again."
    exit 1
fi
echo "publish: date OK ($JSON_DATE)"

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
check_github_status
