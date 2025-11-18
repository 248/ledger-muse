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
- バックエンド: Go 1.23 + Echo 4.11。`cmd/api` でブートし、`internal/{adapter/http,application,domain,port}` に層分離。ヘルスチェックは `pkg/version` から注入したバージョンを返すサービス経由で実装。
- テスト/ガードレール: `/tests/*.sh` で最低限の構成・依存・スクリプトを検証。新規追加時もスクリプトや主要依存をここに反映させる。

## Key Libraries / Services

- Google Cloud: Identity Platform, Cloud Storage, Firestore, Cloud Vision API, Pub/Sub, Cloud Tasks, Cloud Build/Monitoring, Artifact Registry
- IaC: Terraform（モジュール化と環境別ワークスペースを前提）

## Development Standards

### Type Safety
- TypeScript は strict 前提で any を極力禁止
- Go は静的型を活用し、コンテキスト渡しを徹底

### Code Quality
- フロント: ESLint + Prettier を採用予定
- バックエンド: gofmt / go vet を最低限実行
- セキュリティ: IAM 最小権限、TLS 前提、秘密情報のコード同梱禁止

### Testing
- フロント: Vitest/React Testing Library を想定
- バックエンド: go test でユニット＋ハンドラ分離テスト
- CI: Cloud Build でテスト・lint を将来自動化

## Development Environment

### Required Tools
- Node.js（LTS）, Go（安定版）, Terraform, gcloud CLI

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

# infra (予定)
terraform fmt && terraform plan  # 環境別 workspace 前提で実行
```

## Key Technical Decisions

- GCP マネージドサービスを優先し、運用コストを抑えつつ将来の拡張性を確保
- 非同期パイプラインでアップロードと OCR を疎結合化し、遅延吸収と拡張を容易にする
- 環境分離と最小権限設計を前提に、商用化に向けたセキュリティと監視を初期から考慮

updated_at: 2025-11-18
