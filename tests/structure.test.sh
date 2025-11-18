#!/usr/bin/env bash
set -euo pipefail

fail=0

assert_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    echo "missing dir: $path"
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

assert_dir "frontend"
assert_dir "backend"
assert_dir "terraform"

assert_contains ".gitignore" "node_modules"
assert_contains ".gitignore" "\\.next"
assert_contains ".gitignore" "\\.terraform/"
assert_contains ".gitignore" "terraform\\.tfstate"
assert_contains ".gitignore" "\\.air\\.toml"
assert_contains ".gitignore" "\\.DS_Store"

assert_contains "README.md" "モノレポ"
assert_contains "README.md" "frontend"
assert_contains "README.md" "backend"
assert_contains "README.md" "terraform"

exit $fail
