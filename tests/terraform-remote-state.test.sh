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

backend_tf="terraform/backend.tf"
provider_tf="terraform/provider.tf"
wif_backend_tf="terraform/wif/backend.tf"

assert_file "$backend_tf"
assert_file "$provider_tf"
assert_file "$wif_backend_tf"

assert_contains "$backend_tf" 'backend "gcs"'
# bucket は -backend-config で指定するため、ハードコードチェックは削除
assert_contains "$backend_tf" 'prefix[[:space:]]*=[[:space:]]*"global"'

assert_contains "$provider_tf" 'required_version[[:space:]]*=[[:space:]]*">= 1.9.0, < 2.0.0"'
assert_contains "$provider_tf" 'provider "google"'

assert_contains "$wif_backend_tf" 'backend "gcs"'
# bucket は -backend-config で指定するため、ハードコードチェックは削除
assert_contains "$wif_backend_tf" 'prefix[[:space:]]*=[[:space:]]*"wif"'

assert_dir "terraform/environments"
assert_dir "terraform/environments/staging"
assert_dir "terraform/environments/prod"

if [[ $fail -eq 0 ]]; then
  echo "✅ terraform remote state tests passed"
else
  echo "❌ terraform remote state tests failed"
fi

exit $fail
