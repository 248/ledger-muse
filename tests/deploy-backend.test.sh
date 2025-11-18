#!/usr/bin/env bash
set -euo pipefail

fail=0
workflow=".github/workflows/deploy-backend.yml"

assert_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "missing file: $path"
    fail=1
  fi
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  if ! grep -qE -- "$pattern" "$file"; then
    echo "missing pattern in $file: $pattern"
    fail=1
  fi
}

assert_file "$workflow"

# Triggers
assert_contains "$workflow" "^name: Deploy Backend to Cloud Run"
assert_contains "$workflow" "push:"
assert_contains "$workflow" "branches:"
assert_contains "$workflow" "- main"
assert_contains "$workflow" "- develop"
assert_contains "$workflow" "paths:"
assert_contains "$workflow" "backend/\\*\\*"
assert_contains "$workflow" ".github/workflows/deploy-backend.yml"

# Setup and auth
assert_contains "$workflow" "actions/checkout@v4"
assert_contains "$workflow" "actions/setup-go@v5"
assert_contains "$workflow" "go-version: ['\"]?1\\.23['\"]?"
assert_contains "$workflow" "google-github-actions/auth@v2"
assert_contains "$workflow" "google-github-actions/setup-gcloud@v2"

# Build & test
assert_contains "$workflow" "working-directory: ./backend"
assert_contains "$workflow" "go test .*./\\.\\.\\."
assert_contains "$workflow" "go build -v ./\\.\\.\\."

# Docker build/push
assert_contains "$workflow" "docker build"
assert_contains "$workflow" "docker push"
assert_contains "$workflow" "ledger-muse"
assert_contains "$workflow" "SERVICE_NAME"

# Cloud Run deploy
assert_contains "$workflow" "gcloud run deploy"
assert_contains "$workflow" "--region"
assert_contains "$workflow" "--allow-unauthenticated"

exit $fail
