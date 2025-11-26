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

module_dir="terraform/modules/identity-platform"
assert_file "$module_dir/main.tf"
assert_file "$module_dir/variables.tf"
assert_file "$module_dir/outputs.tf"

assert_contains "$module_dir/main.tf" 'google_identity_platform_config'
assert_contains "$module_dir/main.tf" 'google_project_service'
assert_contains "$module_dir/variables.tf" 'variable[[:space:]]+"project_id"'
assert_contains "$module_dir/variables.tf" 'variable[[:space:]]+"authorized_domains"'
assert_contains "$module_dir/outputs.tf" 'authorized_domains'

staging_dir="terraform/environments/staging"
assert_contains "$staging_dir/main.tf" 'module[[:space:]]+"identity_platform"'
assert_contains "$staging_dir/main.tf" '\.\.\/\.\.\/modules\/identity-platform'
assert_contains "$staging_dir/main.tf" 'authorized_domains[[:space:]]*=[[:space:]]*var\.identity_platform_authorized_domains'

assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"identity_platform_authorized_domains"'

# Check actual domain values in .tfvars file (not in variables.tf which only has variable definition)
assert_file "$staging_dir/identity-platform.auto.tfvars"
assert_contains "$staging_dir/identity-platform.auto.tfvars" 'preview--ledger-muse\.asia-east1\.hosted\.app'
assert_contains "$staging_dir/identity-platform.auto.tfvars" 'production--ledger-muse\.asia-east1\.hosted\.app'

assert_contains "$staging_dir/outputs.tf" 'identity_platform_authorized_domains'
assert_contains "$staging_dir/outputs.tf" 'module\.identity_platform\.authorized_domains'

if [[ $fail -eq 0 ]]; then
  echo "✅ terraform identity platform tests passed"
else
  echo "❌ terraform identity platform tests failed"
fi

exit $fail
