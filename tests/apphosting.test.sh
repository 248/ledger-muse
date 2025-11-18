#!/usr/bin/env bash
set -euo pipefail

fail=0
workflow=".github/workflows/app-hosting.yml"
firebase_config="firebase.json"

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
assert_file "$firebase_config"

# firebase.json hosting block
assert_contains "$firebase_config" '"hosting"'
assert_contains "$firebase_config" '"source"[[:space:]]*:[[:space:]]*"frontend"'
assert_contains "$firebase_config" '"ignore"'

# Workflow triggers
assert_contains "$workflow" "^name: Firebase App Hosting"
assert_contains "$workflow" "pull_request:"
assert_contains "$workflow" "branches:\\s*\\[main, develop\\]"
assert_contains "$workflow" "^  push:"
assert_contains "$workflow" "branches:\\s*\\[main, develop\\]"

# Workflow steps
assert_contains "$workflow" "actions/setup-node@v4"
assert_contains "$workflow" "node-version: ['\"]?20['\"]?"
assert_contains "$workflow" "working-directory: ./frontend"
assert_contains "$workflow" "npm ci"
assert_contains "$workflow" "npm run build"
assert_contains "$workflow" "firebase apphosting:sites:deploy"

exit $fail
