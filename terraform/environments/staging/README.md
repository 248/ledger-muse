# Staging Environment

Staging 環境用の Terraform root モジュールを配置します。`backend.tf`/`provider.tf`/`variables.tf` は `terraform/` 直下の共通定義をコピーして利用し、`main.tf` で必要なモジュール（Artifact Registry / Backend API Service Account / Cloud Run）を呼び出します。
