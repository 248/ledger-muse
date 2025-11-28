# Secret Manager Module

This Terraform module creates and manages Google Cloud Secret Manager secrets with version control.

## Features

- Creates a secret in Google Cloud Secret Manager
- Stores secret data in a versioned manner
- Supports custom labels for organization
- Supports optional IAM access control (though for Firebase App Hosting, use Firebase CLI instead)

## Usage

### Basic Usage (Firebase App Hosting)

For Firebase App Hosting secrets, IAM permissions should be managed by Firebase CLI:

```hcl
module "backend_api_url_secret" {
  source = "../../modules/secret-manager"

  project_id  = var.project_id
  secret_id   = "BACKEND_API_BASE_STAGING"
  secret_data = "https://api-staging.example.com"

  labels = {
    environment = "staging"
    purpose     = "app-hosting-config"
  }
}
```

After applying, grant IAM permissions with Firebase CLI:
```bash
firebase apphosting:secrets:grantaccess BACKEND_API_BASE_STAGING \
  --backend staging \
  --location asia-east1 \
  --project <PROJECT_ID>
```

### Advanced Usage (Custom IAM Management)

If you need to manage IAM permissions via Terraform (not recommended for Firebase App Hosting):

```hcl
module "custom_secret" {
  source = "../../modules/secret-manager"

  project_id       = var.project_id
  secret_id        = "CUSTOM_SECRET"
  secret_data      = "secret-value"
  accessor_members = [
    "serviceAccount:custom-sa@project.iam.gserviceaccount.com"
  ]

  labels = {
    environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | GCP project ID where the secret will be created | string | - | yes |
| secret_id | Unique identifier for the secret | string | - | yes |
| secret_data | The actual secret data to store (sensitive) | string | - | yes |
| accessor_members | List of members that can access this secret. For Firebase App Hosting, leave empty and use Firebase CLI instead | list(string) | [] | no |
| labels | Labels to attach to the secret | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_name | Full resource name of the secret |
| secret_id | Secret ID |
| secret_version | Latest version of the secret |

## IAM Permissions

When `accessor_members` is provided, the module grants `roles/secretmanager.secretAccessor` to all listed members.

**For Firebase App Hosting**: Leave `accessor_members` empty and use the Firebase CLI command instead, which sets up the correct combination of permissions:
- `roles/secretmanager.secretAccessor`
- `roles/secretmanager.viewer`
- `roles/secretmanager.secretVersionManager`

## Secret Replication

Secrets are automatically replicated across all GCP regions using the `auto` replication policy.

## Related Documentation

- [Secret Manager Setup Guide](../../../docs/terraform/secret-manager.md) - Full setup guide for Firebase App Hosting
- [Terraform Main Guide](../../../docs/terraform/README.md) - Overall Terraform workflow
