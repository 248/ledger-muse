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

assert_contains() {
  local file="$1"
  local pattern="$2"
  if [[ ! -f "$file" ]] || ! grep -qE "$pattern" "$file"; then
    echo "missing pattern in $file: $pattern"
    fail=1
  fi
}

staging_dir="terraform/environments/staging"

assert_file "$staging_dir/main.tf"
assert_file "$staging_dir/backend.tf"
assert_file "$staging_dir/provider.tf"
assert_file "$staging_dir/variables.tf"

assert_contains "$staging_dir/backend.tf" 'bucket[[:space:]]*=[[:space:]]*"ledger-muse-terraform-state"'
assert_contains "$staging_dir/backend.tf" 'prefix[[:space:]]*=[[:space:]]*"environments/staging"'

assert_contains "$staging_dir/provider.tf" 'provider[[:space:]]+"google"'
assert_contains "$staging_dir/provider.tf" 'required_version'

assert_contains "$staging_dir/main.tf" 'module[[:space:]]+"artifact_registry"'
assert_contains "$staging_dir/main.tf" '\.\.\/\.\.\/modules\/artifact-registry'
assert_contains "$staging_dir/main.tf" 'repository_id[[:space:]]*=\s*var\.artifact_registry_repository_id'

assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"project_id"'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"artifact_registry_repository_id"'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"artifact_registry_description"'

if [[ $fail -eq 0 ]]; then
  echo "✅ terraform environments tests passed"
else
  echo "❌ terraform environments tests failed"
fi

exit $fail
