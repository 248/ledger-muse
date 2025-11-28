# Technology Stack

## Architecture

- フロント（Next.js/TypeScript）＋ API（Go/Echo）＋ 非同期 OCR パイプライン（Pub/Sub + Cloud Tasks 想定）を GCP 上で構成
- インフラは Terraform で環境分離（dev/stg/prod想定）とリモートステート管理を行う方針
- 認証は Identity Platform、データは Firestore（初期）→将来 Cloud SQL 等へ移行可能な設計を考慮
- 現状はモノレポの土台として Next.js App Router + Tailwind と Echo ベースのヘルスチェック API を先行実装

## Core Technologies

- **Language**: TypeScript（フロント）, Go（バックエンド）
- **Framework**: Next.js, Echo
- **Runtime**: Node.js（LTS 想定）, Go（安定版）

## Current Implementation Snapshot (2025-11)

- フロント: Next.js 15 (App Router) + React 18 + Tailwind。TS `strict` 有効、`@/*` パスエイリアスを `tsconfig.json` で定義。Vitest + RTL + JSDOM を `frontend/test/setup.ts` 経由でセットアップ。
- バックエンド: Go 1.24 (go.mod) + Echo 4.11。`cmd/api` でブートし、`internal/{adapter/http,application,domain,port}` に層分離。ヘルスチェックは `pkg/version` から注入したバージョンを返すサービス経由で実装（CI は go 1.23 runner のままなので要アライン）。
- インフラ: Terraform 1.9 系 root (`terraform/backend.tf`) が GCS リモートステートを前提に `prefix = {global,wif,environments/<env>}` を切り替え、`terraform/bootstrap` が `${project}-terraform-state` バケット＋ state 管理 IAM を作成。`terraform/environments/{staging,prod}` で Artifact Registry → Backend API SA → Cloud Run を `modules/{artifact-registry,iam,cloud-run,storage}` へ接続し、`apphosting` / `iam-runner` / `wif` で各デプロイ用 SA・WIF 設定を個別管理。
- テスト/ガードレール: `/tests/*.sh` で最低限の構成・依存・スクリプトを検証（CI 定義や firebase 設定も含む）。新規追加時もスクリプトや主要依存をここに反映させる。
- CI/CD: `.github/workflows/ci.yml` が `paths-filter` で frontend/backend を判定し、Node 20 / Go 1.23 runner（go.mod は 1.24）で lint/type-check/test/build/coverage を実行。バックエンドは Artifact Registry へビルド・Push → Cloud Run へ preview/staging/production デプロイを WIF 認証で行い、ヘルスチェックまで自動化し、PR クローズ時は `cleanup-preview.yml` で Cloud Run プレビューと Artifact Registry イメージを削除。フロントのデプロイは Firebase App Hosting 連携に委譲。

## Key Libraries / Services

- Google Cloud: Identity Platform, Cloud Storage, Firestore, Cloud Vision API, Pub/Sub, Cloud Tasks, Cloud Build/Monitoring, Artifact Registry
- Firebase: App Hosting（フロントのホスティング）
- IaC: Terraform（モジュール化と環境別ワークスペースを前提、WIF/OIDC を用いた GitHub Actions からの権限移譲）

## Development Standards

### Type Safety
- TypeScript は strict 前提で any を極力禁止。型検証は `npm run type-check`（tsc --noEmit）を基準に実施
- Go は静的型を活用し、コンテキスト渡しを徹底

### Code Quality
- フロント: Next.js lint (`eslint-config-next`) + Prettier を npm script で常時実行し、Vitest/RTL で UI スモークを担保。
- バックエンド: `.golangci.yml` で govet/staticcheck/revive/errcheck などを有効化し、CI では `golangci-lint` に加えて `go test -v -race -coverprofile` → `go tool cover` を必須化。
- セキュリティ: IAM 最小権限、TLS 前提、秘密情報のコード同梱禁止
- CI: GitHub Actions `CI/CD Pipeline` が main/develop の push/pr 時に発火し、paths-filter で frontend/backend を判定。Node 20 / Go 1.23 を前提に lint, type-check, test, build, coverage を実行（フロントは Firebase App Hosting 連携でデプロイ別管理、バックエンドのデプロイは今後 Cloud Run 予定）。

### Testing
- フロント: Vitest/React Testing Library で App Router ページのスモークを維持
- バックエンド: go test（`-race -cover`）でユニット＋ハンドラ分離テストを実行
- CI: Cloud Build での追加自動化を将来検討しつつ、GitHub Actions での品質ゲートを先行運用

## Development Environment

### Required Tools
- Node.js（LTS）, Go（安定版）, Terraform, gcloud CLI

### Local Development
- `docker compose up -d --build` で backend + Firebase Emulator Suite(auth/firestore/storage/pubsub/ui) を起動し、backend は `air` によるホットリロードで `/backend` をマウントして再ビルド
- frontend はホストで `npm install && npm run dev` を実行し、`.env.local.example` / `backend/.env.example` をコピーして emulator 接続設定を有効化
- Colima 利用時はプロジェクトパスを `--mount <path>:w` で書き込みマウントしてファイル変更を伝搬させる

### Terraform Workflow
1. `terraform/bootstrap`（>=1.6）で `${project}-terraform-state` バケットと state 管理 IAM を作成。
2. `common.auto.tfvars` に `project_id` / `region` を集約し、各 root (`terraform`, `terraform/environments/<env>`, `terraform/wif`, `terraform/apphosting`, `terraform/iam-runner`) へ共有。
3. 各 root では `terraform -chdir=<dir> init -backend-config="bucket=${PROJECT_ID}-terraform-state"` → `plan/apply -var-file=<relative common.auto.tfvars>` の順で GCS backend に接続して実行。

### Common Commands
```bash
# frontend
npm run dev         # Next.js 開発サーバ
npm run lint        # Next.js lint
npm run type-check  # tsc --noEmit
npm run test        # vitest run

# backend
go run ./cmd/api    # Echo API を起動
go test ./...       # バックエンドのユニット/ハンドラ層テスト

# infra (GCS backend)
terraform -chdir=terraform/bootstrap plan -var-file=terraform.tfvars
terraform -chdir=terraform/environments/staging plan -var-file=../../common.auto.tfvars
```

## Key Technical Decisions

- GCP マネージドサービスを優先し、運用コストを抑えつつ将来の拡張性を確保
- 非同期パイプラインでアップロードと OCR を疎結合化し、遅延吸収と拡張を容易にする
- 環境分離と最小権限設計を前提に、商用化に向けたセキュリティと監視を初期から考慮

updated_at: 2025-11-27
