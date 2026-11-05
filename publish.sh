#!/usr/bin/env bash
# Publishes the current commit on main and confirms it reached the live site.
#
# Usage: commit your change on main, then run ./publish.sh
#
# This is the only way the site deploys. GitHub-triggered deploys are off in
# vercel.json because GitHub's notice to Vercel has arrived 25+ minutes late,
# and a late deploy of an old commit can replace a newer live version.
# Run one publish at a time: the free plan builds one deploy at a time, so a
# second deploy just queues behind the first.

set -u

SITE="https://bentley-climbing-club.vercel.app"
MAX_WAIT=1200   # seconds to allow for the deploy
POLL=10

[ "$(git branch --show-current)" = "main" ] || { echo "Switch to main first."; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "Commit your changes first."; exit 1; }

short=$(git rev-parse --short HEAD)

# GitHub has rejected a good push before, then accepted the same one on retry.
if ! git push -q origin main; then
  echo "Push failed, retrying once."
  git push -q origin main || { echo "Push failed twice. Nothing was published."; exit 1; }
fi
echo "Pushed $short to GitHub. Deploying."

npx --yes vercel@latest deploy --prod --yes < /dev/null > /dev/null 2>&1 &
deploy=$!

waited=0
while kill -0 "$deploy" 2> /dev/null; do
  if [ "$waited" -ge "$MAX_WAIT" ]; then
    echo "Deploy of $short is still running after $((MAX_WAIT / 60)) minutes."
    echo "Check the Vercel dashboard. Don't start another deploy on top of it."
    exit 1
  fi
  sleep "$POLL"
  waited=$((waited + POLL))
done

wait "$deploy" || { echo "Deploy of $short failed. Check the Vercel dashboard."; exit 1; }

live=$(curl -s -m 15 "$SITE/?check=$RANDOM" | tr -d '\r' | sha1sum)
local_page=$(git show HEAD:index.html | tr -d '\r' | sha1sum)
if [ "$live" = "$local_page" ]; then
  echo "Live: $SITE is showing $short."
else
  echo "Vercel finished, but the live page doesn't match $short. Check the Vercel dashboard."
  exit 1
fi
