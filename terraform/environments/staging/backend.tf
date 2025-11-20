terraform {
  backend "gcs" {
    # bucket は terraform init 時に -backend-config で指定します
    # 例: terraform init -backend-config="bucket=${PROJECT_ID}-terraform-state"
    prefix = "environments/staging"
  }
}
