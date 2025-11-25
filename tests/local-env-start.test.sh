#!/usr/bin/env bash
set -euo pipefail

fail=0

assert_grep() {
  local pattern="$1"
  local file="$2"
  if ! grep -qE "$pattern" "$file"; then
    echo "missing pattern in $file: $pattern"
    fail=1
  fi
}

# Colima start guidance
assert_grep "colima start" README.md

# Docker Compose startup (v2-compatible syntax)
assert_grep "docker compose up -d" README.md

# Frontend dev server
assert_grep "npm run dev" README.md

# Health endpoints
assert_grep "http://localhost:8080/health" README.md
assert_grep "http://localhost:4000" README.md

exit $fail
