# CI/CD Secrets (Firebase App Hosting)

## デプロイ方法の説明

**重要:** このプロジェクトでは、Firebase App Hostingの**GitHub統合機能**を使用しています。

### Firebase GitHub統合とは？

Firebase App HostingのGitHub統合は、GitHubリポジトリと直接連携する機能です：

- ✅ **自動デプロイ**: 指定ブランチへのプッシュで自動的にデプロイ
- ✅ **PR Preview**: Pull Request作成時に自動的にプレビュー環境を作成
- ✅ **GitHub Actions不要**: `.github/workflows/`にワークフローファイルを作成する必要なし
- ✅ **Firebase側で管理**: デプロイはFirebaseのインフラで実行

### このプロジェクトの設定

```yaml
# .github/workflows/ci.yml のコメント参照
# Note: Frontend deployment to Firebase App Hosting is handled by GitHub integration
# PR previews and production deployments are automatically triggered by Firebase App Hosting
# This CI pipeline only performs quality checks for frontend
```

**CI/CDパイプラインの役割分担:**
- **GitHub Actions** (`ci.yml`): 品質チェック（Lint、Test、Build）のみ
- **Firebase GitHub統合**: 実際のデプロイ（自動）

### GitHub Secrets（Firebase GitHub統合用）

Firebase GitHub統合を使用する場合、以下のSecretsは**Firebase側で自動管理**されます：

- `FIREBASE_PROJECT_ID`: Firebaseが自動設定
- `FIREBASE_SERVICE_ACCOUNT`: Firebaseが自動設定
- Backend ID: Firebase Console で Backend作成時に指定

**手動でGitHub Secretsを設定する必要はありません**（Firebase統合が自動的に処理）。

---

## カスタムワークフローを使用する場合（オプション）

Firebase GitHub統合ではなく、カスタムGitHub Actionsワークフローを使用する場合のみ、以下のSecretsが必要です：

- `FIREBASE_PROJECT_ID`: Firebase プロジェクト ID（例: `ledger-muse`）
- `FIREBASE_SERVICE_ACCOUNT`: デプロイ用サービスアカウントの JSON 資格情報
- `APP_HOSTING_BACKEND_PROD`: `main` 用の Backend ID（例: `ledger-muse-prod`）
- `APP_HOSTING_BACKEND_STAGING`: `develop`／PR 用の Backend ID（例: `ledger-muse-staging`）

**注意:** Firebase App Hostingは"Site ID"ではなく**"Backend ID"**という概念を使います。

### 必要な権限

デプロイ用サービスアカウント（`firebase-apphosting-deployer`）には以下の権限が必要です：
- `roles/firebasehosting.admin` - Firebase Hostingのデプロイと管理
- `roles/iam.serviceAccountUser` - サービスアカウントの使用

### サービスアカウントの作成（Terraform）

Firebase App Hosting用のサービスアカウントは `terraform/apphosting/` で管理されています。

#### 1. Terraform apply でサービスアカウントを作成

```bash
cd terraform/apphosting

# 変数ファイルを確認（既に存在する場合）
cat terraform.tfvars

# 存在しない場合は作成
cat > terraform.tfvars <<EOF
project_id = "ledger-muse"
region     = "asia-northeast1"
EOF

# Terraform 初期化と適用
terraform init
terraform plan
terraform apply

# サービスアカウントのメールアドレスを確認
terraform output service_account_email
```

**期待される出力:**
```
service_account_email = "firebase-apphosting-deployer@ledger-muse.iam.gserviceaccount.com"
```

#### 2. サービスアカウントキーの発行

**重要:** サービスアカウントキー（JSON）の発行は、セキュリティ上の理由でTerraform stateに保存しないため**手作業**で行います。

```bash
# サービスアカウントのメールアドレスを取得
SA_EMAIL=$(cd terraform/apphosting && terraform output -raw service_account_email)

# JSONキーを発行してダウンロード
gcloud iam service-accounts keys create ~/firebase-apphosting-key.json \
  --iam-account="$SA_EMAIL"

# キーの内容を確認
cat ~/firebase-apphosting-key.json
```

#### 3. GitHub Secrets に登録

**方法A: GitHub CLI を使用（推奨）**

```bash
# プロジェクトルートディレクトリで実行
gh secret set FIREBASE_PROJECT_ID --body "ledger-muse"
gh secret set FIREBASE_SERVICE_ACCOUNT < ~/firebase-apphosting-key.json

# Backend IDは手動で設定（Firebase App Hostingコンソールで確認後）
# gh secret set APP_HOSTING_BACKEND_PROD --body "ledger-muse-prod"
# gh secret set APP_HOSTING_BACKEND_STAGING --body "ledger-muse-staging"

# 設定を確認
gh secret list

# JSONキーファイルを削除（セキュリティ）
rm ~/firebase-apphosting-key.json
```

**方法B: GitHub Web UI を使用**

1. GitHubリポジトリページ → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** をクリック
3. 以下のSecretを追加:
   - **Name**: `FIREBASE_PROJECT_ID`, **Secret**: `ledger-muse`
   - **Name**: `FIREBASE_SERVICE_ACCOUNT`, **Secret**: `~/firebase-apphosting-key.json` の内容をコピー&ペースト
   - **Name**: `APP_HOSTING_BACKEND_PROD`, **Secret**: Firebaseコンソールで確認したBackend ID（例: `ledger-muse-prod`）
   - **Name**: `APP_HOSTING_BACKEND_STAGING`, **Secret**: Firebaseコンソールで確認したBackend ID（例: `ledger-muse-staging`）
4. JSONキーファイルを削除: `rm ~/firebase-apphosting-key.json`

### Firebase App Hosting Backend IDとは？

**Backend ID**は、Firebase App Hostingで作成される各バックエンド環境の一意の識別子です。

**Backend IDの形式:**
- URLフォーマット: `{backend-id}--{project-id}.us-central1.hosted.app`
- 例: `ledger-muse-prod--ledger-muse.us-central1.hosted.app`
  - Backend ID: `ledger-muse-prod`
  - Project ID: `ledger-muse`

### Backend IDの確認方法

#### 方法1: Firebase Console（推奨）

1. **Firebase Console にアクセス**
   - https://console.firebase.google.com/ → プロジェクト選択

2. **App Hosting に移動**
   - 左メニュー → **Build** → **App Hosting**

3. **Backend情報を確認**
   - 各バックエンドのカードに以下が表示されます：
     - **Backend name** (これがBackend ID)
     - **URL**: `{backend-id}--{project-id}.us-central1.hosted.app`
     - **Git branch**: 連携しているブランチ名
     - **Last deployed**: 最終デプロイ日時

4. **Backend IDを取得**
   - Backend nameに表示されている値をコピー
   - または、URLの`--`より前の部分がBackend ID

**Firebase Consoleの表示例:**
```
┌─────────────────────────────────────────────┐
│ Backend: ledger-muse-prod                   │
│ URL: ledger-muse-prod--ledger-muse.us-cen...│
│ Branch: main                                │
│ Last deployed: 2 hours ago                  │
└─────────────────────────────────────────────┘
```

#### 方法2: Firebase CLI

**Backend一覧を表示:**
```bash
# Firebase CLIでBackend一覧を表示
firebase apphosting:backends:list --project ledger-muse
```

**期待される出力:**
```
┌────────────────────┬──────────────────────────────────────────────────┬──────────┐
│ Backend ID         │ URL                                              │ Branch   │
├────────────────────┼──────────────────────────────────────────────────┼──────────┤
│ ledger-muse-prod   │ ledger-muse-prod--ledger-muse.us-central1...     │ main     │
│ ledger-muse-staging│ ledger-muse-staging--ledger-muse.us-central1...  │ develop  │
└────────────────────┴──────────────────────────────────────────────────┴──────────┘
```

**特定のBackend情報を確認:**
```bash
# Backend詳細を表示
firebase apphosting:backends:describe ledger-muse-prod --project ledger-muse
```

#### 方法3: gcloud コマンド

```bash
# Cloud Runサービスとして確認（App HostingはCloud Runを使用）
gcloud run services list \
  --platform managed \
  --region us-central1 \
  --filter="metadata.labels.firebase-app-hosting-backend:*"
```

### Backend の作成方法

Firebase App HostingのBackendは、以下の方法で作成できます：

#### Firebase Console（推奨）

1. Firebase Console → **Build** → **App Hosting**
2. **Get started** または **Add another backend** をクリック
3. GitHub リポジトリを選択
4. **Backend settings** を設定:
   - **Backend name**: 任意の名前（例: `ledger-muse-prod`）
   - **Git branch**: デプロイ対象ブランチ（例: `main`）
   - **Root directory**: アプリのルートディレクトリ（例: `frontend`）
5. **Create backend** をクリック

#### Firebase CLI

```bash
# 新しいBackendを作成
firebase apphosting:backends:create \
  --project ledger-muse \
  --location us-central1

# ブランチを指定してBackendを作成
firebase apphosting:backends:create \
  --project ledger-muse \
  --location us-central1 \
  --git-branch main
```

作成時に対話式プロンプトでBackend名を入力します。

### GitHub Secretsへの設定

Backend IDを確認したら、GitHub Secretsに登録します：

```bash
# Backend IDをGitHub Secretsに設定
gh secret set APP_HOSTING_BACKEND_PROD --body "ledger-muse-prod"
gh secret set APP_HOSTING_BACKEND_STAGING --body "ledger-muse-staging"

# 設定を確認
gh secret list | grep APP_HOSTING
```

### Terraform による自動化

**自動化されている部分（`terraform/apphosting/`）:**
- `google_service_account` - Firebase App Hosting用サービスアカウント作成
- `google_project_iam_member` - 必要な権限の付与（`roles/firebasehosting.admin`, `roles/iam.serviceAccountUser`）

**手作業が必要な部分:**
- サービスアカウントキー（JSON）の発行（セキュリティ上、Terraform stateに保存しない）
- GitHub Actions Secrets の登録
- Firebase App Hosting Backendの作成とBackend IDの確認

### セキュリティ上の注意

- JSONキーファイルは**絶対にGitにコミットしない**
- GitHub Secretsに登録後、ローカルのJSONファイルは削除する
- サービスアカウントには必要最小限の権限のみを付与する

---

# CI/CD Secrets (Cloud Run Deploy)

GitHub Actions `.github/workflows/ci.yml` で必要な Secrets/設定:

- `GCP_PROJECT_ID`: デプロイ先 Google Cloud プロジェクト ID (例: `ledger-muse`)
- `WIF_PROVIDER`: Workload Identity Federation Provider リソースパス
- `WIF_SERVICE_ACCOUNT`: Workload Identity で紐づけるサービスアカウント (例: `github-deployer@ledger-muse.iam.gserviceaccount.com`)

デプロイでは Artifact Registry `asia-northeast1-docker.pkg.dev/<PROJECT_ID>/ledger-muse/<SERVICE_NAME>` へ push したイメージを Cloud Run へデプロイします。

### 必要な権限

デプロイ用サービスアカウント（`github-deployer`）には以下の権限が必要です：
- `roles/artifactregistry.writer` - Dockerイメージのプッシュ
- `roles/run.admin` - Cloud Runサービスのデプロイ
- `roles/iam.serviceAccountUser` - サービスアカウントの使用

### GitHub Secrets の設定手順

#### 1. Terraform Outputs から値を取得

```bash
# プロジェクトルートディレクトリで実行
cd terraform/wif

# 必要な値を取得
export GCP_PROJECT_ID=$(grep 'project_id' ../common.auto.tfvars | cut -d'"' -f2)
export WIF_PROVIDER=$(terraform output -raw wif_provider_name)
export WIF_SERVICE_ACCOUNT=$(terraform output -raw service_account_email)

# 値を確認
echo "GCP_PROJECT_ID: $GCP_PROJECT_ID"
echo "WIF_PROVIDER: $WIF_PROVIDER"
echo "WIF_SERVICE_ACCOUNT: $WIF_SERVICE_ACCOUNT"
```

**期待される出力例:**
```
GCP_PROJECT_ID: ledger-muse
WIF_PROVIDER: projects/912371481714/locations/global/workloadIdentityPools/github-pool/providers/github
WIF_SERVICE_ACCOUNT: github-deployer@ledger-muse.iam.gserviceaccount.com
```

#### 2. GitHub Secrets に登録

**方法A: GitHub CLI を使用（推奨）**

```bash
# プロジェクトルートディレクトリで実行
gh secret set GCP_PROJECT_ID --body "$GCP_PROJECT_ID"
gh secret set WIF_PROVIDER --body "$WIF_PROVIDER"
gh secret set WIF_SERVICE_ACCOUNT --body "$WIF_SERVICE_ACCOUNT"

# 設定を確認
gh secret list
```

**方法B: GitHub Web UI を使用**

1. GitHubリポジトリページ → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** をクリック
3. 以下の3つのSecretを追加:
   - **Name**: `GCP_PROJECT_ID`, **Secret**: 上記で取得した値
   - **Name**: `WIF_PROVIDER`, **Secret**: 上記で取得した値
   - **Name**: `WIF_SERVICE_ACCOUNT`, **Secret**: 上記で取得した値

#### 3. 設定の検証

テスト用ブランチを作成してCI/CDワークフローを実行し、デプロイが成功することを確認します：

```bash
# テスト用ブランチ作成
git checkout -b test/ci-secrets-verification
echo "" >> README.md
git add README.md
git commit -m "test: Verify CI/CD secrets configuration"
git push origin test/ci-secrets-verification

# PRを作成
gh pr create --title "Test: CI/CD Secrets Verification" \
             --body "Testing GitHub Secrets configuration for Cloud Run deployment"

# ワークフロー実行を監視
gh run watch
```

成功すると、以下のジョブが完了します：
- ✅ Backend Quality Checks
- ✅ Deploy Backend to Cloud Run
- ✅ Health Check with Retry

### Preview環境のクリーンアップ

`.github/workflows/cleanup-preview.yml` は、PRクローズ時に自動的に以下をクリーンアップします：
- Cloud Run Preview サービス (`ledger-muse-api-pr-{NUMBER}`)
- Artifact Registry の Preview イメージ

このワークフローも同じSecrets（`GCP_PROJECT_ID`, `WIF_PROVIDER`, `WIF_SERVICE_ACCOUNT`）を使用します。

### Terraform による自動化

WIF（Workload Identity Federation）のセットアップは `terraform/wif/` で管理されています：

**自動化されている部分:**
- `google_service_account` - デプロイ用サービスアカウント作成
- `google_project_iam_member` - 必要な権限の付与
- `google_iam_workload_identity_pool` - WIF プール作成
- `google_iam_workload_identity_pool_provider` - GitHub OIDC プロバイダ作成
- `google_service_account_iam_member` - `roles/iam.workloadIdentityUser` 権限付与

**手作業が必要な部分:**
- GitHub Actions Secrets の登録（上記手順参照）
- 初回のTerraform apply実行

### トラブルシューティング

#### Secrets が設定されていない場合

ワークフローが以下のエラーで失敗します：
```
Error: Missing required secret: GCP_PROJECT_ID
```

→ 上記手順で Secrets を設定してください。

#### WIF 認証エラー

```
Error: google-github-actions/auth failed with: retry function failed after 1 attempt(s)
```

→ 以下を確認してください：
1. `WIF_PROVIDER` と `WIF_SERVICE_ACCOUNT` の値が正確か
2. Terraform WIF モジュールが正しくデプロイされているか（`cd terraform/wif && terraform plan`）
3. サービスアカウントに必要な権限が付与されているか

#### Artifact Registry 権限エラー

```
Error: denied: Permission "artifactregistry.repositories.uploadArtifacts" denied
```

→ サービスアカウントに `roles/artifactregistry.writer` が付与されているか確認：
```bash
gcloud projects get-iam-policy ledger-muse \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:github-deployer@ledger-muse.iam.gserviceaccount.com"
```
