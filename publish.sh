#!/usr/bin/env bash
# Publishes the current commit on main and confirms it reached the live site.
#
# Usage: commit your change on main, then run ./publish.sh
#
# Vercel normally deploys on its own when main is pushed. This script waits for
# that. It runs one manual deploy only if GitHub never triggered Vercel, and it
# never starts a second deploy, because the free plan builds one at a time and
# extra deploys just queue behind a slow one.

set -u

SITE="https://bentley-climbing-club.vercel.app"
API="https://api.github.com/repos/ethanbiancardi-prog/bentley-climbing-club"
TRIGGER_WAIT=120    # seconds for Vercel to pick up the push
LIVE_WAIT=1200      # seconds for a started deploy to go live
POLL=20

[ "$(git branch --show-current)" = "main" ] || { echo "Switch to main first."; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "Commit your changes first."; exit 1; }

sha=$(git rev-parse HEAD)
short=${sha:0:7}

# GitHub has rejected a good push before, then accepted the same one on retry.
if ! git push -q origin main; then
  echo "Push failed, retrying once."
  git push -q origin main || { echo "Push failed twice. Nothing was published."; exit 1; }
fi
echo "Pushed $short to GitHub."

live_matches() {
  [ "$(curl -s -m 15 "$SITE/?check=$RANDOM" | tr -d '\r' | sha1sum)" = \
    "$(git show HEAD:index.html | tr -d '\r' | sha1sum)" ]
}

# Prints the Vercel status for this commit: success, pending, failure, or none.
vercel_state() {
  curl -s -m 15 "$API/commits/$sha/status" | node -e '
    let s = "";
    process.stdin.on("data", d => s += d).on("end", () => {
      try {
        const v = (JSON.parse(s).statuses || []).find(x => /vercel/i.test(x.context));
        console.log(v ? v.state : "none");
      } catch { console.log("none"); }
    });'
}

wait_for_live() {
  local waited=0
  while [ "$waited" -lt "$LIVE_WAIT" ]; do
    if live_matches; then
      [ "$(vercel_state)" = "failure" ] || return 0
    fi
    sleep "$POLL"
    waited=$((waited + POLL))
  done
  return 1
}

waited=0
state=none
while [ "$waited" -lt "$TRIGGER_WAIT" ]; do
  state=$(vercel_state)
  [ "$state" != "none" ] && break
  sleep "$POLL"
  waited=$((waited + POLL))
done

case "$state" in
  failure|error)
    echo "Vercel's build failed for $short. Check the Vercel dashboard. Not retrying."
    exit 1
    ;;
  none)
    echo "GitHub never triggered Vercel. Running one manual deploy."
    npx --yes vercel@latest deploy --prod --yes < /dev/null > /dev/null 2>&1 &
    ;;
  *)
    echo "Vercel picked it up automatically."
    ;;
esac

if wait_for_live; then
  echo "Live: $SITE is showing $short."
else
  echo "$short is not live after $((LIVE_WAIT / 60)) minutes. Check the Vercel dashboard before deploying again."
  exit 1
fi
