# Project Structure

## Organization Philosophy

- フロント/API/インフラを分離し、それぞれでドメイン単位のモジュール化を志向(feature-first UI、レイヤード API、モジュール化された IaC)
- 非同期処理(アップロード→Pub/Sub→OCRワーカー)を独立させ、可用性とスケールを確保
- ドキュメントとスペックはコードと並行管理し、実装判断の背景を残す
- 最小スケルトン(Next.js App Router + Echo ヘルスチェック)を先行接地し、同じ構造でボリューム増にも耐えることを優先

## Directory Patterns

### Frontend App
**Location**: `/frontend`  
**Purpose**: Next.js による UI。ドメイン(auth/receipts/ledger/knowledge 等)ごとに feature-first でコンポーネント・hooks・型をまとめる。  
**Current**: App Router 採用。`frontend/app/{layout.tsx,page.tsx}` でルートを構成し、`frontend/app/page.test.tsx` でスモークテスト。`@/*` エイリアスはアプリルート。  
**Example**: `/frontend/features/receipts/{components,hooks,services}` のようにドメイン配下で自己完結し、ルート側(`frontend/app/receipts/page.tsx`)は薄いハンドオフに留める。

### API Service
**Location**: `/backend`  
**Purpose**: Go + Echo。`cmd/api` がエントリポイント、`internal/{adapter,http,application,domain,port}` へ分離。ハンドラは薄く、service 層に業務ロジック、repository 層で GCP リソース(Firestore/Storage 等)を抽象化。  
**Example**: `/backend/internal/{domain,application,adapter/http}/health` が `pkg/version` を経由してバージョン付きヘルスレスポンスを返す。新規エンドポイントも port interface で依存方向を内向きに固定する。

### Async Workers (planned)
**Location**: `/backend/internal/worker` など(未作成)  
**Purpose**: Pub/Sub/Cloud Tasks からの OCR ジョブを処理し、明細を更新する単機能ワーカー。  
**Example**: `/backend/internal/worker/ocr` にジョブハンドラを集約。

### Infrastructure as Code
**Location**: `/terraform`  
**Purpose**: 環境別(dev/stg/prod)ワークスペースとモジュール分割(identity, firestore, storage, pubsub, tasks, monitoring, ci)。  
**Current**: モジュールが進行中。`terraform/apphosting` で Firebase App Hosting デプロイ用の SA + 付与ロールを管理、`terraform/wif` で GitHub OIDC (Workload Identity Pool/Provider) とデプロイ SA のロール付与（`roles/run.admin`, `roles/artifactregistry.writer`, `roles/iam.serviceAccountUser` など）を定義。tfvars.example で入力例を提示。tfstate はローカルに置かれており、環境分離・remote state 設計を次ステップで行う前提。  
**Example**: `terraform/wif` の provider/pool/provider を増やしつつ、workspace 単位で remote state と backend を揃え、各サービスモジュール(storage/pubsub 等)を再利用する。

### Quality Guardrails & CI
**Location**: `/tests`（bash ガードレール）  
**Purpose**: CI 定義や主要スクリプトの存在・設定を lint 的に確認する。`tests/ci.test.sh` は `.github/workflows/ci.yml` の jobs/path-filter/言語バージョン(Node20, Go1.23)・ firebase.json を検証。`frontend.test.sh` / `backend.test.sh` は依存と主要コマンドをチェック。  
**Pattern**: 新規ワークフローや主要スクリプトを追加したら対応するガードレールをこのディレクトリに追加する。

### Docs & Specs
**Location**: `/docs`, `/.kiro/specs/household-finance-app`  
**Purpose**: 要件・設計・タスクのソース。実装判断やパターン化の根拠を保持。

## Naming Conventions

- **Files**: Reactコンポーネントは PascalCase、ルート/ユーティリティは kebab-case。Go パッケージは lower_snake、Terraform モジュールは kebab-case。
- **Components/Structs**: React/Go ともに PascalCase。
- **Functions**: TypeScript は camelCase、Go は MixedCase(外部公開時)/ lowerCamel(内部)。
- **Configs/Env**: `.env.*` は環境別、秘密は Secret Manager 側で管理(コード同梱禁止)。
- **Routes**: App Router のルートディレクトリはケバブケース、ページコンポーネントは PascalCase のままエクスポート。

## Import Organization

```typescript
import { ReceiptList } from '@/features/receipts/components/ReceiptList'; // 絶対パス(エイリアスは app ルートに設定済み)
import { useReceiptForm } from './hooks/useReceiptForm'; // 同一ドメイン内は相対で閉じる
```

**Path Aliases**: `@/` をフロントエンドのアプリルートに張る想定(scaffold 時に設定)。

## Code Organization Principles

- UI はドメイン単位で自己完結(components/hooks/types/services を近接配置)し、cross-domain 依存を最小化。App Router はページを薄く保ち feature モジュールに処理を委譲。
- API は handler( Echo ) → service → repository の依存方向を一方向に保ち、`internal/{adapter,http}` と `internal/{application,domain}` を分離。GCP クライアントは repository 内に閉じ込める。
- 非同期処理はイベント駆動(Pub/Sub/Tasks)で疎結合化し、リトライや遅延を吸収。
- インフラは環境分離と最小権限 IAM を前提に、モジュール再利用と remote state で一貫性を確保。
- 新規ディレクトリやモジュールは既存パターン(feature-first UI、レイヤード API、モジュール化 IaC)に従えば steering 更新不要。

updated_at: 2025-11-19
