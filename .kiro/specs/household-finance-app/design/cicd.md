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

### 統合CI/CDパイプライン

プロジェクトでは単一の統合型パイプラインを採用し、品質チェックからデプロイまでを一貫して管理します。

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop]
  workflow_dispatch:

# Cancel in-progress runs on the same PR
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  # 1. 変更検出ジョブ
  changes:
    name: Detect Changes
    runs-on: ubuntu-latest
    outputs:
      frontend: ${{ steps.filter.outputs.frontend }}
      backend: ${{ steps.filter.outputs.backend }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            frontend:
              - 'frontend/**'
              - '.github/workflows/ci.yml'
              - 'firebase.json'
            backend:
              - 'backend/**'
              - '.github/workflows/ci.yml'

  # 2. Frontend品質チェック（並列実行）
  frontend-quality:
    name: Frontend Quality Checks
    needs: changes
    if: needs.changes.outputs.frontend == 'true'
    runs-on: ubuntu-latest
    steps:
      # 品質チェック（Lint, TypeCheck, Test, Build）

  # 3. Backend品質チェック（並列実行）
  backend-quality:
    name: Backend Quality Checks
    needs: changes
    if: needs.changes.outputs.backend == 'true'
    runs-on: ubuntu-latest
    steps:
      # 品質チェック（Lint, Test, Build）

  # 4. Frontendデプロイ（品質チェック成功時のみ）
  deploy-frontend:
    name: Deploy Frontend to App Hosting
    needs: [changes, frontend-quality]
    if: |
      needs.changes.outputs.frontend == 'true' &&
      (github.event_name == 'push' || github.event_name == 'pull_request')
    runs-on: ubuntu-latest
    steps:
      # Firebase App Hostingへのデプロイ

  # 5. Backendデプロイ（品質チェック成功時のみ）
  deploy-backend:
    name: Deploy Backend to Cloud Run
    needs: [changes, backend-quality]
    if: |
      needs.changes.outputs.backend == 'true' &&
      github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      # Cloud Runへのデプロイ
```

### パイプラインの動作フロー

```
┌──────────────┐
│   changes    │  変更検出
└──────┬───────┘
       │
       ├─────────────────┬─────────────────┐
       │                 │                 │
       ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  スキップ
│  frontend-   │  │  backend-    │  (変更なし)
│  quality     │  │  quality     │
└──────┬───────┘  └──────┬───────┘
       │                 │
       │ (成功時のみ)     │ (成功時のみ)
       ▼                 ▼
┌──────────────┐  ┌──────────────┐
│  deploy-     │  │  deploy-     │
│  frontend    │  │  backend     │
└──────────────┘  └──────────────┘
```

### 主な改善点

1. **品質保証の強化**
   - 品質チェックが失敗した場合、デプロイは自動的にスキップ
   - `needs`による明示的な依存関係定義

2. **効率化**
   - `dorny/paths-filter`で変更がない部分は自動スキップ
   - Frontend/Backend品質チェックを並列実行

3. **重複実行の防止**
   - `concurrency`制御で同じPRの古い実行を自動キャンセル

4. **可視性の向上**
   - 1つのワークフローで全体のステータスを一目で確認可能
   - GitHub UIでパイプライン全体の進捗を追跡

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

### Docker環境（Colima + Docker Compose）

**開発環境**: macOS + Homebrew + Colima（Docker Desktop の軽量代替）

#### Colima セットアップ

```bash
# Homebrew で Colima と Docker ツールをインストール
brew install colima docker docker-compose

# Colima 起動（リソース設定）
colima start --cpu 4 --memory 8 --disk 60

# Docker 動作確認
docker ps
docker compose version
```

#### Colima 設定のポイント

| 設定項目 | 推奨値 | 説明 |
|---------|--------|------|
| CPU | 4 | Backend（1コンテナ）+ Emulator（1コンテナ）で十分 |
| Memory | 8GB | Firebaseエミュレーター（2GB）+ Backend（1GB）+ バッファ（5GB） |
| Disk | 60GB | イメージ、コンテナ、ボリューム用 |

**注**: Frontend はホスト実行のため Colima VM のリソースを消費しません。

```bash
# リソース変更する場合（停止→削除→再起動）
colima stop
colima delete
colima start --cpu 4 --memory 8 --disk 60

# 状態確認
colima status
colima list
```

#### Docker Compose 設定（Backend + Emulator のみ）

**重要**: Frontend（Next.js）はホストマシンで直接実行します（HMRパフォーマンス最適化のため）

```yaml
# docker-compose.yml
version: '3.8'

services:
  # Firebase Emulator Suite
  firebase-emulator:
    image: node:20-alpine
    working_dir: /app
    volumes:
      - ./firebase.json:/app/firebase.json:ro
      - ./firestore-data:/app/firestore-data  # データ永続化
    ports:
      - "8080:8080"   # Firestore
      - "8085:8085"   # Pub/Sub
      - "9099:9099"   # Authentication
      - "9199:9199"   # Storage
      - "4000:4000"   # Emulator UI
    command: |
      sh -c "npm install -g firebase-tools && firebase emulators:start --project demo-project"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Backend API (Go + Echo)
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.dev
    ports:
      - "8080:8080"
    environment:
      - ENV=local
      - FIRESTORE_EMULATOR_HOST=firebase-emulator:8080
      - FIREBASE_AUTH_EMULATOR_HOST=firebase-emulator:9099
      - STORAGE_EMULATOR_HOST=firebase-emulator:9199
      - PUBSUB_EMULATOR_HOST=firebase-emulator:8085
      - GCP_PROJECT_ID=demo-project
    volumes:
      - ./backend:/app:delegated  # ホットリロード用（macOS最適化）
    depends_on:
      firebase-emulator:
        condition: service_healthy
    command: |
      sh -c "go run cmd/api/main.go"
```

**なぜFrontendをDockerコンテナ化しないか**:
- macOSのボリュームマウントI/Oレイテンシーの影響
- HMR（Hot Module Replacement）の遅延（数秒の差が開発体験を著しく低下）
- ホスト実行であれば変更即反映（100ms未満）

#### Dockerfile.dev（Backend用）

```dockerfile
# backend/Dockerfile.dev
FROM golang:1.23-alpine

WORKDIR /app

# 開発用ツールのインストール
RUN apk add --no-cache git curl

# Go モジュールのキャッシュ
COPY go.mod go.sum ./
RUN go mod download

# Air（ホットリロードツール）のインストール
RUN go install github.com/cosmtrek/air@latest

COPY . .

# Air でホットリロード起動
CMD ["air", "-c", ".air.toml"]
```

#### macOS + Colima 特有の注意点

1. **ボリュームマウントのパフォーマンス**:
   ```yaml
   # 高速化オプション（必要に応じて）
   volumes:
     - ./backend:/app:delegated
   ```

2. **ホストマシンからのアクセス**:
   - `localhost:3000` でFrontend
   - `localhost:8080` でBackend API
   - `localhost:4000` でFirebase Emulator UI
   - Colima は自動的にポートフォワーディング設定

3. **ネットワーク設定**:
   - コンテナ間通信: サービス名で解決（`backend`, `firebase-emulator`）
   - ホストからコンテナ: `localhost:PORT`

### ローカル開発フロー

#### パターン1: ハイブリッドアプローチ（推奨）

**Backend + Emulator（Docker）+ Frontend（ホスト実行）**

```bash
# ターミナル1: Docker Compose でバックエンド + エミュレーター起動
colima start  # 初回のみ
docker compose up -d
docker compose logs -f  # ログ監視（オプション）

# ターミナル2: フロントエンド起動（ホストマシンで直接実行）
cd frontend
npm run dev

# 動作確認
# - Frontend: http://localhost:3000
# - Backend API: http://localhost:8080/health
# - Firestore UI: http://localhost:4000

# 停止
docker compose down  # Backend + Emulator 停止
# Frontend は Ctrl+C で停止
colima stop  # 完全に停止する場合（通常は起動したまま）
```

**所要時間**: 合計30秒程度

**メリット**:
- Frontend の HMR が高速（変更即反映）
- Backend は本番環境（Cloud Run）との一貫性を保持
- Emulator は依存関係を隔離

#### パターン2: すべて個別起動（最軽量）

Docker不要の場合：

```bash
# ターミナル1: Firebaseエミュレーター起動
firebase emulators:start

# ターミナル2: バックエンド起動
cd backend
go run cmd/api/main.go

# ターミナル3: フロントエンド起動
cd frontend
npm run dev

# 動作確認（同上）
```

**メリット**: Docker/Colima不要、最軽量
**デメリット**: 本番環境との差異、依存関係管理が煩雑

#### Colima の日常的な使い方

```bash
# 起動
colima start

# 状態確認
colima status

# 停止（VM停止、リソース解放）
colima stop

# 再起動
colima restart

# 削除（完全にクリーンアップ）
colima delete

# リソース情報確認
docker info
docker stats
```

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
