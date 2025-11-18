#!/usr/bin/env bash
set -euo pipefail

fail=0
base="backend"

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

assert_file "$base/go.mod"
assert_contains "$base/go.mod" "^module "
assert_contains "$base/go.mod" "github.com/labstack/echo/v4"

assert_file "$base/.golangci.yml"
assert_contains "$base/.golangci.yml" "linters:"

assert_file "$base/cmd/api/main.go"
assert_contains "$base/cmd/api/main.go" "echo.New"
assert_contains "$base/cmd/api/main.go" "/health"

assert_file "$base/internal/domain/health/status.go"
assert_file "$base/internal/application/health/service.go"
assert_file "$base/internal/adapter/http/health_handler.go"
assert_file "$base/internal/port/http/router.go"
assert_file "$base/pkg/version/version.go"

exit $fail
