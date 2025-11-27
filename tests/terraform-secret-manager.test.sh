#!/usr/bin/env bash
# Test: Secret Manager module structure and configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Testing Secret Manager Module ==="

# Test 1: Secret Manager module exists
echo "Test: Secret Manager module directory exists"
if [[ ! -d "$PROJECT_ROOT/terraform/modules/secret-manager" ]]; then
  echo "FAIL: terraform/modules/secret-manager directory not found"
  exit 1
fi
echo "PASS"

# Test 2: Required module files exist
echo "Test: Secret Manager module files exist"
for file in main.tf variables.tf outputs.tf; do
  if [[ ! -f "$PROJECT_ROOT/terraform/modules/secret-manager/$file" ]]; then
    echo "FAIL: terraform/modules/secret-manager/$file not found"
    exit 1
  fi
done
echo "PASS"

# Test 3: Module defines google_secret_manager_secret resource
echo "Test: Module contains google_secret_manager_secret resource"
if ! grep -q "resource \"google_secret_manager_secret\"" "$PROJECT_ROOT/terraform/modules/secret-manager/main.tf"; then
  echo "FAIL: google_secret_manager_secret resource not found in main.tf"
  exit 1
fi
echo "PASS"

# Test 4: Module defines google_secret_manager_secret_version resource
echo "Test: Module contains google_secret_manager_secret_version resource"
if ! grep -q "resource \"google_secret_manager_secret_version\"" "$PROJECT_ROOT/terraform/modules/secret-manager/main.tf"; then
  echo "FAIL: google_secret_manager_secret_version resource not found in main.tf"
  exit 1
fi
echo "PASS"

# Test 5: Module defines google_secret_manager_secret_iam_member resource
echo "Test: Module contains google_secret_manager_secret_iam_member resource"
if ! grep -q "resource \"google_secret_manager_secret_iam_member\"" "$PROJECT_ROOT/terraform/modules/secret-manager/main.tf"; then
  echo "FAIL: google_secret_manager_secret_iam_member resource not found in main.tf"
  exit 1
fi
echo "PASS"

# Test 6: Module has required input variables
echo "Test: Module has required variables (project_id, secret_id, secret_data)"
for var in project_id secret_id secret_data; do
  if ! grep -q "variable \"$var\"" "$PROJECT_ROOT/terraform/modules/secret-manager/variables.tf"; then
    echo "FAIL: variable '$var' not found in variables.tf"
    exit 1
  fi
done
echo "PASS"

# Test 7: Module has output for secret name
echo "Test: Module outputs secret_name"
if ! grep -q "output \"secret_name\"" "$PROJECT_ROOT/terraform/modules/secret-manager/outputs.tf"; then
  echo "FAIL: output 'secret_name' not found in outputs.tf"
  exit 1
fi
echo "PASS"

# Test 8: Staging environment uses secret-manager module
echo "Test: Staging environment integrates secret-manager module"
if ! grep -q "module.*secret.*manager" "$PROJECT_ROOT/terraform/environments/staging/main.tf"; then
  echo "FAIL: secret-manager module not found in staging/main.tf"
  exit 1
fi
echo "PASS"

# Test 9: Staging variables include backend_api_url
echo "Test: Staging variables.tf includes backend_api_url"
if ! grep -q "variable \"backend_api_url\"" "$PROJECT_ROOT/terraform/environments/staging/variables.tf"; then
  echo "FAIL: variable 'backend_api_url' not found in staging/variables.tf"
  exit 1
fi
echo "PASS"

# Test 10: App Hosting YAML files exist
echo "Test: apphosting.yaml files exist"
if [[ ! -f "$PROJECT_ROOT/frontend/apphosting.yaml" ]]; then
  echo "FAIL: frontend/apphosting.yaml not found"
  exit 1
fi
if [[ ! -f "$PROJECT_ROOT/frontend/apphosting.staging.yaml" ]]; then
  echo "FAIL: frontend/apphosting.staging.yaml not found"
  exit 1
fi
echo "PASS"

# Test 11: apphosting.staging.yaml references secret
echo "Test: apphosting.staging.yaml references BACKEND_API_BASE_STAGING secret"
if ! grep -q "BACKEND_API_BASE_STAGING" "$PROJECT_ROOT/frontend/apphosting.staging.yaml"; then
  echo "FAIL: BACKEND_API_BASE_STAGING not found in apphosting.staging.yaml"
  exit 1
fi
echo "PASS"

echo ""
echo "=== All Secret Manager Module Tests Passed ==="
