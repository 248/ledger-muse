#!/usr/bin/env bash
set -euo pipefail

fail=0
bootstrap_dir="terraform/bootstrap"

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

assert_file "${bootstrap_dir}/main.tf"
assert_file "${bootstrap_dir}/variables.tf"

main_tf="${bootstrap_dir}/main.tf"
vars_tf="${bootstrap_dir}/variables.tf"

# Bucket definition
assert_contains "$main_tf" 'resource "google_storage_bucket" "state"'
assert_contains "$main_tf" 'terraform-state'
assert_contains "$main_tf" 'versioning'
assert_contains "$main_tf" 'enabled[[:space:]]*=[[:space:]]*true'
assert_contains "$main_tf" 'uniform_bucket_level_access[[:space:]]*=[[:space:]]*true'
assert_contains "$main_tf" 'public_access_prevention[[:space:]]*=[[:space:]]*"enforced"'
assert_contains "$main_tf" 'prevent_destroy[[:space:]]*=[[:space:]]*true'

# IAM binding for state admins (roles/storage.objectAdmin)
assert_contains "$main_tf" 'google_storage_bucket_iam_member" "state_admin'
assert_contains "$main_tf" 'role[[:space:]]*=[[:space:]]*"roles/storage.objectAdmin"'

# Variables
assert_contains "$vars_tf" 'variable "project_id"'
assert_contains "$vars_tf" 'variable "location"'
assert_contains "$vars_tf" 'variable "state_admin_members"'

if [[ $fail -eq 0 ]]; then
  echo "✅ terraform bootstrap tests passed"
else
  echo "❌ terraform bootstrap tests failed"
fi

exit $fail
