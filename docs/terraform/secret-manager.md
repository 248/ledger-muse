# Secret Manager デプロイガイド

## 目的

Firebase App Hosting から Backend API にアクセスするための環境変数（バックエンド URL）を Secret Manager で安全に管理します。

## 前提条件

- Task 2.3 完了（Terraform モジュール基盤が整っている）
- Task 2.6 完了（Cloud Run サービスがデプロイ済み）
- Secret Manager API が有効化されている
- App Hosting サービスアカウントが作成されている

## デプロイ手順

### 1. Secret Manager API を有効化

Staging 環境の `main.tf` には既に `google_project_service.secretmanager` が含まれています。

### 2. App Hosting サービスアカウントの取得

App Hosting のサービスアカウントメールアドレスを取得します：

```bash
# gcloud コマンドで確認
gcloud iam service-accounts list --filter="displayName:Firebase App Hosting"

# 通常: firebase-app-hosting-compute@<PROJECT_ID>.iam.gserviceaccount.com
```

### 3. 環境変数ファイルの設定

`terraform/environments/staging/` に `secret-manager.auto.tfvars` を作成：

```hcl
# Backend API URL (Cloud Run URL)
backend_api_url = "https://ledger-muse-api-staging-<hash>-<region>.a.run.app"

# App Hosting サービスアカウントに Secret へのアクセス権を付与
# App Hosting requires both service accounts:
# - firebase-app-hosting-compute: Used at RUNTIME to access secrets
# - firebase-apphosting-deployer: Used at BUILD TIME to access secrets
backend_api_url_secret_accessors = [
  "serviceAccount:firebase-app-hosting-compute@<PROJECT_ID>.iam.gserviceaccount.com",
  "serviceAccount:firebase-apphosting-deployer@<PROJECT_ID>.iam.gserviceaccount.com"
]
```

**注意**:
- `<PROJECT_ID>` を実際のプロジェクトIDに置き換えてください
- このサービスアカウントはApp Hostingが自動作成します

### 4. Terraform 実行

```bash
# 1. 初期化（新しいモジュールを追加したため）
terraform -chdir=terraform/environments/staging init \
  -backend-config="bucket=ledger-muse-terraform-state"

# 2. プラン確認
terraform -chdir=terraform/environments/staging plan \
  -var-file=../../common.auto.tfvars \
  -var-file=secret-manager.auto.tfvars

# 3. 適用
terraform -chdir=terraform/environments/staging apply \
  -var-file=../../common.auto.tfvars \
  -var-file=secret-manager.auto.tfvars
```

### 5. 検証

Secret が正しく作成されたことを確認：

```bash
# Secret 一覧の確認
gcloud secrets list --filter="name:BACKEND_API_BASE_STAGING"

# Secret の値を確認
gcloud secrets versions access latest --secret="BACKEND_API_BASE_STAGING"

# IAM 権限の確認
gcloud secrets get-iam-policy BACKEND_API_BASE_STAGING
```

期待される出力：
- Secret ID: `BACKEND_API_BASE_STAGING`
- Secret Data: `https://ledger-muse-api-staging-<hash>-<region>.a.run.app`
- IAM Member: App Hosting サービスアカウント（`roles/secretmanager.secretAccessor`）

## App Hosting 設定

### apphosting.staging.yaml

```yaml
runConfig:
  cpu: 1
  memoryMiB: 512
  minInstances: 0
  maxInstances: 1
  concurrency: 80

env:
  - variable: NEXT_PUBLIC_BACKEND_API_BASE
    secret: BACKEND_API_BASE_STAGING
    availability:
      - BUILD
      - RUNTIME
```

この設定により、App Hosting は Secret Manager から `BACKEND_API_BASE_STAGING` を読み取り、環境変数 `NEXT_PUBLIC_BACKEND_API_BASE` として Next.js アプリに注入します。

## トラブルシューティング

### エラー: "Permission denied on secret"

App Hosting サービスアカウントに `roles/secretmanager.secretAccessor` が付与されているか確認：

```bash
gcloud secrets get-iam-policy BACKEND_API_BASE_STAGING
```

### エラー: "Secret not found"

Secret が正しく作成されているか確認：

```bash
gcloud secrets list --project=<PROJECT_ID>
```

### Secret 値の更新

Backend URL が変更された場合：

```bash
# 1. tfvars の backend_api_url を更新
# 2. terraform apply を再実行
terraform -chdir=terraform/environments/staging apply \
  -var-file=../../common.auto.tfvars \
  -var-file=secret-manager.auto.tfvars
```

Terraform は自動的に新しい Secret バージョンを作成します。

## セキュリティのベストプラクティス

1. **最小権限の原則**: App Hosting サービスアカウントのみにアクセス権を付与
2. **Secret のバージョン管理**: Terraform が自動的にバージョンを管理
3. **ログへの記録禁止**: Secret データは sensitive マークされ、Terraform ログに表示されません
4. **定期的な監査**: IAM ポリシーを定期的にレビュー

## 関連ドキュメント

- [Secret Manager Module README](../../terraform/modules/secret-manager/README.md)
- [Firebase App Hosting 環境変数設定](https://firebase.google.com/docs/app-hosting/configure)
- [Terraform 総合ガイド](./README.md)
