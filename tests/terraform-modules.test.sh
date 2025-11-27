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
  if [[ ! -f "$file" ]] || ! grep -qE "$pattern" "$file"; then
    echo "missing pattern in $file: $pattern"
    fail=1
  fi
}

modules_root="terraform/modules"

assert_dir "$modules_root"

# Artifact Registry module expectations
artifact_dir="$modules_root/artifact-registry"
assert_dir "$artifact_dir"
assert_file "$artifact_dir/main.tf"
assert_file "$artifact_dir/variables.tf"
assert_file "$artifact_dir/outputs.tf"
assert_contains "$artifact_dir/main.tf" 'resource[[:space:]]+"google_artifact_registry_repository"'
assert_contains "$artifact_dir/main.tf" 'format[[:space:]]*=[[:space:]]*"DOCKER"'
assert_contains "$artifact_dir/variables.tf" 'variable[[:space:]]+"project_id"'
assert_contains "$artifact_dir/variables.tf" 'variable[[:space:]]+"repository_id"'
assert_contains "$artifact_dir/variables.tf" 'variable[[:space:]]+"region"'
assert_contains "$artifact_dir/outputs.tf" 'output[[:space:]]+"repository_url"'

# IAM module expectations
iam_dir="$modules_root/iam"
assert_dir "$iam_dir"
assert_file "$iam_dir/main.tf"
assert_file "$iam_dir/variables.tf"
assert_file "$iam_dir/outputs.tf"
assert_contains "$iam_dir/main.tf" 'resource[[:space:]]+"google_service_account"'
assert_contains "$iam_dir/main.tf" 'google_project_iam_member'
assert_contains "$iam_dir/variables.tf" 'variable[[:space:]]+"service_account_roles"'
assert_contains "$iam_dir/outputs.tf" 'output[[:space:]]+"service_account_email"'

# Cloud Run module expectations
cloud_run_dir="$modules_root/cloud-run"
assert_dir "$cloud_run_dir"
assert_file "$cloud_run_dir/main.tf"
assert_file "$cloud_run_dir/variables.tf"
assert_file "$cloud_run_dir/outputs.tf"
assert_contains "$cloud_run_dir/main.tf" 'resource[[:space:]]+"google_cloud_run_service"'
assert_contains "$cloud_run_dir/main.tf" 'service_account_name'
assert_contains "$cloud_run_dir/main.tf" 'traffic'
assert_contains "$cloud_run_dir/variables.tf" 'variable[[:space:]]+"container_image"'
assert_contains "$cloud_run_dir/variables.tf" 'variable[[:space:]]+"environment"'
assert_contains "$cloud_run_dir/variables.tf" 'variable[[:space:]]+"min_instances"'
assert_contains "$cloud_run_dir/variables.tf" 'variable[[:space:]]+"max_instances"'
assert_contains "$cloud_run_dir/variables.tf" 'variable[[:space:]]+"memory"'
assert_contains "$cloud_run_dir/variables.tf" 'variable[[:space:]]+"cpu"'
assert_contains "$cloud_run_dir/outputs.tf" 'output[[:space:]]+"service_url"'

# Storage module expectations
storage_dir="$modules_root/storage"
assert_dir "$storage_dir"
assert_file "$storage_dir/main.tf"
assert_file "$storage_dir/variables.tf"
assert_file "$storage_dir/outputs.tf"
assert_contains "$storage_dir/main.tf" 'resource[[:space:]]+"google_storage_bucket"'
assert_contains "$storage_dir/main.tf" 'uniform_bucket_level_access[[:space:]]*=[[:space:]]*true'
assert_contains "$storage_dir/main.tf" 'lifecycle_rule'
assert_contains "$storage_dir/main.tf" 'encryption'
assert_contains "$storage_dir/variables.tf" 'variable[[:space:]]+"force_destroy"'
assert_contains "$storage_dir/variables.tf" 'variable[[:space:]]+"lifecycle_age_days"'
assert_contains "$storage_dir/variables.tf" 'variable[[:space:]]+"kms_key_name"'
assert_contains "$storage_dir/outputs.tf" 'output[[:space:]]+"bucket_url"'

# Secret Manager module expectations
secret_manager_dir="$modules_root/secret-manager"
assert_dir "$secret_manager_dir"
assert_file "$secret_manager_dir/main.tf"
assert_file "$secret_manager_dir/variables.tf"
assert_file "$secret_manager_dir/outputs.tf"
assert_contains "$secret_manager_dir/main.tf" 'resource[[:space:]]+"google_secret_manager_secret"'
assert_contains "$secret_manager_dir/main.tf" 'resource[[:space:]]+"google_secret_manager_secret_version"'
assert_contains "$secret_manager_dir/main.tf" 'resource[[:space:]]+"google_secret_manager_secret_iam_member"'
assert_contains "$secret_manager_dir/main.tf" 'roles/secretmanager.secretAccessor'
assert_contains "$secret_manager_dir/variables.tf" 'variable[[:space:]]+"secret_id"'
assert_contains "$secret_manager_dir/variables.tf" 'variable[[:space:]]+"secret_data"'
assert_contains "$secret_manager_dir/variables.tf" 'variable[[:space:]]+"accessor_members"'
assert_contains "$secret_manager_dir/outputs.tf" 'output[[:space:]]+"secret_name"'

if [[ $fail -eq 0 ]]; then
  echo "✅ terraform modules tests passed"
else
  echo "❌ terraform modules tests failed"
fi

exit $fail
