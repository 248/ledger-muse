# 実装タスク

## Phase 0: プロジェクト基盤構築

### フェーズ目標

Phase 0では、以下の3つの基盤を構築します：

1. **開発環境**: リポジトリ、Frontend/Backendプロジェクト、ローカル開発環境
2. **インフラ基盤（Terraform）**: GCPリソース（Artifact Registry、Cloud Run、IAMなど）
3. **CI/CD**: 品質ゲート、Firebase App Hosting、Cloud Runデプロイパイプライン

**重要**: CI/CDのCloud Runデプロイは、Terraformによるインフラ構築後に実施します（Artifact Registry、サービスアカウントが必要）。

---

### 1. 開発環境セットアップ

- [x] 1.1 (P) リポジトリとディレクトリ構造の初期化
  - モノレポ構造（`frontend/`, `backend/`, `terraform/`）の作成
  - `.gitignore` の設定（Node.js、Go、Terraform用）
  - ルートレベルの `README.md` 作成
  - **前提条件**: なし
  - **成果物**: リポジトリ構造
  - **検証方法**: `ls -la` でディレクトリ確認
  - _Requirements: 16.1_

- [x] 1.2 (P) Frontend プロジェクトの初期化
  - Next.js 15.x プロジェクト作成（TypeScript、App Router）
  - ESLint、Prettier の設定
  - Vitest + React Testing Library のセットアップ
  - Tailwind CSS の導入
  - `package.json` スクリプト定義（dev、build、lint、type-check、test）
  - **前提条件**: タスク1.1完了
  - **成果物**: `frontend/` ディレクトリ、`package.json`
  - **検証方法**: `npm run lint`, `npm run type-check`, `npm run test`, `npm run build` が成功
  - _Requirements: 13.1, 16.1_

- [x] 1.3 (P) Backend プロジェクトの初期化
  - Go プロジェクト初期化（`go mod init`）
  - Echo フレームワーク v4.x の導入
  - golangci-lint 設定（`.golangci.yml`）
  - Hexagonal Architecture のディレクトリ構造作成（`cmd/`, `internal/domain/`, `internal/application/`, `internal/adapter/`, `internal/port/`, `pkg/`）
  - **前提条件**: タスク1.1完了
  - **成果物**: `backend/` ディレクトリ、`go.mod`、`.golangci.yml`
  - **検証方法**: `go build ./...`, `golangci-lint run` が成功
  - _Requirements: 10.1, 16.1_

---

### 2. Terraform基盤構築

**実施目的**: GCPリソース（Artifact Registry、Cloud Run、IAMなど）を構築し、CI/CDデプロイの前提条件を整える。

#### 既存リソースの状況（タスク実施前）

以下のリソースは既にデプロイ済みです：

**Workload Identity Federation（WIF）**
- **場所**: `terraform/wif/`
- **stateファイル**: ローカル（`terraform/wif/terraform.tfstate`）
- **リソース**:
  - Workload Identity Pool: `github-actions-pool`
  - OIDC Provider: `github-actions-provider`
  - Service Account: `github-deployer@{project-id}.iam.gserviceaccount.com`
  - IAM権限:
    - `roles/artifactregistry.writer` - Dockerイメージプッシュ用
    - `roles/run.admin` - Cloud Runデプロイ用
    - `roles/iam.serviceAccountUser` - SAの使用権限

**未デプロイのリソース（以下のタスクで新規作成）**:
- Artifact Registry リポジトリ（タスク2.4）
- Backend API Service Account（タスク2.5）
- Cloud Run サービス（タスク2.6）

---

#### 実行手順の概要

1. **ステップ1**: リモートステートバケット作成（タスク2.1）
2. **ステップ2**: 既存WIF stateのリモート移行（タスク2.2）
3. **ステップ3**: 新しいモジュール作成とデプロイ（タスク2.3-2.6）

---

- [x] 2.1 リモートステートバケット作成（Terraform Bootstrap）
  - **前提条件**: GCPプロジェクト作成済み、Terraform CLI インストール済み
  - `google_storage_bucket` で Terraform ステート用バケット作成（バージョニング有効化）
  - IAM 最小権限設定（開発者に `roles/storage.objectAdmin`）
  - **成果物**: `{project-id}-terraform-state` バケット
  - **検証方法**: `gsutil ls gs://{project-id}-terraform-state` でバケット確認
  - **実行コマンド**:
    ```bash
    gcloud storage buckets create gs://{project-id}-terraform-state \
      --location=asia-northeast1 \
      --uniform-bucket-level-access
    ```
  - **注意**: 初回のみ手動実行、または bootstrap 用 Terraform で作成
  - **メモ (2025-11-19)**:
    - `terraform/bootstrap` に state バケット作成手順・テストを追加し、`common.auto.tfvars` から `region` を受け取れるよう修正。
    - Terraform Runner 専用 SA モジュール (`terraform/iam-runner`) とドキュメントを追加し、runner を `state_admin_members` に追加して `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` で Terraform を実行する運用を整理。
  - _Requirements: 17.1, 17.2_

- [x] 2.2 Terraform プロジェクト初期化とWIF state移行
  - **前提条件**: タスク2.1完了、既存WIF（`terraform/wif/`）がデプロイ済み
  - Terraform バージョン指定（v1.9.x）、`terraform/provider.tf` 作成（既存の場合はスキップ）
  - 環境分離構造作成（`terraform/environments/staging/`, `terraform/environments/prod/`）
  - 共通変数定義（`terraform/common.auto.tfvars`）確認
  - **既存WIF stateのリモート移行**:
    - `terraform/wif/backend.tf` を作成してGCSバックエンド設定
    - `terraform init -migrate-state` でローカルstateをリモートに移行
  - **成果物**:
    - `terraform/backend.tf` - ルートレベルのバックエンド設定（新規の場合）
    - `terraform/environments/staging/` - Staging環境ディレクトリ
    - `terraform/wif/backend.tf` - WIFモジュールのバックエンド設定
    - リモートバケットに `wif/default.tfstate` が作成される
  - **実行コマンド**:
    ```bash
    # WIFモジュールにbackend.tfを追加
    cd terraform/wif
    cat > backend.tf <<'EOF'
    terraform {
      backend "gcs" {
        bucket = "{project-id}-terraform-state"
        prefix = "wif"
      }
    }
    EOF

    # stateをリモートに移行
    terraform init -migrate-state
    # "Successfully configured the backend" を確認

    # リモートバケットにstateファイルが作成されたことを確認
    gsutil ls gs://{project-id}-terraform-state/wif/
    ```
  - **検証方法**:
    - `terraform init` が成功、"Successfully configured the backend" メッセージ確認
    - `gsutil ls gs://{project-id}-terraform-state/wif/` でstateファイル確認
    - `terraform state list` で既存リソースがリストされることを確認
  - **メモ (2025-11-20)**:
    - `terraform/backend.tf` と `terraform/provider.tf` を追加し、GCS backend (`ledger-muse-478602-terraform-state/global`) と Terraform 1.9 系の required_version を共通化。
    - `terraform/environments/{staging,prod}` ディレクトリを新設し、今後の環境別 root モジュールの置き場とする README を配置。
    - `terraform/wif/backend.tf` を追加し `terraform init -migrate-state` で GCS backend に移行するドキュメント (`docs/terraform/wif.md`) とテスト (`tests/terraform-remote-state.test.sh`) を更新。
  - _Requirements: 17.1, 17.2, 17.3_

- [x] 2.3 (P) Terraform モジュール作成（基本リソース）
  - **前提条件**: タスク2.2完了
  - **既存モジュール**: `terraform/wif/` - Workload Identity Federation（デプロイ済み、移行のみ）
  - **新規作成モジュール**:
    - `modules/artifact-registry/` モジュール（Dockerリポジトリ）
    - `modules/iam/` モジュール（Backend API Service Account専用）
    - `modules/cloud-run/` モジュール（Backend API ホスティング）
    - `modules/storage/` モジュール（Cloud Storage バケット、Phase 4で使用）
  - **注意**:
    - WIFモジュールは既にデプロイ済みなので、新規作成ではなくstate管理のみ
    - `modules/iam/` は Backend API用のService Accountを作成（WIF Deployer SAとは別物）
  - **成果物**: `terraform/modules/` 配下のモジュールファイル（`main.tf`, `variables.tf`, `outputs.tf`）
  - **検証方法**: `terraform validate` で各モジュールの構文チェック
  - **メモ (2025-11-20)**:
    - Artifact Registry / IAM / Cloud Run / Storage の 4 モジュールを設計書通りに作成し、`tests/terraform-modules.test.sh` で存在と主要属性を検証。
    - `docs/terraform/README.md` にモジュール一覧を追記して参照先を一元化。
  - _Requirements: 17.5_

- [x] 2.4 (P) Artifact Registry リポジトリ作成（Terraform apply）
  - **前提条件**: タスク2.3完了
  - `terraform/environments/staging/main.tf` で `artifact-registry` モジュールを呼び出し
  - `asia-northeast1` に Docker リポジトリ `ledger-muse` を作成
  - **既存WIF Service Accountの権限について**:
    - `github-deployer` SAには既に `roles/artifactregistry.writer` 権限が設定済み
    - 追加のIAM設定は不要（既存WIFで対応済み）
  - **成果物**: Artifact Registry リポジトリ（`asia-northeast1-docker.pkg.dev/{project-id}/ledger-muse`）
  - **検証方法**:
    ```bash
    gcloud artifacts repositories list --location=asia-northeast1
    # ledger-muse リポジトリが存在することを確認
    ```
  - **重要**: このタスク完了後、CI/CDでDockerイメージをプッシュ可能になる
  - **メモ (2025-11-20)**:
    - `terraform/environments/staging` に backend/provider/variables/main/outputs を作成し、Artifact Registry モジュールを呼び出して `ledger-muse` リポジトリをデプロイできるようにした。
    - `tests/terraform-environments.test.sh` を追加して環境ルート構成とモジュール呼び出しを検証。`docs/terraform/README.md` に実行手順を追記。
  - _Requirements: 12.1, 15.10_

- [x] 2.5 Backend API サービスアカウント作成（Terraform apply）
  - **前提条件**: タスク2.3完了
  - `terraform/environments/staging/main.tf` で `iam` モジュールを呼び出し
  - Backend API用サービスアカウント作成（`backend-api-staging-sa`）
  - **WIF Deployer SAとの違い**:
    - `github-deployer`: GitHub Actionsがデプロイ時に使用（既存）
    - `backend-api-staging-sa`: Cloud Runで実行時に使用（新規作成）
  - 必要な権限付与（`roles/datastore.user`, `roles/storage.objectAdmin`, `roles/pubsub.publisher`, `roles/serviceusage.serviceUsageConsumer`）  
    - ※ Cloud Vision API 専用ロールは現在提供されていないため、将来必要であれば tfvars で追加する
  - **成果物**: サービスアカウント、IAMポリシーバインディング
  - **検証方法**:
    ```bash
    gcloud iam service-accounts list | grep backend-api
    # backend-api-staging-sa が存在することを確認
    ```
  - **重要**: このタスク完了後、Cloud Runデプロイ時にサービスアカウントを指定可能
  - **注意**: Workload Identity Federationの設定は不要（既存WIFで対応済み）
  - **メモ (2025-11-20)**:
    - `terraform/environments/staging/main.tf` で `module "backend_api_service_account"` を追加し、`modules/iam` から SA 作成＋IAM 付与を自動化。
    - `variables.tf` に `backend_api_service_account_{id,display_name,roles}` を追加し、Firestore/Storage/Vision/PubSub のロールをデフォルトで持たせた。
    - `outputs.tf` で SA の email を出力し、Cloud Run (2.6) から参照しやすいように整理。`docs/terraform/README.md` に実行手順を追記。
  - _Requirements: 11.1, 11.2, 12.1_

- [x] 2.6 Staging 環境 Cloud Run 初期定義（Terraform apply）
  - **前提条件**: タスク2.4, 2.5完了
  - `terraform/environments/staging/main.tf` で `cloud-run` モジュールを呼び出し
  - Cloud Run サービス作成（`ledger-muse-api-staging`）
  - コンテナイメージはプレースホルダー（`gcr.io/cloudrun/hello`）
  - サービスアカウント指定: `backend-api-staging-sa@{project-id}.iam.gserviceaccount.com`
  - 環境変数、メモリ、CPU、スケーリング設定
  - **成果物**: Cloud Run サービス（初期デプロイ）
  - **検証方法**:
    ```bash
    gcloud run services list --platform managed
    # ledger-muse-api-staging が存在することを確認

    # エンドポイントアクセス
    curl $(gcloud run services describe ledger-muse-api-staging --platform managed --region asia-northeast1 --format 'value(status.url)')
    # プレースホルダーアプリからのレスポンスを確認
    ```
  - **注意**: 以降のデプロイはGitHub Actionsで更新（既存WIF Deployer SAを使用）
  - **メモ (2025-11-20)**:
    - `terraform/environments/staging` に `module "backend_api_cloud_run"` を追加し、Cloud Run モジュールへサービス名/イメージ/スケール閾値/ENVを tfvars ベースで渡せるようにした。
    - 変数・outputs を追加し、`module.backend_api_service_account.service_account_email` をそのまま実行コンテキストに渡す構成に整理。
    - `tests/terraform-environments.test.sh` へ Cloud Run ブロック検証を追加し、`docs/terraform/README.md` に plan/apply 手順 + CLI/コンソール確認手順を追記。
  - _Requirements: 12.1, 12.7, 12.12_

- [ ] 2.7* Queue/Async 基盤スキャフォールド（Terraform）
  - **前提条件**: タスク2.5完了
  - Pub/Sub トピック/サブスクリプション雛形（`receipt-uploaded`）
  - Cloud Tasks キュー雛形
  - OCR ワーカー用 Cloud Run サービス/SA をプレースホルダー作成
  - **成果物**: Pub/Sub、Cloud Tasks リソース
  - **検証方法**: `gcloud pubsub topics list`, `gcloud tasks queues list` で確認
  - **注意**: Phase 4まで延期可能（OCR機能実装時に必須）
  - _Requirements: 5.9, 5.10, 12.4, 12.5, 12.6_

- [ ] 2.8* KMS キーリング/キー雛形（Terraform）
  - **前提条件**: タスク2.2完了
  - KMS キーリング作成（`ledger-muse-staging`）
  - 暗号鍵作成（`storage-key`）
  - Rotation policy 設定（90日）
  - **成果物**: KMS キーリング、暗号鍵
  - **検証方法**: `gcloud kms keyrings list` で確認
  - **注意**: Phase 7まで延期可能（暗号化強化時に必須）
  - _Requirements: 19.4, 19.6_

- [ ] 2.9* Monitoring/Alerting 雛形（Terraform）
  - **前提条件**: タスク2.6完了
  - Uptime Check 作成（Cloud Run `/health` エンドポイント）
  - AlertPolicy 作成（レスポンス遅延 > 3秒、エラーレート > 1%）
  - **成果物**: Uptime Check、Alert Policy
  - **検証方法**: GCPコンソールでアラート確認
  - **注意**: Phase 7まで延期可能（運用監視強化時に必須）
  - _Requirements: 12.8, 15.3, 15.4_

---

### 3. CI/CD品質ゲートとFirebase App Hosting

**実施目的**: GCPインフラに依存しない品質チェックとフロントエンドデプロイを先行実施。

- [x] 3.1 GitHub Actions 品質ゲートワークフロー作成
  - **前提条件**: タスク1.2, 1.3完了
  - `.github/workflows/ci.yml` の実装（Lint、TypeCheck、Test、Build）
  - Frontend 品質ゲート（ESLint、TypeScript、Vitest）
  - Backend 品質ゲート（golangci-lint、`go test`、`go build`）
  - 変更検出（`dorny/paths-filter`）による最適化
  - **成果物**: `.github/workflows/ci.yml`（品質チェック部分）
  - **検証方法**: PR作成時にワークフロー実行、すべてのチェックが成功
  - _Requirements: 15.10, 16.1_

- [x] 3.2 (P) Firebase App Hosting の GitHub 統合
  - **前提条件**: なし（Firebase側で完結）
  - Firebase プロジェクト作成
  - Firebase App Hosting の有効化
  - GitHub リポジトリ連携設定
  - PR Preview 環境の設定
  - **成果物**: Firebase App Hosting設定、GitHub統合
  - **検証方法**: PR作成時にプレビューURLが発行される
  - _Requirements: 13.1, 15.10_

---

### 4. Cloud Runデプロイパイプライン

**実施目的**: Terraformで構築したインフラ（Artifact Registry、サービスアカウント、Cloud Run）を使用してBackendをデプロイ。

#### GitHub Secrets設定（タスク4.1の前提条件）

Cloud Runデプロイワークフロー（タスク4.1）を実行する前に、以下のGitHub Secretsを設定する必要があります。

**必要なSecrets**

| Secret | 説明 | 取得方法 |
|--------|------|---------|
| `GCP_PROJECT_ID` | GCPプロジェクトID | `terraform/common.auto.tfvars`の`project_id` |
| `WIF_PROVIDER` | Workload Identity Provider ID | `terraform/wif/`で`terraform output wif_provider_name` |
| `WIF_SERVICE_ACCOUNT` | WIF用サービスアカウントメール | `terraform/wif/`で`terraform output service_account_email` |

**設定手順**

```bash
# 1. Terraform outputから値を取得
cd terraform/wif
export WIF_PROVIDER=$(terraform output -raw wif_provider_name)
export WIF_SERVICE_ACCOUNT=$(terraform output -raw service_account_email)
export GCP_PROJECT_ID=$(grep 'project_id' ../common.auto.tfvars | cut -d'"' -f2)

# 2. GitHub Secretsに設定（GitHub CLIを使用）
gh secret set GCP_PROJECT_ID --body "$GCP_PROJECT_ID"
gh secret set WIF_PROVIDER --body "$WIF_PROVIDER"
gh secret set WIF_SERVICE_ACCOUNT --body "$WIF_SERVICE_ACCOUNT"

# 3. 設定確認
gh secret list
```

**注意**: GitHub CLIがない場合は、GitHub UIから手動で設定してください：
1. GitHubリポジトリページ → Settings → Secrets and variables → Actions
2. "New repository secret"をクリック
3. 上記の値を入力

---

- [x] 4.1 (P) Cloud Run デプロイワークフロー実装
  - **前提条件**: タスク2.4, 2.5, 2.6完了（Artifact Registry、SA、Cloud Runが存在）
  - `.github/workflows/ci.yml` にデプロイジョブ追加
  - Workload Identity Federation による GCP 認証
  - Dockerイメージビルド
  - Artifact Registry へのイメージプッシュ
  - Cloud Run へのデプロイ（Staging環境、PR preview、Production）
  - デプロイ後のヘルスチェック
  - **成果物**: `.github/workflows/ci.yml`（デプロイ部分）
  - **重要**: ワークフローファイル自体は既に作成済みだが、実行確認は未完了
  - **検証方法（詳細）**:

    **ステップ1: テスト用ブランチとPRの作成**
    ```bash
    # 1. テスト用ブランチを作成
    git checkout -b test/cloud-run-deploy

    # 2. 軽微な変更を加える（例: READMEに空行追加）
    echo "" >> README.md
    git add README.md
    git commit -m "test: Verify Cloud Run deploy pipeline"

    # 3. ブランチをプッシュ
    git push origin test/cloud-run-deploy

    # 4. PRを作成
    gh pr create --title "Test: Cloud Run deploy pipeline" \
                 --body "Testing Cloud Run deployment workflow"
    ```

    **ステップ2: GitHub Actionsの実行確認**
    1. GitHubリポジトリページ → "Actions"タブ
    2. "CI/CD Pipeline"ワークフローが実行中であることを確認
    3. ワークフロー名をクリックして詳細を表示
    4. "Deploy Backend to Cloud Run"ジョブが成功するまで待機

    **ステップ3: ワークフロー失敗時のログ確認**
    ```bash
    # GitHub CLIでログを確認
    gh run list --limit 1
    gh run view <run-id> --log-failed
    ```

    **ステップ4: Cloud Run URLの確認とヘルスチェック**
    ```bash
    # Cloud Runサービス一覧を確認
    gcloud run services list --platform managed --region asia-northeast1

    # サービスURLを取得
    export SERVICE_URL=$(gcloud run services describe ledger-muse-api-pr-2 \
      --platform managed \
      --region asia-northeast1 \
      --format 'value(status.url)')

    # ヘルスチェック
    curl $SERVICE_URL/health
    # 期待される出力: {"status":"ok","version":"..."}
    ```

    **ステップ5: PRコメントの確認**
    - PR画面に戻り、GitHub Actionsボットが以下のコメントを投稿していることを確認:
      ```
      ### 🚀 Backend Preview Deployed

      **API URL**: https://ledger-muse-api-pr-2-....a.run.app
      **Health Check**: https://ledger-muse-api-pr-2-....a.run.app/health

      This preview will be available until the PR is closed.
      ```
  - _Requirements: 12.1, 12.7, 15.10_

---

### 5. ローカル開発環境セットアップ

**実施目的**: GCPに接続せずにローカルでフルスタック開発を可能にする。

- [x] 5.1 Firebase Emulator Suite のセットアップ
  - **前提条件**: タスク1.2完了
  - Firebase CLI のインストール
  - `firebase init emulators` による初期化
  - `firebase.json` の設定（Auth、Firestore、Storage、Pub/Sub、UI）
  - エミュレーターのポート設定（Auth: 9099、Firestore: 8080、Storage: 9199、Pub/Sub: 8085、UI: 4000）
  - **成果物**: `firebase.json`、Firebase Emulator Suite
  - **検証方法**: `firebase emulators:start` で起動、http://localhost:4000 でUI確認
  - _Requirements: 9.1, 12.2_

- [x] 5.2 Docker Compose 環境構築（Colima + Docker）
  - **前提条件**: なし
  - Colima、Docker、Docker Compose のインストール（Homebrew）
  - Colima の初期設定（CPU 4、メモリ 8GB、ディスク 60GB）
  - `docker-compose.yml` の作成（Backend + Firebase Emulator）
  - `backend/Dockerfile.dev` の作成（Air によるホットリロード対応）
  - `.air.toml` の作成
  - **成果物**: `docker-compose.yml`, `backend/Dockerfile.dev`, `.air.toml`
  - **検証方法**: `colima start`, `docker compose up` で起動確認
  - _Requirements: 12.1, 12.12_

- [x] 5.3 環境変数設定
  - **前提条件**: タスク1.2, 1.3完了
  - Frontend `.env.local` の作成（API URL、エミュレーターホスト、NextAuth設定）
  - Backend `.env` の作成（エミュレーターホスト、GCP プロジェクトID）
  - 環境変数のドキュメント化（README への記載）
  - **成果物**: `frontend/.env.local`, `backend/.env`, `README.md`（環境変数セクション）
  - **検証方法**: `.env` ファイル読み込み確認、環境変数が正しく設定されている
  - _Requirements: 11.8_

- [x] 5.4 ローカル環境の起動確認
  - **前提条件**: タスク5.1, 5.2, 5.3完了
  - `colima start` でDocker環境起動
  - `docker compose up -d` でBackend + Emulator起動
  - `npm run dev` でFrontend起動（ホスト実行）
  - http://localhost:3000（Frontend）、http://localhost:8080/health（Backend）、http://localhost:4000（Emulator UI）の動作確認
  - HMR（Hot Module Replacement）の即時反映確認
  - **成果物**: 動作するローカル開発環境
  - **検証方法**: 各URLにアクセス、ホットリロード確認
  - _Requirements: 13.3_

- [ ] 5.5 (P) Cloud Vision API モックの実装
  - **前提条件**: タスク1.3完了
  - ローカル開発用 MockOCRService の実装
  - 環境変数による切り替え（`ENV=local` でモック使用）
  - モックレスポンスの実装（金額、日付、店舗名のダミーデータ）
  - **成果物**: `backend/internal/adapter/vision/mock_vision.go`
  - **検証方法**: ローカルでOCR処理のモックが動作する
  - **注意**: Phase 4まで延期可能（OCR機能実装時に必須）
  - _Requirements: 5.2, 12.4_

---

## Phase 0 完了基準

以下のすべてが満たされた場合、Phase 0完了とします：

1. **開発環境**: Frontend/Backendプロジェクトが初期化され、品質ゲートが通過する
2. **Terraform基盤**: Artifact Registry、サービスアカウント、Cloud Runが作成され、Terraformで管理されている
3. **CI/CD**: 品質ゲート、Firebase App Hosting、Cloud Runデプロイが動作する
4. **ローカル環境**: Firebase Emulator、Docker Composeでローカル開発が可能
5. **検証**: PR作成→品質ゲート通過→Cloud Runデプロイ成功→エンドポイント確認

---

## Phase 1: Hello World デプロイ

- [ ] 6. Frontend 最小実装とデプロイ
- [x] 6.1 (P) トップページ作成
  - `app/page.tsx` の実装（Hello World メッセージ）
  - ローカル環境での動作確認（`npm run dev`）
  - レスポンシブデザインの確認（モバイル、タブレット、デスクトップ）
  - _Requirements: 13.1, 13.2_

- [x] 6.2 Backend API 呼び出しの実装
  - Backend ヘルスチェック API 呼び出し
  - `fetch` による API リクエスト
  - ローディング状態の表示
  - エラーハンドリング
  - _Requirements: 10.3, 13.3_

- [x] 6.3 Firebase App Hosting へのデプロイ
  - **完了済み**: タスク3.2「Firebase App Hosting の GitHub 統合」で完了
  - GitHub統合により、PRプレビューと本番デプロイが自動化されています
  - 追加の手動デプロイ作業は不要です
  - _Requirements: 13.1, 15.10_

- [ ] 7. Backend 最小実装とデプロイ
- [x] 7.1 (P) ヘルスチェックエンドポイント実装
  - `GET /health` エンドポイント作成
  - レスポンス形式（JSON: status、version）
  - ローカル環境での動作確認（`go run cmd/api/main.go`）
  - **実装済み**: `backend/internal/adapter/http/health_handler.go`、`backend/cmd/api/main.go`で実装済み
  - _Requirements: 10.2, 10.3, 15.5_

- [x] 7.2 Echo サーバーの基本設定
  - Echo インスタンスの初期化
  - CORS ミドルウェアの設定
  - ロガーミドルウェアの設定
  - エラーハンドリングミドルウェアの設定
  - ポート設定（環境変数 `PORT` から取得、デフォルト 8080）
  - **実装状況**: 5項目すべて完了（CORS/Logger/カスタムHTTPエラーハンドラを main.go で実装）
  - _Requirements: 10.1, 11.6, 15.1_

- [x] 7.3 Dockerfile の作成
  - マルチステージビルド（ビルドステージ + ランタイムステージ）
  - distroless ベースイメージの使用（セキュリティ）
  - 最小限のレイヤー構成
  - **実装済み**: backend/Dockerfileが存在し、本番用マルチステージビルドが完成
  - _Requirements: 12.1, 16.1_

- [x] 7.4 Cloud Run へのデプロイ
  - Artifact Registry へのイメージプッシュ
  - Cloud Run サービス作成（Staging環境）
  - 環境変数の設定
  - デプロイ確認（`curl https://api-staging.example.com/health`）
  - **完了済み**: タスク4.1「Cloud Run デプロイワークフロー実装」でCI/CD自動化済み
  - _Requirements: 12.1, 12.7, 15.10_

- [ ] 8. エンドツーエンド統合確認
- [x] 8.1 ローカル環境での Frontend-Backend 統合
  - Frontend（localhost:3000）から Backend（localhost:8080）への API 呼び出し
  - CORS エラーの解消確認
  - レスポンスデータの表示確認
  - _Requirements: 10.3, 11.6_

- [x] 8.2 Staging 環境での Frontend-Backend 統合
  - Firebase App Hosting（Frontend）から Cloud Run（Backend）への API 呼び出し
  - HTTPS 通信の確認
  - レスポンスタイムの確認（< 1秒）
  - **確認手順**: `docs/staging-integration.md` に疎通手順と curl コマンドを記載（App Hosting 環境変数設定→フロント表示で「バックエンド: OK」確認→ `/health` を HTTPS で <1s チェック）
  - _Requirements: 11.3, 11.4, 20.1_

- [x] 8.3* E2E テストの初期実装
  - Playwright のセットアップ
  - Hello World ページの表示テスト
  - Backend API 呼び出しテスト
  - _Requirements: 15.10_

- [ ] 8.4 App Hosting 環境変数のTerraform管理
  - **前提条件**: タスク2.3完了（Terraformモジュール基盤）
  - Secret Manager モジュール作成（`terraform/modules/secret-manager/`）
  - Staging環境でSecret作成（`BACKEND_API_BASE_STAGING`）
  - App Hosting サービスアカウントへのIAM権限付与（`roles/secretmanager.secretAccessor`）
  - `apphosting.yaml` / `apphosting.staging.yaml` でSecret参照設定
  - **成果物**: 
    - `terraform/modules/secret-manager/` モジュール
    - Secret Manager に登録されたバックエンドURL
    - `apphosting.yaml` / `apphosting.staging.yaml`
  - **検証方法**:
    ```bash
    # Secret の確認
    gcloud secrets list --filter="name:BACKEND_API_BASE_STAGING"
    gcloud secrets versions access latest --secret="BACKEND_API_BASE_STAGING"
    
    # IAM権限の確認
    gcloud secrets get-iam-policy BACKEND_API_BASE_STAGING
    ```
  - **ドキュメント更新**: `docs/staging-integration.md` をSecret Manager使用方式に更新
  - _Requirements: 11.8, 17.5, 19.5_

## Phase 2: 認証機能実装

- [ ] 9. Google Cloud Identity Platform セットアップ
- [x] 9.1 Identity Platform の有効化
  - Terraform で Identity Platform リソース作成
  - Google プロバイダーの有効化
  - authorized_domains を `preview--ledger-muse.asia-east1.hosted.app`, `production--ledger-muse.asia-east1.hosted.app` で設定（staging 環境変数にて定義）
  - OAuth 2.0 クライアントは今後 IDP プロバイダ設定時に client_id/client_secret を tfvars で受け取る想定（現時点ではドメイン登録まで）
  - _Requirements: 1.1, 11.1, 17.1_

- [ ] 9.2 (P) Firebase Admin SDK のセットアップ（Backend）
  - Firebase Admin SDK のインストール
  - サービスアカウント認証の設定
  - ローカル環境でのエミュレーター接続確認
  - _Requirements: 1.1, 11.1_

- [ ] 10. Frontend 認証機能実装
- [ ] 10.1 NextAuth.js v5 のセットアップ
  - NextAuth.js v5 のインストール
  - `app/api/auth/[...nextauth]/route.ts` の作成
  - Google Provider の設定（クライアントID、シークレット）
  - Session Provider の設定
  - _Requirements: 1.1, 1.2_

- [ ] 10.2 ログインページの作成
  - `app/login/page.tsx` の実装
  - Google ログインボタンの配置
  - ログイン状態の確認
  - リダイレクト処理（ログイン成功時にダッシュボードへ）
  - _Requirements: 1.3, 13.1_

- [ ] 10.3 ログアウト機能の実装
  - ログアウトボタンの配置
  - NextAuth.js の `signOut` 関数呼び出し
  - ログイン画面へのリダイレクト
  - _Requirements: 1.5_

- [ ] 10.4 保護されたルートの作成
  - `app/dashboard/page.tsx` の作成（認証必須ページ）
  - ミドルウェアによる認証チェック（`middleware.ts`）
  - 未認証ユーザーのログインページへのリダイレクト
  - セッション情報の表示（ユーザー名、メールアドレス）
  - _Requirements: 1.3, 1.7, 11.2_

- [ ] 10.5 セッション管理の実装
  - セッションの自動更新設定
  - トークンリフレッシュロジック
  - セッション有効期限の設定
  - _Requirements: 1.7_

- [ ] 11. Backend JWT 検証ミドルウェア実装
- [ ] 11.1 JWT ミドルウェアの実装
  - Authorization ヘッダーからトークン抽出
  - Firebase Admin SDK による JWT 検証
  - トークン検証失敗時の 401 エラーレスポンス
  - ユーザーID の抽出と Context への設定
  - _Requirements: 1.3, 10.6, 11.1_

- [ ] 11.2 保護されたエンドポイントの作成\n  - `GET /api/v1/me` エンドポイント実装
  - JWT ミドルウェアの適用
  - ユーザー情報の返却（userId、email）
  - _Requirements: 1.3, 10.2, 11.2_

- [ ] 11.3 認証エラーハンドリング
  - 無効なトークンのエラーレスポンス（401）
  - トークン期限切れのエラーレスポンス（401）
  - エラーログの記録
  - _Requirements: 1.4, 10.5, 11.9_

- [ ] 12. 認証機能のテスト
- [ ] 12.1* Frontend 認証フローの Unit テスト
  - ログインコンポーネントのテスト
  - セッション状態管理のテスト
  - API クライアント（認証付き）のテスト
  - _Requirements: 1.2, 1.3_

- [ ] 12.2* Backend JWT ミドルウェアの Unit テスト
  - 有効なトークンの検証テスト
  - 無効なトークンの検証テスト
  - トークン欠落時のテスト
  - _Requirements: 1.3, 10.6_

- [ ] 12.3 認証フローの E2E テスト
  - ログインフローのテスト（Playwright）
  - ダッシュボードアクセステスト（認証必須）
  - ログアウトフローのテスト
  - 未認証ユーザーのリダイレクトテスト
  - _Requirements: 1.2, 1.3, 1.5, 15.10_

## Phase 3: 取引CRUD機能実装

- [ ] 13. Transaction ドメイン層実装（Backend）
- [ ] 13.1 (P) Transaction エンティティ定義
  - `internal/domain/transaction.go` の作成
  - Transaction 構造体の定義（ID、UserID、Amount、Type、CategoryID、Date、Description、CreatedAt、UpdatedAt）
  - バリデーションロジック（金額 > 0、Type は "income" または "expense"）
  - _Requirements: 2.1, 2.6_

- [ ] 13.2 (P) TransactionRepository Port の定義
  - `internal/port/transaction_repository.go` の作成
  - インターフェース定義（Create、FindByID、FindByUserID、Update、Delete、List）
  - ページネーション対応（Limit、Offset）
  - _Requirements: 2.2, 9.3_

- [ ] 13.3 TransactionService の実装
  - `internal/application/transaction_service.go` の作成
  - Create メソッド（バリデーション、Repository 呼び出し、変更履歴記録）
  - Update メソッド（変更履歴記録）
  - Delete メソッド（論理削除）
  - List メソッド（ユーザー単位のデータ隔離）
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.8_

- [ ] 14. Firestore Adapter 実装（Backend）
- [ ] 14.1 Firestore クライアント初期化
  - `internal/adapter/firestore/client.go` の作成
  - Firestore クライアントの初期化（環境変数による切り替え、エミュレーター対応）
  - エラーハンドリング
  - _Requirements: 9.1, 9.4_

- [ ] 14.2 TransactionRepository Adapter の実装
  - `internal/adapter/firestore/transaction_repository.go` の作成
  - `users/{userId}/transactions/{transactionId}` コレクション構造
  - Create メソッド（ドキュメント作成）
  - FindByID メソッド（ドキュメント取得）
  - FindByUserID メソッド（クエリ、新しい順ソート）
  - Update メソッド（ドキュメント更新）
  - Delete メソッド（論理削除フラグ設定）
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 9.1, 9.8_

- [ ] 14.3 Firestore トランザクション処理
  - トランザクション境界の実装
  - データ整合性の保証
  - エラー時のロールバック
  - _Requirements: 9.5_

- [ ] 15. Transaction API 実装（Backend）
- [ ] 15.1 Transaction ルーターの作成
  - `internal/adapter/http/transaction_handler.go` の作成
  - ルーティング定義（`POST /api/v1/transactions`, `GET /api/v1/transactions`, `GET /api/v1/transactions/:id`, `PUT /api/v1/transactions/:id`, `DELETE /api/v1/transactions/:id`）
  - JWT ミドルウェアの適用
  - _Requirements: 2.1, 2.2, 10.2, 10.6_

- [ ] 15.2 CreateTransaction エンドポイント実装
  - リクエストボディのパース
  - バリデーション（必須項目チェック）
  - TransactionService 呼び出し
  - レスポンス返却（201 Created）
  - _Requirements: 2.1, 2.5, 10.4_

- [ ] 15.3 GetTransactions エンドポイント実装
  - クエリパラメータ取得（page、limit、sort）
  - ユーザーID によるフィルタリング
  - TransactionService 呼び出し
  - レスポンス返却（200 OK）
  - _Requirements: 2.2, 2.8, 10.4_

- [ ] 15.4 UpdateTransaction エンドポイント実装
  - パスパラメータ取得（transactionId）
  - リクエストボディのパース
  - ユーザー権限チェック（自分の取引のみ更新可能）
  - TransactionService 呼び出し
  - レスポンス返却（200 OK）
  - _Requirements: 2.3, 11.2, 10.4_

- [ ] 15.5 DeleteTransaction エンドポイント実装
  - パスパラメータ取得（transactionId）
  - ユーザー権限チェック
  - TransactionService 呼び出し（論理削除）
  - レスポンス返却（204 No Content）
  - _Requirements: 2.4, 11.2, 10.4_

- [ ] 15.6 (P) API ログ記録の実装
  - リクエスト/レスポンスログの記録
  - エラーログの記録
  - 構造化ログ（JSON 形式）
  - _Requirements: 10.8, 15.1, 15.2_

- [ ] 16. Category ドメイン実装（Backend）
- [ ] 16.1 (P) Category エンティティ定義
  - `internal/domain/category.go` の作成
  - Category 構造体（ID、UserID、Name、Type、Color、CreatedAt、UpdatedAt）
  - _Requirements: 3.1, 3.5_

- [ ] 16.2 (P) CategoryRepository Port と Adapter の実装
  - `internal/port/category_repository.go` の作成
  - Firestore Adapter（`users/{userId}/categories/{categoryId}`）
  - CRUD メソッド実装
  - _Requirements: 3.1, 3.2, 9.1_

- [ ] 16.3 CategoryService の実装
  - `internal/application/category_service.go` の作成
  - Create、Update、Delete メソッド
  - Delete 時の使用チェック（TransactionRepository 参照）
  - デフォルトカテゴリの初期登録ロジック
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.6_

- [ ] 16.4 Category API 実装
  - `internal/adapter/http/category_handler.go` の作成
  - `POST /api/v1/categories`, `GET /api/v1/categories`, `PUT /api/v1/categories/:id`, `DELETE /api/v1/categories/:id`
  - JWT ミドルウェア適用
  - _Requirements: 3.1, 3.2, 3.3, 10.2_

- [ ] 17. Frontend 取引管理 UI 実装
- [ ] 17.1 取引一覧ページの作成
  - `app/transactions/page.tsx` の実装
  - API クライアント（`lib/api/transactions.ts`）の作成
  - 取引一覧の表示（テーブル形式）
  - ページネーション機能
  - ローディングインジケーター
  - _Requirements: 2.2, 13.1, 13.5_

- [ ] 17.2 取引作成フォームの実装
  - `app/transactions/new/page.tsx` の作成
  - フォーム入力（日付、金額、カテゴリ、タイプ、メモ）
  - リアルタイムバリデーション
  - 送信処理（API POST リクエスト）
  - 成功時のリダイレクト
  - _Requirements: 2.1, 2.5, 13.8_

- [ ] 17.3 取引編集フォームの実装
  - `app/transactions/[id]/edit/page.tsx` の作成
  - 既存データの取得と表示
  - 更新処理（API PUT リクエスト）
  - _Requirements: 2.3, 13.8_

- [ ] 17.4 取引削除機能の実装
  - 削除確認ダイアログ
  - 削除処理（API DELETE リクエスト）
  - 一覧ページへのリダイレクト
  - _Requirements: 2.4, 13.6_

- [ ] 17.5 カテゴリ管理 UI の実装
  - `app/categories/page.tsx` の作成
  - カテゴリ一覧表示
  - カテゴリ作成/編集フォーム
  - カテゴリ削除（使用チェック付き）
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 18. 取引機能のテスト
- [ ] 18.1* Backend Unit テスト
  - TransactionService のテスト（バリデーション、CRUD ロジック）
  - CategoryService のテスト
  - Firestore Adapter のテスト（エミュレーター使用）
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2_

- [ ] 18.2* Frontend Unit テスト
  - API クライアントのテスト（モック）
  - フォームコンポーネントのテスト
  - _Requirements: 2.1, 13.8_

- [ ] 18.3 取引 CRUD の E2E テスト
  - 取引作成フロー（Playwright）
  - 取引一覧表示
  - 取引編集フロー
  - 取引削除フロー
  - データ隔離の確認（他ユーザーの取引が表示されないこと）
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.8, 15.10_

## Phase 4: レシートOCR機能実装

- [ ] 19. Cloud Storage セットアップ
- [ ] 19.1 Cloud Storage バケット作成
  - Terraform で Storage バケット作成
  - バケット名設定（`{project-id}-receipts`）
  - ライフサイクルポリシー設定（古い画像の自動削除）
  - サーバー側暗号化の有効化
  - _Requirements: 12.2, 19.2, 21.6_

- [ ] 19.2 (P) IAM 権限設定
  - バックエンドサービスアカウントへの Storage 書き込み権限付与
  - オブジェクトレベルのアクセス制御（ユーザー単位の隔離）
  - _Requirements: 11.2, 12.2_

- [ ] 20. Receipt ドメイン実装（Backend）
- [ ] 20.1 (P) Receipt エンティティ定義
  - `internal/domain/receipt.go` の作成
  - Receipt 構造体（ID、UserID、ImageURL、Status、OCRResult、UploadedAt、ProcessedAt）
  - Status 列挙型（Pending、Processing、Completed、Failed）
  - _Requirements: 4.2, 5.3_

- [ ] 20.2 (P) ReceiptRepository Port と Adapter の実装
  - `internal/port/receipt_repository.go` の作成
  - Firestore Adapter（`receipts/{receiptId}`）
  - CRUD メソッド、ステータス更新メソッド
  - _Requirements: 4.2, 5.3, 9.1_

- [ ] 21. Cloud Storage Adapter 実装（Backend）
- [ ] 21.1 (P) ImageStorage Port の定義
  - `internal/port/image_storage.go` の作成
  - インターフェース（Upload、GetURL、Delete）
  - _Requirements: 4.1, 12.2_

- [ ] 21.2 CloudStorageAdapter の実装
  - `internal/adapter/storage/cloud_storage.go` の作成
  - Upload メソッド（ファイルアップロード、署名付きURL生成）
  - GetURL メソッド（画像URL取得）
  - Delete メソッド（画像削除）
  - エミュレーター対応
  - _Requirements: 4.1, 4.2, 12.2_

- [ ] 22. Receipt アップロード API 実装（Backend）
- [ ] 22.1 ReceiptService の実装
  - `internal/application/receipt_service.go` の作成
  - Upload メソッド（画像検証、Storage アップロード、Receipt 作成、Pub/Sub イベント発行）
  - GetReceipt メソッド
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 22.2 ファイルアップロードバリデーション
  - ファイル形式チェック（JPEG、PNG、HEIC）
  - ファイルサイズチェック（最大 10MB）
  - エラーレスポンス（400 Bad Request）
  - _Requirements: 4.4, 4.5, 4.6_

- [ ] 22.3 Receipt アップロードエンドポイント実装
  - `POST /api/v1/receipts/upload`（multipart/form-data）
  - ファイルのパース
  - ReceiptService 呼び出し
  - レスポンス返却（Receipt オブジェクト、status: pending）
  - _Requirements: 4.1, 4.2, 10.3_

- [ ] 22.4 Receipt 取得エンドポイント実装
  - `GET /api/v1/receipts/:id`
  - `GET /api/v1/receipts`（ユーザー単位の一覧）
  - _Requirements: 4.7, 4.8_

- [ ] 23. Pub/Sub と Cloud Tasks セットアップ
- [ ] 23.1 Pub/Sub トピックとサブスクリプション作成
  - Terraform で Pub/Sub トピック作成（`receipt-uploaded`）
  - サブスクリプション作成（Cloud Tasks エンドポイントへのプッシュ）
  - _Requirements: 12.5, 18.1, 18.2_

- [ ] 23.2 Cloud Tasks キュー作成
  - Terraform で Cloud Tasks キュー作成
  - レート制限設定（Vision API クォータ対策）
  - リトライポリシー設定（最大3回）
  - デッドレターキュー設定
  - _Requirements: 12.6, 18.4, 18.5_

- [ ] 23.3 (P) PubSubAdapter の実装
  - `internal/adapter/pubsub/publisher.go` の作成
  - Publish メソッド（イベント発行）
  - エミュレーター対応
  - _Requirements: 12.5, 18.1, 18.2_

- [ ] 24. Cloud Vision Adapter 実装（Backend）
- [ ] 24.1 (P) OCRService Port の定義
  - `internal/port/ocr_service.go` の作成
  - インターフェース（ExtractText）
  - _Requirements: 5.2, 12.4_

- [ ] 24.2 CloudVisionAdapter の実装
  - `internal/adapter/vision/cloud_vision.go` の作成
  - DOCUMENT_TEXT_DETECTION の使用
  - テキスト抽出、金額・日付・店舗名のパース
  - 信頼度スコアの記録
  - エラーハンドリング
  - _Requirements: 5.2, 5.8, 5.9, 12.4_

- [ ] 24.3 OCR 結果パース処理
  - 金額抽出ロジック（通貨記号、数値パターンマッチング）
  - 日付抽出ロジック（日付フォーマットパターンマッチング）
  - 店舗名抽出ロジック（トップテキストブロック）
  - 複数金額検出時の合計金額選択
  - _Requirements: 5.3, 5.9_

- [ ] 25. OCR Worker 実装（Backend）
- [ ] 25.1 OCR Worker エンドポイント実装
  - `POST /api/v1/workers/ocr`（Cloud Tasks からの呼び出し）
  - リクエスト認証（Cloud Tasks 専用トークン検証）
  - _Requirements: 5.1, 18.3_

- [ ] 25.2 OCR 処理ロジック実装
  - Cloud Storage から画像取得
  - Cloud Vision API 呼び出し
  - OCR 結果パース
  - Firestore へ結果保存（Receipt ステータス更新）
  - 処理時間計測（30秒以内目標）
  - _Requirements: 5.2, 5.3, 5.10_

- [ ] 25.3 OCR Worker の冪等性実装
  - receiptId による重複処理チェック
  - ステータス確認（Processing 中は処理スキップ）
  - _Requirements: 18.4_

- [ ] 25.4 OCR エラーハンドリング
  - OCR 失敗時のログ記録
  - Receipt ステータス更新（Failed）
  - リトライロジック（Cloud Tasks 任せ）
  - デッドレターキュー移動（3回失敗後）
  - _Requirements: 5.5, 18.4, 18.5_

- [ ] 26. Frontend レシート機能 UI 実装
- [ ] 26.1 レシート画像アップロードフォーム作成
  - ファイル選択 UI
  - ドラッグ&ドロップ対応
  - プレビュー表示
  - アップロードボタン
  - _Requirements: 4.1, 13.1_

- [ ] 26.2 OCR 処理状態の表示
  - アップロード中インジケーター
  - OCR 処理中インジケーター
  - 処理完了通知
  - エラーメッセージ表示
  - _Requirements: 4.2, 5.4, 5.5, 5.6_

- [ ] 26.3 OCR 結果の取引フォーム自動入力
  - OCR 結果取得（ポーリング or WebSocket）
  - 取引フォームへの自動入力（金額、日付、店舗名）
  - ユーザーによる確認・修正 UI
  - _Requirements: 5.4, 5.7_

- [ ] 26.4 レシート画像表示機能
  - サムネイル表示（取引詳細ページ）
  - フルサイズ画像表示（モーダル）
  - _Requirements: 4.7, 4.8_

- [ ] 27. レシート OCR 機能のテスト
- [ ] 27.1* Backend Unit テスト
  - ReceiptService のテスト
  - CloudStorageAdapter のテスト（モック）
  - CloudVisionAdapter のテスト（モック）
  - OCR Worker のテスト（モック）
  - _Requirements: 4.1, 5.2_

- [ ] 27.2 OCR 処理の統合テスト
  - Pub/Sub → Cloud Tasks → OCR Worker のフロー
  - エミュレーター環境でのエンドツーエンドテスト
  - _Requirements: 5.1, 5.2, 5.3, 18.1, 18.2_

- [ ] 27.3 レシートアップロード E2E テスト
  - ファイルアップロード（Playwright）
  - OCR 処理完了待機
  - 取引フォーム自動入力確認
  - _Requirements: 4.1, 4.2, 5.4, 15.10_

## Phase 5: ナレッジ機能（メモ・タグ）実装

- [ ] 28. Memo ドメイン実装（Backend）
- [ ] 28.1 (P) Memo エンティティ定義
  - `internal/domain/memo.go` の作成
  - Memo 構造体（ID、UserID、TransactionID、Content、Tags、CreatedAt、UpdatedAt）
  - 文字数制限バリデーション（最大 5000 文字）
  - _Requirements: 6.1, 6.6_

- [ ] 28.2 (P) MemoRepository Port と Adapter の実装
  - `internal/port/memo_repository.go` の作成
  - Firestore Adapter（`users/{userId}/memos/{memoId}`）
  - CRUD メソッド、タグ検索メソッド
  - _Requirements: 6.1, 6.7, 9.1_

- [ ] 28.3 KnowledgeService の実装
  - `internal/application/knowledge_service.go` の作成
  - CreateMemo、UpdateMemo、DeleteMemo メソッド
  - 編集履歴タイムスタンプ記録
  - _Requirements: 6.1, 6.5_

- [ ] 28.4 Memo API 実装
  - `POST /api/v1/transactions/:id/memos`
  - `GET /api/v1/transactions/:id/memos`
  - `PUT /api/v1/memos/:id`
  - `DELETE /api/v1/memos/:id`
  - JWT ミドルウェア適用
  - _Requirements: 6.1, 10.2_

- [ ] 29. Frontend ナレッジ UI 実装
- [ ] 29.1 メモ追加フォームの作成
  - 取引詳細ページ内のメモフォーム
  - Markdown エディタ統合
  - プレビュー機能
  - _Requirements: 6.1, 6.4_

- [ ] 29.2 メモ表示機能の実装
  - メモアイコン表示（取引一覧）
  - メモポップアップ表示
  - Markdown レンダリング
  - _Requirements: 6.2, 6.3, 6.4_

- [ ] 29.3 タグ入力機能の実装
  - タグ入力コンポーネント
  - 自動補完（既存タグ候補）
  - タグ削除機能
  - _Requirements: 6.7_

- [ ] 29.4 XSS 対策の実装
  - DOMPurify によるサニタイズ処理
  - Markdown レンダリング時のエスケープ
  - _Requirements: 11.8_

- [ ] 30. ナレッジ機能のテスト
- [ ] 30.1* Backend Unit テスト
  - KnowledgeService のテスト
  - MemoRepository のテスト
  - _Requirements: 6.1, 6.5_

- [ ] 30.2* Frontend Unit テスト
  - メモコンポーネントのテスト
  - XSS 対策のテスト
  - _Requirements: 6.1, 6.4_

- [ ] 30.3 メモ機能の E2E テスト
  - メモ追加フロー（Playwright）
  - Markdown プレビュー確認
  - タグ付けフロー
  - _Requirements: 6.1, 6.4, 6.7, 15.10_

## Phase 6: 検索・レポート機能実装

- [ ] 31. 検索機能実装（Backend）
- [ ] 31.1 SearchService の実装
  - `internal/application/search_service.go` の作成
  - 全文検索ロジック（Firestore クエリ + アプリケーション層フィルタリング）
  - 日付範囲フィルタ
  - カテゴリフィルタ
  - タグフィルタ
  - _Requirements: 7.1, 7.3, 7.4, 7.6_

- [ ] 31.2 検索 API 実装
  - `GET /api/v1/transactions/search`（クエリパラメータ: q、from、to、category、tags）
  - ハイライト情報の返却
  - _Requirements: 7.1, 7.2_

- [ ] 32. レポート機能実装（Backend）
- [ ] 32.1 ReportService の実装
  - `internal/application/report_service.go` の作成
  - 集計ロジック（期間別、カテゴリ別）
  - 月次・週次・年次集計
  - 前月比較データ生成
  - _Requirements: 8.1, 8.2, 8.3, 8.6_

- [ ] 32.2 レポート API 実装
  - `GET /api/v1/reports/summary`（クエリパラメータ: from、to、groupBy）
  - CSV エクスポート機能
  - _Requirements: 8.1, 8.7_

- [ ] 33. Frontend 検索・レポート UI 実装
- [ ] 33.1 検索フォームの作成
  - 検索キーワード入力
  - 日付範囲選択
  - カテゴリフィルタ
  - タグフィルタ
  - _Requirements: 7.1, 7.3, 7.4_

- [ ] 33.2 検索結果表示の実装
  - 検索結果一覧
  - マッチ箇所のハイライト表示
  - 現在のフィルタ条件表示
  - 結果 0 件時のメッセージ
  - _Requirements: 7.2, 7.5, 7.7_

- [ ] 33.3 ダッシュボードの作成
  - `app/dashboard/page.tsx` の更新
  - 当月の収入・支出・残高表示
  - カテゴリ別支出グラフ（円グラフ）
  - 月次推移グラフ（折れ線グラフ）
  - グラフクリックでドリルダウン
  - _Requirements: 8.1, 8.2, 8.4, 8.5_

- [ ] 33.4 レポートエクスポート機能の実装
  - CSV ダウンロードボタン
  - エクスポート処理
  - _Requirements: 8.7_

- [ ] 34. 検索・レポート機能のテスト
- [ ] 34.1* Backend Unit テスト
  - SearchService のテスト
  - ReportService のテスト
  - _Requirements: 7.1, 8.1_

- [ ] 34.2* Frontend Unit テスト
  - 検索フォームのテスト
  - グラフコンポーネントのテスト
  - _Requirements: 7.1, 8.4_

- [ ] 34.3 検索機能の E2E テスト
  - 検索フロー（Playwright）
  - フィルタ適用
  - ハイライト表示確認
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 15.10_

- [ ] 34.4 レポート機能の E2E テスト
  - ダッシュボード表示
  - グラフドリルダウン
  - CSV エクスポート
  - _Requirements: 8.1, 8.4, 8.5, 8.7, 15.10_

## Phase 7: 運用・監視機能実装

- [ ] 35. ログ・監視機能実装（Backend）
- [ ] 35.1 構造化ログの実装
  - JSON 形式のログ出力
  - ログレベル設定（INFO、WARN、ERROR）
  - 機密情報マスキング
  - _Requirements: 11.8, 15.1, 15.2, 19.5_

- [ ] 35.2 Cloud Monitoring 統合
  - メトリクス収集（API レスポンスタイム、エラーレート、リクエスト数）
  - カスタムメトリクス定義
  - _Requirements: 12.8, 15.3_

- [ ] 35.3 Cloud Trace 統合
  - 分散トレーシングの実装
  - トレースコンテキスト伝播
  - _Requirements: 12.10, 15.8_

- [ ] 35.4 アラート設定
  - API レスポンスタイム > 3 秒でアラート
  - エラーレート > 1% でアラート
  - コスト > 予算でアラート
  - _Requirements: 15.4, 21.4_

- [ ] 36. セキュリティ強化
- [ ] 36.1 HTTPS 強制の実装
  - Cloud Run での HTTPS 設定
  - HTTP → HTTPS リダイレクト
  - _Requirements: 11.3, 11.4_

- [ ] 36.2 データ暗号化の確認
  - TLS 1.3 設定確認
  - Cloud Storage サーバー側暗号化確認
  - Firestore 暗号化確認
  - _Requirements: 19.1, 19.2, 19.3_

- [ ] 36.3 (P) Cloud KMS セットアップ
  - Terraform で KMS キーリング作成
  - 暗号鍵作成
  - 鍵ローテーションポリシー設定
  - _Requirements: 19.4, 19.6_

- [ ] 36.4 レート制限の実装
  - アップロードエンドポイントのレート制限（10回/時間）
  - API レート制限（将来対応の準備）
  - _Requirements: 14.4_

- [ ] 36.5 アカウントロック機能の実装
  - ログイン失敗回数カウント
  - 5回連続失敗でアカウントロック
  - _Requirements: 11.7_

- [ ] 37. パフォーマンス最適化
- [ ] 37.1 API パフォーマンステスト
  - JMeter または Locust によるロードテスト
  - 95 パーセンタイル < 1 秒の確認
  - _Requirements: 20.1_

- [ ] 37.2 OCR 処理パフォーマンステスト
  - OCR 処理時間計測
  - 平均 < 15 秒、最大 < 30 秒の確認
  - _Requirements: 5.10, 20.2_

- [ ] 37.3 Frontend パフォーマンステスト
  - Lighthouse スコア計測
  - LCP < 2.5 秒の確認
  - _Requirements: 20.3_

- [ ] 38. Production 環境セットアップ
- [ ] 38.1 Production 環境の Terraform 定義
  - `terraform/environments/prod/main.tf` の作成
  - Production 固有変数（`prod.tfvars`）
  - 本番用リソース設定（スケーリング、冗長性）
  - _Requirements: 12.12, 17.2_

- [ ] 38.2 Production デプロイパイプライン構築
  - GitHub Actions ワークフロー（`.github/workflows/deploy-production.yml`）
  - 手動承認ゲート
  - ブルー/グリーンデプロイ（または Canary）
  - _Requirements: 15.10_

- [ ] 38.3 Production 環境へのデプロイ
  - Staging で最終確認
  - Production デプロイ実行
  - 動作確認
  - ロールバック手順の確認
  - _Requirements: 12.12, 17.7_

## 次のステップ

実装完了後:
1. 各フェーズの成功基準を確認
2. すべてのテストがパスすることを確認
3. Staging 環境で統合テストを実施
4. Production 環境へのデプロイを実施
5. 本番運用開始
