# Secret Manager デプロイガイド

## 目的

Firebase App Hosting から Backend API にアクセスするための環境変数（バックエンド URL）を Secret Manager で安全に管理します。

## アーキテクチャ概要

このガイドでは **Terraform** と **Firebase CLI** を組み合わせたハイブリッドアプローチを採用します：

- **Terraform**: シークレットの作成とユーザー指定のサービスアカウント権限管理
- **Firebase CLI**: App Hosting固有のIAMバインディング自動設定（`firebase apphosting:secrets:grantaccess`）

このアプローチにより、インフラのコード管理とFirebaseエコシステムの利便性を両立できます。

## 前提条件

- Task 2.3 完了（Terraform モジュール基盤が整っている）
- Task 2.6 完了（Cloud Run サービスがデプロイ済み）
- Secret Manager API が有効化されている
- Firebase CLI がインストール済み（`npm install -g firebase-tools`）

## デプロイ手順

### 1. Secret Manager API を有効化

Staging 環境の `main.tf` には既に `google_project_service.secretmanager` が含まれています。

### 2. 環境変数ファイルの設定

`terraform/environments/staging/` に `secret-manager.auto.tfvars` を作成：

```hcl
# Backend API URL (Cloud Run URL)
# Get from: gcloud run services describe ledger-muse-api-staging --region asia-northeast1 --format='value(status.url)'
backend_api_url = "https://ledger-muse-api-staging-912371481714.asia-northeast1.run.app"

# Note: Service account permissions are managed by Firebase CLI
# Run: firebase apphosting:secrets:grantaccess BACKEND_API_BASE_STAGING --backend staging --location asia-east1 --project <PROJECT_ID>
```

**注意**:
- `backend_api_url` を実際の Cloud Run URL に置き換えてください
- IAM権限設定はTerraformでは行いません（Firebase CLIで管理）

### 3. Terraform 実行

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

### 4. シークレット作成の確認

Secret が正しく作成されたことを確認：

```bash
# Secret 一覧の確認
gcloud secrets list --filter="name:BACKEND_API_BASE_STAGING"

# Secret の値を確認
gcloud secrets versions access latest --secret="BACKEND_API_BASE_STAGING"

# IAM 権限の確認（Terraform管理分）
gcloud secrets get-iam-policy BACKEND_API_BASE_STAGING
```

期待される出力：
- Secret ID: `BACKEND_API_BASE_STAGING`
- Secret Data: `https://ledger-muse-api-staging-912371481714.asia-northeast1.run.app`
- IAM Bindings: この時点ではなし（次のステップでFirebase CLIが設定）

### 5. Firebase CLI で App Hosting 用の権限を付与

**重要**: Terraform でシークレットを作成した後、Firebase CLI コマンドで App Hosting 固有の IAM バインディングを設定します。

```bash
firebase apphosting:secrets:grantaccess BACKEND_API_BASE_STAGING \
  --backend staging \
  --location asia-east1 \
  --project <PROJECT_ID>
```

このコマンドは以下を自動的に設定します：
- `firebase-app-hosting-compute` へ `secretAccessor` - シークレット値の読み取り（`secretmanager.versions.access`）
- `firebase-app-hosting-compute` へ `viewer` - メタデータの読み取り
- Firebase App Hosting Service Agent (`service-PROJECT_NUMBER@gcp-sa-firebaseapphosting`) へ `secretVersionManager` - バージョン管理

成功すると以下のメッセージが表示されます：
```
✔  Successfully set IAM bindings on secret BACKEND_API_BASE_STAGING.
```

権限設定を確認：
```bash
gcloud secrets get-iam-policy BACKEND_API_BASE_STAGING --project=ledger-muse
```

### 6. App Hosting 設定ファイルの確認

`frontend/apphosting.staging.yaml` にシークレット参照が正しく設定されているか確認：

```yaml
runConfig:
  cpu: 1
  memoryMiB: 512
  minInstances: 0
  maxInstances: 1
  concurrency: 80

env:
  # Staging backend API base URL - loaded from Secret Manager
  - variable: NEXT_PUBLIC_BACKEND_API_BASE
    secret: BACKEND_API_BASE_STAGING
    availability:
      - BUILD
      - RUNTIME
```

この設定により、App Hosting は Secret Manager から `BACKEND_API_BASE_STAGING` を読み取り、環境変数 `NEXT_PUBLIC_BACKEND_API_BASE` として Next.js アプリに注入します。

### 7. Firebase App Hosting でデプロイ

Firebase コンソールまたは GitHub 連携で staging 環境にデプロイします。ビルド時およびランタイムで環境変数が正しく注入されることを確認してください。

## 権限の確認

Firebase CLI コマンド実行後の権限状態を確認：

```bash
# シークレットレベルの IAM ポリシー確認
gcloud secrets get-iam-policy BACKEND_API_BASE_STAGING

# プロジェクトレベルの Secret Manager 権限確認
gcloud projects get-iam-policy ledger-muse \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/secretmanager.*" \
  --format="table(bindings.role,bindings.members)"
```

期待される権限構成（全てFirebase CLI管理）：
```yaml
bindings:
- members:
  - serviceAccount:firebase-app-hosting-compute@PROJECT_ID.iam.gserviceaccount.com
  role: roles/secretmanager.secretAccessor
- members:
  - serviceAccount:service-PROJECT_NUMBER@gcp-sa-firebaseapphosting.iam.gserviceaccount.com
  role: roles/secretmanager.secretVersionManager
- members:
  - serviceAccount:firebase-app-hosting-compute@PROJECT_ID.iam.gserviceaccount.com
  role: roles/secretmanager.viewer
```

**重要**:
- `secretAccessor` が最も重要な権限（`versions.access`を提供し、ビルド時のエラーを防ぐ）
- 3つ全ての権限がFirebase CLIコマンド1回で設定されます

## トラブルシューティング

### エラー: "Permission 'secretmanager.versions.access' denied"

**症状**: ビルド時に以下のエラーが発生：
```
Permission 'secretmanager.versions.access' denied for resource
'projects/PROJECT_NUMBER/secrets/BACKEND_API_BASE_STAGING/versions/1'
```

**原因**: Firebase CLI コマンドが実行されていない、または `secretAccessor` 権限が不足しています。

**解決策**: Firebase CLI コマンドを実行してください：

```bash
firebase apphosting:secrets:grantaccess BACKEND_API_BASE_STAGING \
  --backend staging \
  --location asia-east1 \
  --project <PROJECT_ID>
```

このコマンドは `secretAccessor` 権限を含む必要な全権限を設定します。

### エラー: "Secret not found"

**原因**: Terraform でシークレットが作成されていません。

**解決策**: Terraform apply を実行してシークレットを作成してください：

```bash
terraform -chdir=terraform/environments/staging apply \
  -var-file=../../common.auto.tfvars \
  -var-file=secret-manager.auto.tfvars
```

### ビルドエラー: Secret reference format

**注意**: シークレット参照は**シンプルな形式**（`BACKEND_API_BASE_STAGING`）を使用してください。プロジェクト番号形式（`projects/NUMBER/secrets/ID/versions/VERSION`）は不要です。

### Secret 値の更新

Backend URL が変更された場合：

```bash
# 1. tfvars の backend_api_url を更新
# 2. terraform apply を再実行
terraform -chdir=terraform/environments/staging apply \
  -var-file=../../common.auto.tfvars \
  -var-file=secret-manager.auto.tfvars
```

Terraform は自動的に新しい Secret バージョンを作成します。Firebase CLI での再設定は不要です。

## セキュリティのベストプラクティス

1. **責任分離**:
   - Terraform: インフラ管理者が管理（シークレット作成）
   - Firebase CLI: デプロイ担当者が実行（全ての IAM 権限設定）

2. **最小権限の原則**: 各サービスアカウントに必要最小限の権限のみを付与

3. **Secret のバージョン管理**: Terraform が自動的にバージョンを管理

4. **ログへの記録禁止**: Secret データは sensitive マークされ、Terraform ログに表示されません

5. **定期的な監査**: IAM ポリシーを定期的にレビュー

## なぜ Firebase CLI を使用するのか？

Firebase App Hosting のシークレット権限設定には以下の理由でFirebase CLIの使用が推奨されます：

1. **Google管理のService Agent**: `service-PROJECT_NUMBER@gcp-sa-firebaseapphosting` はGoogle管理のサービスアカウントで、Terraformで直接管理することは推奨されません

2. **複数の権限の組み合わせ**: 3つの異なる権限（`secretAccessor`, `viewer`, `secretVersionManager`）を正確に設定する必要があります

3. **自動的な権限検証**: Firebase CLIはApp Hostingに必要な最小限かつ十分な権限を自動的に設定します

4. **メンテナンス性**: Firebase App Hostingの権限要件が変更された場合、Firebase CLIが自動的に対応します

Firebase CLI の `apphosting:secrets:grantaccess` コマンドは、これらの複雑な権限設定を1回のコマンドで正しく構成してくれます。

## 関連ドキュメント

- [Secret Manager Module README](../../terraform/modules/secret-manager/README.md)
- [Firebase App Hosting 環境変数設定](https://firebase.google.com/docs/app-hosting/configure)
- [Terraform 総合ガイド](./README.md)
- [Firebase CLI Reference - apphosting:secrets:grantaccess](https://firebase.google.com/docs/cli#apphosting_commands)
