#!/usr/bin/env bash
set -euo pipefail

fail=0
workflow=".github/workflows/quality-gate.yml"

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
  if ! grep -qE "$pattern" "$file"; then
    echo "missing pattern in $file: $pattern"
    fail=1
  fi
}

assert_file "$workflow"

# Triggers
assert_contains "$workflow" "^name: Quality Gate"
assert_contains "$workflow" "pull_request:"
assert_contains "$workflow" "branches:\\s*\\[main, develop\\]"
assert_contains "$workflow" "^  push:"
assert_contains "$workflow" "branches:\\s*\\[main, develop\\]"

# Frontend job
assert_contains "$workflow" "frontend-quality:"
assert_contains "$workflow" "working-directory: ./frontend"
assert_contains "$workflow" "actions/setup-node@v4"
assert_contains "$workflow" "node-version: ['\"]?20['\"]?"
assert_contains "$workflow" "npm run lint"
assert_contains "$workflow" "npm run type-check"
assert_contains "$workflow" "npm run test"
assert_contains "$workflow" "npm run build"

# Backend job
assert_contains "$workflow" "backend-quality:"
assert_contains "$workflow" "working-directory: ./backend"
assert_contains "$workflow" "actions/setup-go@v5"
assert_contains "$workflow" "go-version: ['\"]?1\\.23['\"]?"
assert_contains "$workflow" "golangci-lint-action@v4"
assert_contains "$workflow" "go test .*./\\.\\.\\."
assert_contains "$workflow" "go build -v ./\\.\\.\\."

exit $fail
