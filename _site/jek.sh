#!/bin/bash

# bundle install
# bundle exec jekyll serve &
# sleep 3
# open -a Safari http://127.0.0.1:4000

set -euo pipefail

cd "$(dirname "$0")"

echo "Syncing Biology Skills content..."
python3 scripts/sync_skills.py

echo "Starting Jekyll..."
bundle exec jekyll serve &
JEKYLL_PID=$!

cleanup() {
  kill "$JEKYLL_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

sleep 3
open -a Safari http://127.0.0.1:4000

wait "$JEKYLL_PID"

