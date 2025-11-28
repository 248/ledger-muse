# Cloud Run 環境変数設定ガイド

Cloud Run サービスに環境変数を設定する方法を説明します。

## 現在の状態

現在の `terraform/modules/cloud-run` モジュールは、単一の環境変数 `ENV` のみをサポートしています：

```hcl
env {
  name  = "ENV"
  value = var.environment
}
```

複数の環境変数を設定するには、モジュールの拡張が必要です。

## 設定方法

### 方法1: Cloud Runモジュールの拡張（推奨）

#### 1.1 モジュールの修正

**`terraform/modules/cloud-run/variables.tf`** に変数を追加：

```hcl
variable "env_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}
```

**`terraform/modules/cloud-run/main.tf`** の `env` ブロックを修正：

```hcl
spec {
  service_account_name = var.service_account_email

  containers {
    image = var.container_image

    # 環境変数を動的に設定
    dynamic "env" {
      for_each = merge(
        { ENV = var.environment },
        var.env_vars
      )
      content {
        name  = env.key
        value = env.value
      }
    }

    resources {
      limits = {
        memory = var.memory
        cpu    = var.cpu
      }
    }
  }
}
```

#### 1.2 Staging環境での利用

**`terraform/environments/staging/main.tf`** でモジュール呼び出しを修正：

```hcl
module "backend_api_cloud_run" {
  source = "../../modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  service_name          = var.backend_api_cloud_run_service_name
  container_image       = var.backend_api_cloud_run_container_image
  environment           = var.backend_api_cloud_run_environment
  service_account_email = module.backend_api_service_account.service_account_email

  # 環境変数を追加
  env_vars = {
    FIREBASE_PROJECT_ID = var.project_id
  }

  min_instances = var.backend_api_cloud_run_min_instances
  max_instances = var.backend_api_cloud_run_max_instances
  memory        = var.backend_api_cloud_run_memory
  cpu           = var.backend_api_cloud_run_cpu

  depends_on = [google_project_service.cloudrun]
}
```

#### 1.3 適用

```bash
cd terraform/environments/staging
terraform init
terraform plan -var-file=../../common.auto.tfvars
terraform apply -var-file=../../common.auto.tfvars
```

---

### 方法2: GitHub Actions CI/CDでの設定（PR Preview用）

PR Preview環境では、GitHub Actionsワークフローで環境変数を直接設定します。

**`.github/workflows/ci.yml`** の修正例：

```yaml
- name: Deploy to Cloud Run
  run: |
    gcloud run deploy "${{ env.PREVIEW_PREFIX }}${{ github.event.pull_request.number }}" \
      --project "$PROJECT_ID" \
      --region "$REGION" \
      --image "${{ env.ARTIFACT_REPOSITORY }}/${{ env.PREVIEW_PREFIX }}${{ github.event.pull_request.number }}:${{ github.sha }}" \
      --platform managed \
      --allow-unauthenticated \
      --service-account "${{ env.STAGING_SERVICE_ACCOUNT }}@$PROJECT_ID.iam.gserviceaccount.com" \
      --set-env-vars "ENV=preview,FIREBASE_PROJECT_ID=$PROJECT_ID" \
      --memory "$CLOUD_RUN_MEMORY" \
      --cpu "$CLOUD_RUN_CPU" \
      --timeout "$CLOUD_RUN_TIMEOUT" \
      --min-instances "$CLOUD_RUN_MIN_INSTANCES" \
      --max-instances "$CLOUD_RUN_MAX_INSTANCES" \
      --concurrency "$CLOUD_RUN_CONCURRENCY" \
      --quiet
```

**ポイント**:
- `--set-env-vars` でカンマ区切りで複数の環境変数を設定
- `$PROJECT_ID` は既に環境変数として利用可能
- Staging/Production環境も同様に修正可能

---

### 方法3: tfvarsファイルでの設定

環境変数を外部ファイルで管理したい場合：

**`terraform/environments/staging/cloud-run.auto.tfvars`** を作成：

```hcl
backend_api_cloud_run_env_vars = {
  FIREBASE_PROJECT_ID = "ledger-muse-478602"
  LOG_LEVEL           = "info"
}
```

**`terraform/environments/staging/variables.tf`** に変数定義を追加：

```hcl
variable "backend_api_cloud_run_env_vars" {
  description = "Additional environment variables for Backend API Cloud Run"
  type        = map(string)
  default     = {}
}
```

**`terraform/environments/staging/main.tf`** で利用：

```hcl
module "backend_api_cloud_run" {
  # ...
  env_vars = var.backend_api_cloud_run_env_vars
  # ...
}
```

適用：

```bash
terraform apply -var-file=../../common.auto.tfvars -var-file=cloud-run.auto.tfvars
```

---

## よく使う環境変数

| 変数名 | 説明 | 例 |
|--------|------|-----|
| `ENV` | 環境識別子 | `staging`, `production`, `preview` |
| `FIREBASE_PROJECT_ID` | Firebase/GCPプロジェクトID | `ledger-muse-478602` |
| `PORT` | **※予約済み - Cloud Runが自動設定** | `8080`（読み取り専用） |
| `LOG_LEVEL` | ログレベル | `debug`, `info`, `warn`, `error` |
| `GCP_PROJECT` | GCPプロジェクトID（SDKで自動認識） | `ledger-muse-478602` |

## Secret Managerとの連携

機密情報（APIキー、パスワードなど）は環境変数として直接設定せず、Secret Managerを使用します：

```hcl
env {
  name = "DATABASE_PASSWORD"
  value_from {
    secret_key_ref {
      name = "database-password"
      key  = "latest"
    }
  }
}
```

詳細は `docs/terraform/secret-manager.md` を参照してください。

---

## トラブルシューティング

### 環境変数が反映されない

1. **Terraformの再適用**: モジュール変更後は `terraform init` と `terraform apply` を実行
2. **Cloud Runのリビジョン確認**:
   ```bash
   gcloud run services describe <service-name> \
     --region asia-northeast1 \
     --format='value(spec.template.spec.containers[0].env)'
   ```
3. **ログ確認**: Cloud Runログで環境変数の読み込みエラーを確認

### CI/CDでデプロイが失敗する

**エラー**: `The user-provided container failed to start and listen on the port`

**原因**:
- `FIREBASE_PROJECT_ID` などの必須環境変数が未設定
- `PORT` は予約済み環境変数のため手動設定不可（Cloud Runが自動設定）

**解決策**:
1. `.github/workflows/ci.yml` で `--set-env-vars` を確認
2. バックエンドコードで環境変数の読み込みを確認：
   ```go
   projectID := os.Getenv("FIREBASE_PROJECT_ID")
   if projectID == "" {
       return nil, fmt.Errorf("FIREBASE_PROJECT_ID environment variable must be set")
   }
   ```

---

## 関連ドキュメント

- [Terraform総合ガイド](./README.md)
- [Secret Manager設定](./secret-manager.md)
- [Cloud Run公式ドキュメント](https://cloud.google.com/run/docs/configuring/environment-variables)
