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

assert_file "docker-compose.yml"
assert_file "backend/Dockerfile.dev"
assert_file "backend/.air.toml"

# docker-compose.yml checks
assert_grep "^services:" docker-compose.yml
assert_grep "^  backend:" docker-compose.yml
assert_grep "context: ./backend" docker-compose.yml
assert_grep "dockerfile: Dockerfile.dev" docker-compose.yml
assert_grep "8080:8080" docker-compose.yml

assert_grep "^  firebase-emulators:" docker-compose.yml
assert_grep "9099:9099" docker-compose.yml
assert_grep "9000:8080" docker-compose.yml
assert_grep "9199:9199" docker-compose.yml
assert_grep "8085:8085" docker-compose.yml
assert_grep "4000:4000" docker-compose.yml

# Dockerfile.dev checks
assert_grep "^FROM golang:1\\.23" backend/Dockerfile.dev
assert_grep "air-verse/air@v1.61.1" backend/Dockerfile.dev
assert_grep "WORKDIR /app" backend/Dockerfile.dev
assert_grep "CMD \\[\"air\", \"-c\", \".air.toml\"\\]" backend/Dockerfile.dev

# .air.toml checks
assert_grep "^cmd = \"go build -o ./tmp/main ./cmd/api\"" backend/.air.toml
assert_grep "^bin = \"./tmp/main\"" backend/.air.toml

exit $fail
