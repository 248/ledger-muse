# Secret Manager Module

This Terraform module creates and manages Google Cloud Secret Manager secrets with IAM access control.

## Features

- Creates a secret in Google Cloud Secret Manager
- Stores secret data in a versioned manner
- Grants IAM access to specified service accounts
- Supports custom labels for organization

## Usage

```hcl
module "backend_api_url_secret" {
  source = "../../modules/secret-manager"

  project_id       = var.project_id
  secret_id        = "BACKEND_API_BASE_STAGING"
  secret_data      = "https://api-staging.example.com"
  accessor_members = [
    "serviceAccount:app-hosting-sa@project.iam.gserviceaccount.com"
  ]

  labels = {
    environment = "staging"
    purpose     = "app-hosting-config"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | GCP project ID where the secret will be created | string | - | yes |
| secret_id | Unique identifier for the secret | string | - | yes |
| secret_data | The actual secret data to store (sensitive) | string | - | yes |
| accessor_members | List of members that can access this secret | list(string) | [] | no |
| labels | Labels to attach to the secret | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_name | Full resource name of the secret |
| secret_id | Secret ID |
| secret_version | Latest version of the secret |

## IAM Permissions

The module grants `roles/secretmanager.secretAccessor` to all members listed in `accessor_members`.

## Secret Replication

Secrets are automatically replicated across all GCP regions using the `auto` replication policy.
