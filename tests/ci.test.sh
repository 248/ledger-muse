#!/usr/bin/env bash
set -euo pipefail

fail=0
workflow=".github/workflows/ci.yml"
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

echo "Testing CI/CD Pipeline workflow..."

# Workflow name and triggers
assert_contains "$workflow" "^name: CI/CD Pipeline"
assert_contains "$workflow" "pull_request:"
assert_contains "$workflow" "branches:\\s*\\[main, develop\\]"
assert_contains "$workflow" "^\\s*push:"
assert_contains "$workflow" "branches:\\s*\\[main, develop\\]"

# Concurrency control
assert_contains "$workflow" "concurrency:"
assert_contains "$workflow" "group:"
assert_contains "$workflow" "cancel-in-progress: true"

# Changes detection job
assert_contains "$workflow" "changes:"
assert_contains "$workflow" "dorny/paths-filter@v3"
assert_contains "$workflow" "frontend:"
assert_contains "$workflow" "backend:"

# Frontend quality job
assert_contains "$workflow" "frontend-quality:"
assert_contains "$workflow" "needs: changes"
assert_contains "$workflow" "needs.changes.outputs.frontend == 'true'"
assert_contains "$workflow" "working-directory: ./frontend"
assert_contains "$workflow" "actions/setup-node@v4"
assert_contains "$workflow" "node-version: ['\"]?20['\"]?"
assert_contains "$workflow" "npm run lint"
assert_contains "$workflow" "npm run type-check"
assert_contains "$workflow" "npm run test"
assert_contains "$workflow" "npm run build"

# Backend quality job
assert_contains "$workflow" "backend-quality:"
assert_contains "$workflow" "needs.changes.outputs.backend == 'true'"
assert_contains "$workflow" "working-directory: ./backend"
assert_contains "$workflow" "actions/setup-go@v5"
assert_contains "$workflow" "go-version: ['\"]?1\\.23['\"]?"
assert_contains "$workflow" "golangci-lint-action@v4"
assert_contains "$workflow" "go test .*./\\.\\.\\."
assert_contains "$workflow" "go build -v ./\\.\\.\\."

# Backend deploy job
assert_contains "$workflow" "deploy-backend:"
assert_contains "$workflow" "Deploy Backend to Cloud Run"
assert_contains "$workflow" "needs: \\[changes, backend-quality\\]"
assert_contains "$workflow" "github.event_name == 'pull_request'"
assert_contains "$workflow" "google-github-actions/auth@v2"
assert_contains "$workflow" "google-github-actions/setup-gcloud@v2"
assert_contains "$workflow" "gcloud auth configure-docker"
assert_contains "$workflow" "docker build"
assert_contains "$workflow" "gcloud run deploy"
assert_contains "$workflow" "create-or-update-comment@v4"
assert_contains "$workflow" "/health"

# Note: Frontend deployment is handled by Firebase App Hosting GitHub integration
# No deploy-frontend job in CI pipeline

# Note: Backend deployment will be implemented in Phase 0 Task 4
# after Terraform infrastructure is set up

# Firebase configuration
assert_contains "$firebase_config" '"hosting"'
assert_contains "$firebase_config" '"source"[[:space:]]*:[[:space:]]*"frontend"'
assert_contains "$firebase_config" '"ignore"'

if [ $fail -eq 0 ]; then
  echo "✅ All CI/CD Pipeline tests passed"
else
  echo "❌ CI/CD Pipeline tests failed"
fi

exit $fail
