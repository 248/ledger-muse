# インフラストラクチャ設計

本ドキュメントでは、Google Cloud Platform（GCP）上でのインフラストラクチャ構成と、Terraformによるインフラ構成管理（IaC）の戦略を定義します。

## インフラストラクチャ概要

### GCPサービス構成

| サービス | 用途 | 環境 |
|---------|------|------|
| **Cloud Run** | Backend APIホスティング | Staging, Production |
| **Artifact Registry** | Dockerイメージレジストリ | Staging, Production |
| **Firestore** | NoSQLデータベース | Staging, Production |
| **Cloud Storage** | レシート画像保存 | Staging, Production |
| **Cloud Vision API** | OCR処理 | Staging, Production |
| **Pub/Sub** | 非同期メッセージング | Staging, Production |
| **Cloud Tasks** | 非同期処理ワーカー | Staging, Production |
| **Identity Platform** | 認証基盤 | Staging, Production |
| **Cloud Monitoring** | メトリクス収集 | Staging, Production |
| **Cloud Logging** | ログ管理 | Staging, Production |
| **Cloud Trace** | 分散トレーシング | Staging, Production |
| **Cloud KMS** | 暗号鍵管理 | Staging, Production |

### リージョン設定

- **プライマリリージョン**: `asia-northeast1`（東京）
  - レイテンシ最小化（日本国内ユーザー想定）
  - フルサービス対応
  - Cloud Runのコールドスタート時間が短い

## 環境分離戦略

### 環境構成

| 環境 | 用途 | Terraform workspace | GCPプロジェクト |
|------|------|---------------------|----------------|
| **Local** | ローカル開発・デバッグ | - | エミュレーター使用（GCP不要） |
| **Staging** | 統合テスト・PR Preview | `staging` | 同一プロジェクト内（リソース名で分離） |
| **Production** | 本番環境 | `production` | 同一プロジェクト内（リソース名で分離） |

**注**: 学習段階ではコスト削減のため、StagingとProductionは同一GCPプロジェクト内で環境変数とリソース名（`-staging`、`-prod`サフィックス）により分離します。将来的には別プロジェクトへの分離も可能です。

### 環境別リソース設定

#### Cloud Run

| 環境 | サービス名 | インスタンス設定 | メモリ | CPU | 同時実行数 |
|------|-----------|----------------|--------|-----|-----------|
| Staging | `ledger-muse-api-staging` | min: 0, max: 3 | 512Mi | 1 | 80 |
| Production | `ledger-muse-api-prod` | min: 0, max: 10 | 512Mi | 1 | 80 |

#### Firestore

| 環境 | モード | ロケーション |
|------|-------|-------------|
| Staging | Native mode | `asia-northeast1` |
| Production | Native mode | `asia-northeast1` |

**注**: Firestoreは1プロジェクトにつき1インスタンスのため、コレクション名に環境プレフィックス（`staging_`, `prod_`）を付与して分離します。

#### Cloud Storage

| 環境 | バケット名 | ライフサイクル | 暗号化 |
|------|-----------|--------------|-------|
| Staging | `{project-id}-receipts-staging` | 90日後削除 | Google管理鍵 |
| Production | `{project-id}-receipts-prod` | 365日後削除 | Google管理鍵（将来的にKMS） |

## Terraform構成管理

### ディレクトリ構造

```
terraform/
├── environments/
│   ├── staging/
│   │   ├── main.tf          # Staging環境のメイン定義
│   │   ├── variables.tf     # Staging固有変数
│   │   ├── terraform.tfvars # Staging固有値
│   │   └── outputs.tf       # Staging出力
│   └── prod/
│       ├── main.tf          # Production環境のメイン定義
│       ├── variables.tf     # Production固有変数
│       ├── terraform.tfvars # Production固有値
│       └── outputs.tf       # Production出力
├── modules/
│   ├── cloud-run/           # Cloud Runモジュール
│   ├── firestore/           # Firestoreモジュール
│   ├── storage/             # Cloud Storageモジュール
│   ├── artifact-registry/   # Artifact Registryモジュール
│   ├── iam/                 # IAM（サービスアカウント、権限）モジュール
│   ├── pubsub/              # Pub/Subモジュール
│   ├── kms/                 # KMSモジュール
│   └── monitoring/          # Monitoring/Alertingモジュール
├── backend.tf               # リモートステート設定
├── provider.tf              # GCPプロバイダー設定
└── common.auto.tfvars       # 共通変数（project_id, regionなど）
```

### リモートステート管理

**バックエンド**: Cloud Storage

```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket  = "{project-id}-terraform-state"
    prefix  = "ledger-muse"
  }
}
```

**ステートファイル構成**:
- `ledger-muse/staging/default.tfstate` - Staging環境
- `ledger-muse/prod/default.tfstate` - Production環境

### Terraformモジュール設計

#### 1. Artifact Registryモジュール

```hcl
# modules/artifact-registry/main.tf
resource "google_artifact_registry_repository" "docker_repo" {
  repository_id = var.repository_id
  location      = var.region
  format        = "DOCKER"
  description   = "Docker image repository for Ledger Muse"
}
```

**用途**: CI/CDパイプラインでビルドしたDockerイメージの保存先

`modules/artifact-registry/variables.tf`:

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "repository_id" {
  description = "Artifact Registry repository ID"
  type        = string
}

variable "region" {
  description = "Region for Artifact Registry"
  type        = string
}

variable "description" {
  description = "Description of the repository"
  type        = string
  default     = "Docker repository for Ledger Muse"
}
```

`modules/artifact-registry/outputs.tf`:

```hcl
output "repository_id" {
  value       = google_artifact_registry_repository.docker_repo.repository_id
  description = "Artifact Registry repository ID"
}

output "repository_url" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}"
  description = "Full URL of the Artifact Registry repository"
}

output "repository_name" {
  value       = google_artifact_registry_repository.docker_repo.name
  description = "Full resource name of the Artifact Registry repository"
}
```

#### 2. Cloud Runモジュール

```hcl
# modules/cloud-run/main.tf
resource "google_cloud_run_service" "api" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      containers {
        image = var.container_image
        env {
          name  = "ENV"
          value = var.environment
        }
      }
      service_account_name = var.service_account_email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}
```

**前提条件**: Artifact Registryにイメージが存在すること

`modules/cloud-run/variables.tf`:

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
}

variable "region" {
  description = "Region for Cloud Run service"
  type        = string
}

variable "container_image" {
  description = "Container image URL"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, prod)"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for Cloud Run"
  type        = string
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "memory" {
  description = "Memory allocation (e.g., 512Mi)"
  type        = string
  default     = "512Mi"
}

variable "cpu" {
  description = "CPU allocation (e.g., 1)"
  type        = string
  default     = "1"
}
```

`modules/cloud-run/outputs.tf`:

```hcl
output "service_url" {
  value       = google_cloud_run_service.api.status[0].url
  description = "Cloud Run service URL"
}

output "service_name" {
  value       = google_cloud_run_service.api.name
  description = "Cloud Run service name"
}

output "service_id" {
  value       = google_cloud_run_service.api.id
  description = "Cloud Run service ID"
}
```

#### 3. IAMモジュール

```hcl
# modules/iam/main.tf
resource "google_service_account" "backend_api" {
  account_id   = var.service_account_id
  display_name = "Backend API Service Account"
}

resource "google_project_iam_member" "firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.backend_api.email}"
}

resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.backend_api.email}"
}

resource "google_project_iam_member" "vision_user" {
  project = var.project_id
  role    = "roles/cloudvision.user"
  member  = "serviceAccount:${google_service_account.backend_api.email}"
}

resource "google_project_iam_member" "pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.backend_api.email}"
}
```

`modules/iam/variables.tf`:

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "service_account_id" {
  description = "Service Account ID (not email)"
  type        = string
}

variable "service_account_display_name" {
  description = "Display name for the service account"
  type        = string
}

variable "service_account_roles" {
  description = "List of IAM roles to assign to the service account"
  type        = list(string)
  default     = []
}
```

`modules/iam/outputs.tf`:

```hcl
output "service_account_email" {
  value       = google_service_account.backend_api.email
  description = "Service account email address"
}

output "service_account_name" {
  value       = google_service_account.backend_api.name
  description = "Service account resource name"
}

output "service_account_id" {
  value       = google_service_account.backend_api.account_id
  description = "Service account ID"
}
```

#### 4. Storageモジュール

```hcl
# modules/storage/main.tf
resource "google_storage_bucket" "receipts" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = var.force_destroy

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = var.lifecycle_age_days
    }
    action {
      type = "Delete"
    }
  }

  encryption {
    default_kms_key_name = var.kms_key_name
  }
}
```

`modules/storage/variables.tf`:

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "bucket_name" {
  description = "Cloud Storage bucket name"
  type        = string
}

variable "region" {
  description = "Region for Cloud Storage bucket"
  type        = string
}

variable "force_destroy" {
  description = "Allow deletion of bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "lifecycle_age_days" {
  description = "Number of days after which objects are deleted"
  type        = number
  default     = 90
}

variable "kms_key_name" {
  description = "KMS key name for encryption (optional)"
  type        = string
  default     = null
}
```

`modules/storage/outputs.tf`:

```hcl
output "bucket_name" {
  value       = google_storage_bucket.receipts.name
  description = "Cloud Storage bucket name"
}

output "bucket_url" {
  value       = google_storage_bucket.receipts.url
  description = "Cloud Storage bucket URL"
}

output "bucket_id" {
  value       = google_storage_bucket.receipts.id
  description = "Cloud Storage bucket ID"
}
```

#### 5. Pub/Subモジュール

```hcl
# modules/pubsub/main.tf
resource "google_pubsub_topic" "receipt_uploaded" {
  name = var.topic_name
}

resource "google_pubsub_subscription" "receipt_uploaded_sub" {
  name  = "${var.topic_name}-sub"
  topic = google_pubsub_topic.receipt_uploaded.name

  push_config {
    push_endpoint = var.worker_endpoint
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 3
  }
}

resource "google_pubsub_topic" "dead_letter" {
  name = "${var.topic_name}-dlq"
}
```

#### 6. Monitoringモジュール

```hcl
# modules/monitoring/main.tf
resource "google_monitoring_uptime_check_config" "api_health" {
  display_name = "${var.service_name} Health Check"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path         = "/health"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.api_url
    }
  }
}

resource "google_monitoring_alert_policy" "api_response_time" {
  display_name = "${var.service_name} Response Time Alert"
  combiner     = "OR"

  conditions {
    display_name = "Response time > 3s"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_latencies\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 3000  # 3秒
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_95"
      }
    }
  }

  notification_channels = var.notification_channels
}
```

#### 7. KMSモジュール（Phase 7で実装予定）

```hcl
# modules/kms/main.tf
resource "google_kms_key_ring" "ledger_muse" {
  name     = var.keyring_name
  location = var.region
}

resource "google_kms_crypto_key" "storage_key" {
  name            = var.key_name
  key_ring        = google_kms_key_ring.ledger_muse.id
  rotation_period = "7776000s"  # 90日

  lifecycle {
    prevent_destroy = true
  }
}
```

### Staging環境のTerraform定義

`terraform/environments/staging/main.tf`のサンプルコード：

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }

  backend "gcs" {
    bucket = "ledger-muse-478602-terraform-state"  # プロジェクトIDに置き換え
    prefix = "staging"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Artifact Registry Module
module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id    = var.project_id
  repository_id = "ledger-muse"
  region        = var.region
}

# IAM Module (Backend API Service Account)
module "iam" {
  source = "../../modules/iam"

  project_id                   = var.project_id
  service_account_id           = "backend-api-staging-sa"
  service_account_display_name = "Backend API Staging Service Account"
  service_account_roles        = [
    "roles/datastore.user",        # Firestore
    "roles/storage.objectAdmin",   # Cloud Storage
    "roles/cloudvision.user",      # Cloud Vision API
    "roles/pubsub.publisher"       # Pub/Sub
  ]
}

# Cloud Run Module
module "cloud_run" {
  source = "../../modules/cloud-run"

  project_id            = var.project_id
  service_name          = "ledger-muse-api-staging"
  region                = var.region
  container_image       = "gcr.io/cloudrun/hello"  # Placeholder（初回デプロイ後、GitHub Actionsで更新）
  environment           = "staging"
  service_account_email = module.iam.service_account_email
  min_instances         = 0
  max_instances         = 10
  memory                = "512Mi"
  cpu                   = "1"

  depends_on = [
    module.artifact_registry,
    module.iam
  ]
}
```

`terraform/environments/staging/variables.tf`:

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast1"
}
```

`terraform/environments/staging/outputs.tf`:

```hcl
output "artifact_registry_repository_url" {
  value       = module.artifact_registry.repository_url
  description = "Artifact Registry repository URL"
}

output "backend_service_account_email" {
  value       = module.iam.service_account_email
  description = "Backend API service account email"
}

output "cloud_run_service_url" {
  value       = module.cloud_run.service_url
  description = "Cloud Run service URL"
}
```

## Phase 0でのインフラ構築順序

### タスク実施順序（依存関係を考慮）

```
1. リモートステートバケット作成（手動 or 初回Terraform）
   ↓
2. Terraformプロジェクト初期化
   ↓
3. Terraformモジュール作成（IAM、Artifact Registry）
   ↓
4. Artifact Registryリポジトリ作成 ← CI/CDのデプロイで必須
   ↓
5. Staging環境Terraform定義（Cloud Run、Backend SA）
   ↓
6. CI/CD Cloud Runデプロイパイプライン実装
   （この時点でArtifact Registryとサービスアカウントが存在）
```

**重要**: CI/CDの品質ゲート（Lint/Test/Build）とFirebase App Hostingは、GCPインフラに依存しないため、Terraformと並行して実装可能です。

## IAM最小権限設計

### サービスアカウント構成

| サービスアカウント | 用途 | 付与権限 |
|------------------|------|---------|
| `backend-api-sa@{project}.iam.gserviceaccount.com` | Backend API（Cloud Run） | `roles/datastore.user`<br>`roles/storage.objectAdmin`<br>`roles/cloudvision.user`<br>`roles/pubsub.publisher` |
| `github-actions-sa@{project}.iam.gserviceaccount.com` | GitHub Actions（CI/CD） | `roles/artifactregistry.writer`<br>`roles/run.admin`<br>`roles/iam.serviceAccountUser` |
| `ocr-worker-sa@{project}.iam.gserviceaccount.com` | OCR Worker | `roles/datastore.user`<br>`roles/storage.objectViewer`<br>`roles/cloudvision.user` |

### Workload Identity Federation（WIF）

GitHub ActionsからGCPへのアクセスは、サービスアカウントキーを使用せず、Workload Identity Federationを使用します。

```hcl
# modules/iam/wif.tf
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_actions_wif" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}
```

## セキュリティ設定

### Cloud Runセキュリティ

- **認証**: Cloud Run Invokerロールをパブリック（`allUsers`）に付与（APIは内部でJWT検証）
- **HTTPS強制**: 自動的にHTTPS通信のみ許可
- **環境変数**: Secret Managerからシークレットを注入

```hcl
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.api.name
  location = google_cloud_run_service.api.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
```

### Cloud Storageセキュリティ

- **暗号化**: Google管理鍵（デフォルト）、将来的にKMS
- **アクセス制御**: Uniform bucket-level access（バケットレベルIAM）
- **署名付きURL**: 一時的なアクセス権限付与

## モニタリング・アラート

### 監視対象メトリクス

| メトリクス | 閾値 | アラート |
|-----------|------|---------|
| API レスポンスタイム（95パーセンタイル） | > 3秒 | Email |
| API エラーレート | > 1% | Email |
| Cloud Run インスタンス数 | > 上限の80% | Email |
| Cloud Storage 使用量 | > 予算の80% | Email |
| Cloud Vision API クォータ使用率 | > 80% | Email |

### ログ保持ポリシー

| ログタイプ | 保持期間 | 保存先 |
|----------|---------|-------|
| アプリケーションログ | 30日 | Cloud Logging |
| アクセスログ | 30日 | Cloud Logging |
| 監査ログ | 365日 | Cloud Logging |

## コスト最適化

### 学習段階のコスト削減策

1. **Cloud Run**:
   - `min_instances = 0`（コールドスタート許容）
   - 低メモリ・低CPU設定（512Mi / 1 CPU）

2. **Cloud Storage**:
   - ライフサイクルポリシー（Staging: 90日、Production: 365日）
   - Standard Storage Class（高頻度アクセス想定）

3. **Firestore**:
   - 無料枠活用（50K reads/day、20K writes/day）
   - インデックス最小化

4. **Cloud Vision API**:
   - 無料枠活用（1,000 units/month）
   - レート制限によるコスト制御

5. **Pub/Sub**:
   - 無料枠活用（10GB/month）

6. **モニタリング**:
   - 無料枠活用（50GB logs/month）

### 推定月間コスト（学習段階）

| サービス | 使用量 | 推定コスト |
|---------|-------|----------|
| Cloud Run | 10,000リクエスト/月 | $0（無料枠内） |
| Cloud Storage | 1GB | $0.02 |
| Firestore | 10,000 reads/writes | $0（無料枠内） |
| Cloud Vision API | 100 OCR | $0（無料枠内） |
| Pub/Sub | 1GB | $0（無料枠内） |
| **合計** | - | **$0.02 〜 $5/月** |

## 将来的な拡張

### Phase 7以降での実装予定

- **Cloud KMS**: 暗号鍵管理（Storage、Secret Manager）
- **Cloud Armor**: WAF、DDoS対策
- **Cloud CDN**: 静的コンテンツ配信（Firebase App Hosting統合）
- **Cloud SQL (PostgreSQL)**: Firestoreからの移行
- **Memorystore (Redis)**: キャッシュ層
- **Cloud Scheduler**: 定期実行タスク（レポート生成など）

### マルチリージョン対応（商用段階）

- **Cloud Run**: マルチリージョンデプロイ + Cloud Load Balancer
- **Cloud Storage**: マルチリージョンバケット
- **Firestore**: マルチリージョンレプリケーション

## トラブルシューティング

### Terraform init失敗

**エラー**: `Error: Failed to get existing workspaces`

**対処法**:
1. GCSバケットが存在するか確認: `gsutil ls gs://{project-id}-terraform-state`
2. バケットへのアクセス権限を確認: `gsutil iam get gs://{project-id}-terraform-state`
3. `.terraform/`ディレクトリを削除して再試行: `rm -rf .terraform && terraform init`

### Terraform state移行失敗

**エラー**: `Error: Error acquiring the state lock`

**対処法**:
1. 他のTerraform processが実行中でないか確認
2. ロックファイルを強制削除（注意！）: `terraform force-unlock <LOCK_ID>`

### Artifact Registry API無効化エラー

**エラー**: `ERROR: (gcloud.artifacts.repositories.list) PERMISSION_DENIED: Artifact Registry API has not been used`

**対処法**:
```bash
gcloud services enable artifactregistry.googleapis.com --project={project-id}
```

### Cloud Run APIが無効

**エラー**: `Error 403: Cloud Run API has not been used`

**対処法**:
```bash
gcloud services enable run.googleapis.com --project={project-id}
```

### Terraform apply失敗（リソース競合）

**エラー**: `Error: Error creating ... already exists`

**対処法**:
1. 既存リソースをTerraform管理下にインポート:
   ```bash
   terraform import <resource_type>.<resource_name> <resource_id>
   ```
2. または、既存リソースを手動削除してから再実行

### Cloud Runデプロイ失敗（GitHub Actions）

**エラー**: GitHub ActionsでCloud Runデプロイが失敗

**対処法**:
1. GitHub Actionsのログを確認（Actions → 失敗したワークフロー → ログ）
2. GitHub Secretsが正しく設定されているか確認: `gh secret list`
3. WIF Service Accountの権限を確認:
   ```bash
   gcloud projects get-iam-policy {project-id} \
     --flatten="bindings[].members" \
     --filter="bindings.members:serviceAccount:github-deployer@*"
   ```

### Docker buildエラー（GitHub Actions）

**エラー**: `ERROR: failed to solve: failed to compute cache key`

**対処法**:
1. Dockerfileの構文を確認
2. ビルドコンテキストのパスを確認
3. GitHub Actionsで`docker/setup-buildx-action`が正しく設定されているか確認

### Cloud Run起動失敗（ヘルスチェックタイムアウト）

**エラー**: `Cloud Run error: Container failed to start. Failed to start and then listen on the port defined by the PORT environment variable`

**対処法**:
1. アプリケーションが環境変数`PORT`を読み込んでいるか確認
2. ヘルスチェックエンドポイント（`/health`）が正しく実装されているか確認
3. Cloud Runのログを確認: `gcloud run services logs read {service-name} --region {region}`

## 参考資料

- [Terraform Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Cloud Run Best Practices](https://cloud.google.com/run/docs/best-practices)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Google Cloud IAM Best Practices](https://cloud.google.com/iam/docs/best-practices)
