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

assert_contains "$staging_dir/main.tf" 'module[[:space:]]+"backend_api_service_account"'
assert_contains "$staging_dir/main.tf" '\.\.\/\.\.\/modules\/iam'
assert_contains "$staging_dir/main.tf" 'service_account_id[[:space:]]*=\s*var\.backend_api_service_account_id'
assert_contains "$staging_dir/main.tf" 'service_account_roles[[:space:]]*=\s*var\.backend_api_service_account_roles'

assert_contains "$staging_dir/main.tf" 'module[[:space:]]+"backend_api_cloud_run"'
assert_contains "$staging_dir/main.tf" '\.\.\/\.\.\/modules\/cloud-run'
assert_contains "$staging_dir/main.tf" 'service_name[[:space:]]*=\s*var\.backend_api_cloud_run_service_name'
assert_contains "$staging_dir/main.tf" 'container_image[[:space:]]*=\s*var\.backend_api_cloud_run_container_image'
assert_contains "$staging_dir/main.tf" 'service_account_email[[:space:]]*=\s*module\.backend_api_service_account\.service_account_email'
assert_contains "$staging_dir/main.tf" 'environment[[:space:]]*=\s*var\.backend_api_cloud_run_environment'
assert_contains "$staging_dir/main.tf" 'min_instances[[:space:]]*=\s*var\.backend_api_cloud_run_min_instances'
assert_contains "$staging_dir/main.tf" 'max_instances[[:space:]]*=\s*var\.backend_api_cloud_run_max_instances'
assert_contains "$staging_dir/main.tf" 'memory[[:space:]]*=\s*var\.backend_api_cloud_run_memory'
assert_contains "$staging_dir/main.tf" 'cpu[[:space:]]*=\s*var\.backend_api_cloud_run_cpu'

assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"project_id"'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"artifact_registry_repository_id"'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"artifact_registry_description"'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"backend_api_service_account_id"'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"backend_api_service_account_display_name"'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"backend_api_service_account_roles"'
assert_contains "$staging_dir/variables.tf" 'roles/datastore\.user'
assert_contains "$staging_dir/variables.tf" 'roles/storage\.objectAdmin'
assert_contains "$staging_dir/variables.tf" 'roles/pubsub\.publisher'
assert_contains "$staging_dir/variables.tf" 'roles/serviceusage\.serviceUsageConsumer'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"backend_api_cloud_run_service_name"'
assert_contains "$staging_dir/variables.tf" 'ledger-muse-api-staging'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"backend_api_cloud_run_container_image"'
assert_contains "$staging_dir/variables.tf" 'gcr\.io/cloudrun/hello'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"backend_api_cloud_run_environment"'
assert_contains "$staging_dir/variables.tf" 'staging'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"backend_api_cloud_run_min_instances"'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"backend_api_cloud_run_max_instances"'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"backend_api_cloud_run_memory"'
assert_contains "$staging_dir/variables.tf" 'variable[[:space:]]+"backend_api_cloud_run_cpu"'

assert_contains "$staging_dir/outputs.tf" 'backend_api_service_account_email'
assert_contains "$staging_dir/outputs.tf" 'module\.backend_api_service_account\.service_account_email'
assert_contains "$staging_dir/outputs.tf" 'backend_api_cloud_run_service_url'
assert_contains "$staging_dir/outputs.tf" 'module\.backend_api_cloud_run\.service_url'

if [[ $fail -eq 0 ]]; then
  echo "✅ terraform environments tests passed"
else
  echo "❌ terraform environments tests failed"
fi

exit $fail
