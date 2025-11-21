#!/usr/bin/env bash
set -euo pipefail

fail=0

assert_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "missing file: $path"
    fail=1
  fi
}

assert_grep() {
  local pattern="$1"
  local file="$2"
  if ! grep -qE "$pattern" "$file"; then
    echo "missing pattern in $file: $pattern"
    fail=1
  fi
}

# Frontend env template
assert_file "frontend/.env.local.example"
assert_grep "^NEXT_PUBLIC_BACKEND_API_BASE=http://localhost:8080" frontend/.env.local.example
assert_grep "^NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST=localhost:9000" frontend/.env.local.example
assert_grep "^NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST=http://localhost:9099" frontend/.env.local.example

# Backend env template
assert_file "backend/.env.example"
assert_grep "^FIREBASE_PROJECT_ID=demo-no-project" backend/.env.example
assert_grep "^FIRESTORE_EMULATOR_HOST=firebase-emulators:8080" backend/.env.example
assert_grep "^FIREBASE_AUTH_EMULATOR_HOST=firebase-emulators:9099" backend/.env.example

# README documentation
assert_grep "^## 環境変数" README.md
assert_grep "frontend/.env.local.example" README.md
assert_grep "backend/.env.example" README.md

exit $fail
