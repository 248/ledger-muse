# Staging フロントエンド ⇔ バックエンド疎通確認手順 (Phase 1 / Task 8.2)

Firebase App Hosting (Frontend) から Cloud Run (Backend) への HTTPS 呼び出しを検証するための手順です。CORS とレスポンスタイム (<1s 目標) を確認します。

## 事前準備

### 1. Secret Manager の設定（Terraform）

Secret Manager への登録と IAM 権限の設定は Terraform で管理します。

**設定ファイル**: `terraform/environments/staging/secret-manager.auto.tfvars`

```hcl
# Backend API URL (Cloud Run URL)
backend_api_url = "https://ledger-muse-api-staging-<hash>.a.run.app"

# App Hosting サービスアカウントに Secret へのアクセス権を付与
# サービスアカウント確認: gcloud iam service-accounts list --filter="displayName:Firebase App Hosting"
# 実際の形式: firebase-app-hosting-compute@<PROJECT_ID>.iam.gserviceaccount.com
backend_api_url_secret_accessors = [
  "serviceAccount:firebase-app-hosting-compute@<PROJECT_ID>.iam.gserviceaccount.com"
]
```

**Terraform 実行**:

```bash
# 1. 初期化（初回のみ）
terraform -chdir=terraform/environments/staging init \
  -backend-config="bucket=ledger-muse-terraform-state"

# 2. 適用
terraform -chdir=terraform/environments/staging apply \
  -var-file=../../common.auto.tfvars \
  -var-file=secret-manager.auto.tfvars
```

詳細は [Secret Manager デプロイガイド](./terraform/secret-manager.md) を参照してください。

### 2. App Hosting の `apphosting.yaml` で Secret を参照

`frontend/apphosting.staging.yaml`:

```yaml
env:
  - variable: NEXT_PUBLIC_BACKEND_API_BASE
    secret: BACKEND_API_BASE_STAGING
    availability:
      - BUILD
      - RUNTIME
```

> **注意**:
> - Firebase Console の App Hosting 画面には環境変数を直接編集する UI はありません
> - 環境変数は `apphosting.yaml` + Secret Manager で管理します
> - Secret Manager の作成・更新・IAM 権限は Terraform で管理します

## 確認手順

### 1. バックエンドのヘルスチェック

```bash
curl -w "status=%{http_code} time_total=%{time_total}\n" \
  -s -o /dev/null <BACKEND_URL>/health
```

**期待される結果**:
- HTTP Status: `200`
- Response Time: `< 1秒`

### 2. フロントエンドのデプロイと確認

```bash
# 変更をプッシュ（GitHub Actions が自動デプロイ）
git add .
git commit -m "feat: Secret Manager integration for staging environment"
git push origin <branch-name>
```

デプロイ後、Firebase Console の App Hosting から URL にアクセスし、以下を確認：

**期待される表示**:
- ヒーロー下の「バックエンド接続」カードに「バックエンド: OK (vX.X.X)」が表示される

**エラー時の確認項目**:
- CORS エラー: Cloud Run 側のレスポンスヘッダを確認
- 接続エラー: `NEXT_PUBLIC_BACKEND_API_BASE` の値を確認
- ローカルでの再現: `NEXT_PUBLIC_BACKEND_API_BASE=http://localhost:8080 npm run dev`

## 成果物
- ブラウザでの表示確認（「バックエンド: OK ...」）
- `/health` への HTTPS curl ログ（200 / <1s）

