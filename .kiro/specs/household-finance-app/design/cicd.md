# CI/CD パイプライン設計

本ドキュメントでは、継続的インテグレーション・継続的デプロイメント（CI/CD）の具体的な実装戦略を定義します。

## CI/CDツール構成

### Frontend: Firebase App Hosting + GitHub統合

- **自動デプロイ**: Firebase App Hosting の GitHub統合機能を使用
- **プレビュー環境**: PRごとに自動生成される一時的なプレビューURL
- **本番デプロイ**: `main` ブランチへのマージで自動デプロイ
- **ステージング環境**: `develop` ブランチで自動デプロイ

### Backend: GitHub Actions + Cloud Run

- **デプロイツール**: GitHub Actions
- **コンテナレジストリ**: Artifact Registry
- **デプロイ先**: Cloud Run（staging/prod環境のみ）

## 環境戦略

| 環境 | ブランチ | Frontend | Backend | 用途 |
|------|---------|----------|---------|------|
| **Local** | `feature/*` | Next.js dev server (localhost:3000) | Go (localhost:8080) | 日常的な開発・デバッグ（Firebaseエミュレーター使用） |
| **PR Preview** | PR作成時 | Firebase App Hosting (一時URL) | Cloud Run (staging) | コードレビュー時の動作確認・統合テスト |
| **Staging** | `develop` | Firebase App Hosting (staging) | Cloud Run (staging) | 統合テスト・受け入れテスト |
| **Production** | `main` | Firebase App Hosting (production) | Cloud Run (production) | 本番環境 |

### ローカル開発環境

ローカル開発では、GCPへのデプロイは行わず、以下のツールを使用します：

- **Firebase Emulator Suite**: Firestore、Authentication、Cloud Storage、Pub/Subをエミュレート
- **Next.js Dev Server**: `npm run dev` でHMR（Hot Module Replacement）対応の開発サーバー
- **Go Backend**: `go run cmd/api/main.go` でローカルAPIサーバー起動
- **Docker Compose（オプション）**: バックエンドをコンテナ化して実行

### PR Preview 環境

Firebase App Hosting は PR 作成時に自動でプレビュー環境を生成します：

- **自動生成**: PR作成時に一時的なプレビューURLが発行される
- **バックエンド接続**: Staging環境のCloud Run APIに接続
- **自動削除**: PRマージまたはクローズ時に自動削除
- **コスト**: 無料枠内で運用可能（10,000訪問/月まで）

## GitHub Actions パイプライン

### 品質ゲートパイプライン（全PR共通）

```yaml
# .github/workflows/quality-gate.yml
name: Quality Gate

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop]

jobs:
  frontend-quality:
    name: Frontend Quality Checks
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./frontend
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type Check
        run: npm run type-check

      - name: Unit Tests
        run: npm run test

      - name: Build Check
        run: npm run build

  backend-quality:
    name: Backend Quality Checks
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./backend
    steps:
      - uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.23'
          cache: true
          cache-dependency-path: backend/go.sum

      - name: Lint
        uses: golangci/golangci-lint-action@v4
        with:
          version: latest
          working-directory: backend

      - name: Unit Tests
        run: go test -v -race -coverprofile=coverage.out ./...

      - name: Coverage Report
        run: go tool cover -func=coverage.out

      - name: Build Check
        run: go build -v ./...
```

### Backend デプロイパイプライン

```yaml
# .github/workflows/deploy-backend.yml
name: Deploy Backend to Cloud Run

on:
  push:
    branches:
      - main      # Production
      - develop   # Staging
    paths:
      - 'backend/**'
      - '.github/workflows/deploy-backend.yml'

env:
  PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  REGION: asia-northeast1
  SERVICE_NAME: ledger-muse-api

jobs:
  deploy:
    name: Deploy to Cloud Run
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write

    steps:
      - uses: actions/checkout@v4

      - name: Set environment
        id: set-env
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "ENV=prod" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
            echo "ENV=staging" >> $GITHUB_OUTPUT
          fi

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Configure Docker for Artifact Registry
        run: gcloud auth configure-docker ${{ env.REGION }}-docker.pkg.dev

      - name: Build Docker image
        working-directory: ./backend
        run: |
          docker build -t ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/ledger-muse/${{ env.SERVICE_NAME }}:${{ github.sha }} .
          docker tag ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/ledger-muse/${{ env.SERVICE_NAME }}:${{ github.sha }} \
                     ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/ledger-muse/${{ env.SERVICE_NAME }}:${{ steps.set-env.outputs.ENV }}

      - name: Push Docker image
        run: |
          docker push ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/ledger-muse/${{ env.SERVICE_NAME }}:${{ github.sha }}
          docker push ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/ledger-muse/${{ env.SERVICE_NAME }}:${{ steps.set-env.outputs.ENV }}

      - name: Deploy to Cloud Run
        run: |
          gcloud run deploy ${{ env.SERVICE_NAME }}-${{ steps.set-env.outputs.ENV }} \
            --image ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/ledger-muse/${{ env.SERVICE_NAME }}:${{ github.sha }} \
            --platform managed \
            --region ${{ env.REGION }} \
            --allow-unauthenticated \
            --set-env-vars "ENV=${{ steps.set-env.outputs.ENV }}" \
            --service-account ledger-muse-backend@${{ env.PROJECT_ID }}.iam.gserviceaccount.com \
            --min-instances 0 \
            --max-instances 10 \
            --memory 512Mi \
            --cpu 1 \
            --timeout 60s

      - name: Output Service URL
        run: |
          SERVICE_URL=$(gcloud run services describe ${{ env.SERVICE_NAME }}-${{ steps.set-env.outputs.ENV }} \
            --region ${{ env.REGION }} \
            --format 'value(status.url)')
          echo "Service URL: $SERVICE_URL"
```

## ローカル開発環境セットアップ

### Firebase Emulator Suite

ローカルでFirebaseサービスをエミュレートします：

```bash
# Firebase CLI インストール
npm install -g firebase-tools

# Firebase プロジェクト初期化
firebase init emulators

# エミュレーター起動
firebase emulators:start
```

#### エミュレーター設定（firebase.json）

```json
{
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "storage": {
      "port": 9199
    },
    "pubsub": {
      "port": 8085
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
```

### Docker Compose（オプション）

バックエンドとエミュレーターをまとめて起動：

```yaml
# docker-compose.yml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      - ENV=local
      - FIRESTORE_EMULATOR_HOST=firebase-emulator:8080
      - PUBSUB_EMULATOR_HOST=firebase-emulator:8085
    depends_on:
      - firebase-emulator

  firebase-emulator:
    image: google/cloud-sdk:latest
    command: gcloud emulators firestore start --host-port=0.0.0.0:8080
    ports:
      - "8080:8080"
      - "8085:8085"
      - "9099:9099"

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:8080
      - NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST=firebase-emulator:8080
    depends_on:
      - backend
```

### ローカル開発フロー

1. **バックエンド起動**:
   ```bash
   cd backend
   go run cmd/api/main.go
   ```

2. **フロントエンド起動**:
   ```bash
   cd frontend
   npm run dev
   ```

3. **Firebaseエミュレーター起動**:
   ```bash
   firebase emulators:start
   ```

4. **動作確認**:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8080
   - Firestore UI: http://localhost:4000

### 環境変数設定

#### フロントエンド（.env.local）

```bash
# API接続先
NEXT_PUBLIC_API_URL=http://localhost:8080

# Firebase Emulator
NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST=localhost:8080
NEXT_PUBLIC_AUTH_EMULATOR_HOST=localhost:9099

# NextAuth.js
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-development-secret
```

#### バックエンド（.env）

```bash
# 環境
ENV=local

# Firebase Emulator
FIRESTORE_EMULATOR_HOST=localhost:8080
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
STORAGE_EMULATOR_HOST=localhost:9199
PUBSUB_EMULATOR_HOST=localhost:8085

# GCP プロジェクト（エミュレーター用）
GCP_PROJECT_ID=demo-project
```

### Cloud Vision API のローカル対応

Cloud Vision APIはエミュレートできないため、以下のいずれかを選択：

1. **モック実装**（推奨）:
   ```go
   type MockOCRService struct{}

   func (m *MockOCRService) ExtractText(imageURL string) (*OCRResult, error) {
       return &OCRResult{
           Amount: 1500,
           Date: time.Now(),
           Merchant: "テストストア",
       }, nil
   }
   ```

2. **Staging環境のAPIを使用**:
   ```bash
   # 本物のCloud Vision APIを使用（APIキーまたはADC認証）
   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
   ```

## Firebase App Hosting デプロイ設定

### Firebase設定ファイル

```json
// firebase.json
{
  "hosting": {
    "source": "frontend",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ]
  }
}
```

### GitHub統合設定

Firebase App Hosting は以下を自動で実行します：

1. **PR作成時**:
   - プレビュー環境を自動生成
   - PRコメントにプレビューURLを投稿
   - 品質チェック（ビルド成功確認）

2. **`develop` ブランチマージ時**:
   - Staging環境へ自動デプロイ
   - ステージング用URLで確認可能

3. **`main` ブランチマージ時**:
   - Production環境へ自動デプロイ
   - 本番URLで公開

## 品質ゲート基準

### マージ条件

以下の条件をすべて満たす場合のみ、PRのマージを許可：

1. **Lint**: エラーなし
2. **TypeCheck**: 型エラーなし
3. **Unit Tests**: すべてのテストがパス、カバレッジ 80% 以上
4. **Build**: ビルドが成功
5. **Code Review**: 最低1名のレビュー承認

### ブランチ保護ルール

```yaml
# GitHub Branch Protection Settings
branches:
  main:
    require_pull_request_reviews:
      required_approving_review_count: 1
    require_status_checks:
      strict: true
      contexts:
        - "Frontend Quality Checks"
        - "Backend Quality Checks"
    enforce_admins: false

  develop:
    require_pull_request_reviews:
      required_approving_review_count: 1
    require_status_checks:
      strict: true
      contexts:
        - "Frontend Quality Checks"
        - "Backend Quality Checks"
```

## モニタリング・アラート

### デプロイ後の自動ヘルスチェック

```yaml
# GitHub Actions でデプロイ後にヘルスチェック
- name: Health Check
  run: |
    sleep 10
    curl -f ${{ steps.deploy.outputs.url }}/health || exit 1
```

### Cloud Monitoring 連携

- **デプロイ成功率**: Cloud Build メトリクス
- **API エラーレート**: Cloud Run メトリクス（5分間隔）
- **レスポンスタイム**: 95パーセンタイル < 1秒

### アラート設定

| アラート | 条件 | 通知先 |
|---------|------|--------|
| デプロイ失敗 | ビルド・デプロイエラー | GitHub Issues + Email |
| エラーレート上昇 | 5分間のエラー率 > 5% | Email |
| レスポンスタイム遅延 | 95パーセンタイル > 2秒 | Email |

## ロールバック戦略

### 自動ロールバック

Cloud Run のリビジョン管理機能を使用：

```bash
# 直前のリビジョンにロールバック
gcloud run services update-traffic ledger-muse-api-prod \
  --to-revisions PREVIOUS=100 \
  --region asia-northeast1
```

### 手動ロールバック手順

1. Cloud Console で異常検知
2. GitHub Actions の "Re-run jobs" で前回の成功デプロイを再実行
3. または、`gcloud` コマンドで特定リビジョンへ切り替え

## セキュリティ

### Workload Identity Federation

GitHub Actions から GCP へのアクセスは、サービスアカウントキーを使わず Workload Identity Federation を使用：

```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: 'projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github/providers/github-provider'
    service_account: 'github-actions@PROJECT_ID.iam.gserviceaccount.com'
```

### Secrets 管理

| Secret | 用途 | 保存場所 |
|--------|------|---------|
| GCP_PROJECT_ID | プロジェクトID | GitHub Secrets |
| WIF_PROVIDER | Workload Identity Provider | GitHub Secrets |
| WIF_SERVICE_ACCOUNT | サービスアカウント | GitHub Secrets |

## Terraform との連携

### インフラ変更のCI/CD

```yaml
# .github/workflows/terraform.yml
name: Terraform

on:
  pull_request:
    paths:
      - 'terraform/**'
  push:
    branches: [main]
    paths:
      - 'terraform/**'

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Terraform Init
        run: terraform init
        working-directory: terraform

      - name: Terraform Plan
        if: github.event_name == 'pull_request'
        run: terraform plan
        working-directory: terraform

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
        working-directory: terraform
```

## コスト最適化

### CI/CD コスト削減策

1. **キャッシュ活用**: npm/go モジュールキャッシュで実行時間短縮
2. **並列実行**: Frontend/Backend の品質チェックを並列化
3. **条件付き実行**: 変更があったディレクトリのみテスト実行
4. **GitHub Actions 無料枠**: パブリックリポジトリは無料、プライベートは月2,000分まで無料

### 環境別リソース設定

| 環境 | Cloud Run インスタンス | メモリ | CPU |
|------|----------------------|--------|-----|
| Staging | min: 0, max: 3 | 512Mi | 1 |
| Production | min: 0, max: 10 | 512Mi | 1 |

**注**: ローカル開発環境はGCPリソースを使用しないため、コスト削減と管理負担軽減を実現します。

## 参考資料

- [Firebase App Hosting Documentation](https://firebase.google.com/docs/app-hosting)
- [Cloud Run CI/CD Best Practices](https://cloud.google.com/run/docs/continuous-deployment-with-cloud-build)
- [GitHub Actions for Google Cloud](https://github.com/google-github-actions)
