# ブランチ戦略 & プルリクエスト計画

## 📋 目次

- [設計原則](#設計原則)
- [PR一覧](#pr一覧)
- [Phase別実装計画](#phase別実装計画)
- [並列実行グループ](#並列実行グループ)
- [依存関係グラフ](#依存関係グラフ)
- [リスクと注意事項](#リスクと注意事項)
- [推奨ワークフロー](#推奨ワークフロー)

---

## 設計原則

### 1. レビューサイズ

- **Small**: < 300 LOC (Lines of Code)
- **Medium**: 300-800 LOC
- **Large**: 800-1500 LOC

### 2. 論理的一貫性

関連する機能を一つのPRにまとめる。例:
- Backend Domain層と Adapter層を一つのPRに
- Frontend UI と API クライアントを一つのPRに

### 3. 依存関係の明確化

- ベースブランチと依存関係を明記
- 依存PRがマージされるまで待機

### 4. 並列実行

- 依存関係のないブランチは同時作業可能
- 効率的なリソース活用

### 5. テスト完結性

- 各PRは独立してテスト可能
- Unit/Integration/E2E テストを含む

---

## PR一覧

| PR# | ブランチ名 | Phase | タスク | サイズ | 並列実行 | 依存関係 |
|-----|-----------|-------|--------|--------|----------|----------|
| #1 | `setup/project-structure` | 0 | 1.1, 1.2, 1.3 | Small | ✅ | なし |
| #2 | `setup/terraform-infrastructure` | 0 | 2.1-2.6 | Medium | ✅ | なし |
| #3 | `setup/ci-quality-gate` | 0 | 3.1, 3.2 | Small | ❌ | PR #1 |
| #4 | `setup/cloud-run-deploy` | 0 | 4.1 | Small | ❌ | PR #2, #3 |
| #5 | `setup/local-dev-environment` | 0 | 5.1-5.5 | Medium | ❌ | PR #1 |
| #6 | `feature/hello-world-deployment` | 1 | 6.1-6.3, 7.1-7.4, 8.1-8.3 | Medium | ❌ | PR #3, #5 |
| #7 | `feature/auth-infrastructure` | 2 | 9.1, 9.2 | Small | ✅ | PR #2, #6 |
| #8 | `feature/authentication` | 2 | 10.1-10.5, 11.1-11.3, 12.1-12.3 | Large | ❌ | PR #7 |
| #9 | `feature/backend-transaction-domain` | 3 | 13.1-13.3, 14.1-14.3 | Medium | ✅ | PR #8 |
| #10 | `feature/backend-category` | 3 | 16.1-16.4 | Small | ✅ | PR #8 |
| #11 | `feature/backend-transaction-api` | 3 | 15.1-15.6, 18.1 | Medium | ❌ | PR #9, #10 |
| #12 | `feature/frontend-transaction-ui` | 3 | 17.1-17.5, 18.2, 18.3 | Large | ❌ | PR #11 |
| #13 | `feature/receipt-infrastructure` | 4 | 19.1, 19.2, 23.1-23.3 | Medium | ✅ | PR #2 |
| #14 | `feature/receipt-domain-storage` | 4 | 20.1, 20.2, 21.1, 21.2 | Small | ✅ | PR #8 |
| #15 | `feature/receipt-upload-api` | 4 | 22.1-22.4 | Medium | ❌ | PR #13, #14 |
| #16 | `feature/ocr-worker` | 4 | 24.1-24.3, 25.1-25.4, 27.1, 27.2 | Large | ❌ | PR #15 |
| #17 | `feature/receipt-ui` | 4 | 26.1-26.4, 27.3 | Medium | ❌ | PR #16 |
| #18 | `feature/memo-knowledge` | 5 | 28.1-28.4, 29.1-29.4, 30.1-30.3 | Medium | ❌ | PR #12 |
| #19 | `feature/search-functionality` | 6 | 31.1, 31.2, 33.1, 33.2, 34.1, 34.3 | Medium | ✅ | PR #18 |
| #20 | `feature/report-functionality` | 6 | 32.1, 32.2, 33.3, 33.4, 34.2, 34.4 | Medium | ✅ | PR #18 |
| #21 | `ops/logging-monitoring` | 7 | 35.1-35.4 | Medium | ✅ | PR #11 |
| #22 | `ops/security-hardening` | 7 | 36.1-36.5 | Medium | ✅ | PR #8 |
| #23 | `ops/performance-optimization` | 7 | 37.1-37.3 | Small | ❌ | PR #20 |
| #24 | `ops/production-setup` | 7 | 38.1-38.3 | Medium | ❌ | PR #21, #22, #23 |

---

## Phase別実装計画

### Phase 0: プロジェクト基盤構築 (5 PRs)

#### PR #1: `setup/project-structure`
**タスク**: 1.1, 1.2, 1.3
**依存関係**: なし
**サイズ**: Small
**並列実行**: ✅ 可能

**成果物**:
- モノレポ構造 (`frontend/`, `backend/`, `terraform/`)
- Next.js 15.x プロジェクト (TypeScript, App Router, Vitest, Tailwind CSS)
- Go Echo プロジェクト (Hexagonal Architecture ディレクトリ構造)
- ESLint, Prettier, golangci-lint 設定

**レビューポイント**:
- ディレクトリ構造の適切性
- Linter/Formatter 設定の妥当性
- package.json/go.mod の依存関係

**作業時間見積**: 4-6 時間
**レビュー時間見積**: 1 時間

---

#### PR #2: `setup/terraform-infrastructure`
**タスク**: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6
**依存関係**: なし (PR #1 と並列実行可能)
**サイズ**: Medium
**並列実行**: ✅ 可能

**成果物**:
- リモートステートバケット作成（Cloud Storage）
- Terraformプロジェクト初期化（リモートバックエンド設定）
- 既存WIF stateのリモート移行
- Terraformモジュール作成（`modules/artifact-registry/`, `modules/iam/`, `modules/cloud-run/`, `modules/storage/`）
- Artifact Registryリポジトリ作成（`ledger-muse`）
- Backend APIサービスアカウント作成（`backend-api-staging-sa`）
- Staging環境Cloud Run初期定義（プレースホルダーイメージ）

**レビューポイント**:
- Terraformモジュール設計の再利用性
- State管理の安全性（ローカル→リモート移行）
- 既存WIFリソースとの統合
- 環境分離の適切性

**作業時間見積**: 8-10 時間
**レビュー時間見積**: 2 時間

**注意事項**:
- 既存のWIF（`terraform/wif/`）がデプロイ済みであることを前提
- `terraform plan`の結果をPRに含める
- Staging環境でのテストを完了してからマージ
- GitHub Secrets（WIF_PROVIDER、WIF_SERVICE_ACCOUNT）の設定が必要

---

#### PR #3: `setup/ci-quality-gate`
**タスク**: 3.1, 3.2
**依存関係**: PR #1 (`setup/project-structure`)
**サイズ**: Small
**並列実行**: ❌ (PR #1 に依存、PR #2 と並列可能)

**成果物**:
- `.github/workflows/ci.yml` (品質ゲート部分のみ)
  - Frontend: ESLint、TypeScript、Vitest
  - Backend: golangci-lint、Test、Build
- Firebase App Hosting の GitHub 統合
- ブランチ保護ルール設定

**レビューポイント**:
- CI/CD パイプラインの品質ゲートの妥当性
- Firebase App Hosting統合の設定

**作業時間見積**: 4-6 時間
**レビュー時間見積**: 1 時間

---

#### PR #4: `setup/cloud-run-deploy`
**タスク**: 4.1
**依存関係**: PR #2 (`setup/terraform-infrastructure`), PR #3 (`setup/ci-quality-gate`)
**サイズ**: Small
**並列実行**: ❌ (PR #2, #3 に依存)

**成果物**:
- `.github/workflows/ci.yml`にCloud Runデプロイジョブを追加
  - Workload Identity Federation認証
  - Dockerイメージビルド
  - Artifact Registryプッシュ
  - Cloud Runデプロイ（PR preview、Staging、Production）
  - デプロイ後ヘルスチェック

**レビューポイント**:
- デプロイ設定のセキュリティ
- PR previewデプロイフロー
- Cloud Run設定の妥当性

**作業時間見積**: 4-6 時間
**レビュー時間見積**: 1 時間

**注意事項**:
- GitHub Secretsが設定済みであること（PR #2で設定）
- PR作成時にデプロイが成功することを確認

---

#### PR #5: `setup/local-dev-environment`
**タスク**: 5.1, 5.2, 5.3, 5.4, 5.5
**依存関係**: PR #1 (`setup/project-structure`)
**サイズ**: Medium
**並列実行**: ❌ (PR #1 に依存、PR #3 と並列可能)

**成果物**:
- Firebase Emulator Suite セットアップ (`firebase.json`)
- Docker Compose 環境 (Colima + Docker)
- `backend/Dockerfile.dev`, `.air.toml` (ホットリロード)
- 環境変数設定 (`.env.local`, `.env`)
- MockOCRService 実装

**レビューポイント**:
- ローカル環境の起動確認手順
- Docker 設定の最適性
- 環境変数のドキュメント化

**作業時間見積**: 6-8 時間
**レビュー時間見積**: 1.5 時間

**テスト項目**:
- `colima start` → `docker compose up -d` → `npm run dev` の一連の起動
- http://localhost:3000 (Frontend)
- http://localhost:8080/health (Backend)
- http://localhost:4000 (Emulator UI)
- HMR (Hot Module Replacement) の即時反映確認

---

### Phase 1: Hello World デプロイ (1 PR)

#### PR #6: `feature/hello-world-deployment`
**タスク**: 6.1, 6.2, 6.3, 7.1, 7.2, 7.3, 7.4, 8.1, 8.2, 8.3
**依存関係**: PR #3, PR #5
**サイズ**: Medium
**並列実行**: ❌

**成果物**:
- Frontend トップページ (`app/page.tsx`, Backend API 呼び出し)
- Backend ヘルスチェックエンドポイント (`GET /health`)
- Echo サーバー基本設定 (CORS, Logger, Error Handling)
- `Dockerfile` (マルチステージビルド, distroless)
- Firebase App Hosting & Cloud Run デプロイ確認
- E2E 統合確認 (Playwright 初期実装)

**レビューポイント**:
- Frontend-Backend 通信の正常動作
- CORS 設定の適切性
- Dockerfile のセキュリティ
- デプロイの成功確認

**作業時間見積**: 8-10 時間
**レビュー時間見積**: 2 時間

**テスト項目**:
- ローカル環境での Frontend-Backend 統合
- Staging 環境での Frontend-Backend 統合
- HTTPS 通信の確認
- レスポンスタイム < 1 秒

---

### Phase 2: 認証機能実装 (2 PRs)

#### PR #7: `feature/auth-infrastructure`
**タスク**: 9.1, 9.2
**依存関係**: PR #2, PR #6
**サイズ**: Small
**並列実行**: ✅ (PR #7 と並列可能)

**成果物**:
- Identity Platform リソース (Terraform)
- Google OAuth 2.0 クライアント設定
- Firebase Admin SDK セットアップ (Backend)

**レビューポイント**:
- OAuth リダイレクト URI の正確性
- サービスアカウント権限の適切性

**作業時間見積**: 4-6 時間
**レビュー時間見積**: 1 時間

**注意事項**:
- `terraform plan` の結果を PR に含める
- リダイレクト URI は Staging/Production の両方を設定

---

#### PR #8: `feature/authentication`
**タスク**: 10.1, 10.2, 10.3, 10.4, 10.5, 11.1, 11.2, 11.3, 12.1, 12.2, 12.3
**依存関係**: PR #7
**サイズ**: Large
**並列実行**: ❌ (PR #6 に依存)

**成果物**:
- NextAuth.js v5 セットアップ (`app/api/auth/[...nextauth]/route.ts`)
- ログインページ (`app/login/page.tsx`)
- ログアウト機能
- 保護されたルート (`app/dashboard/page.tsx`, `middleware.ts`)
- セッション管理 (自動更新, トークンリフレッシュ)
- Backend JWT ミドルウェア (`Authorization` ヘッダー検証)
- `GET /api/v1/me` エンドポイント
- Unit テスト (Frontend 認証フロー, Backend JWT)
- E2E テスト (ログイン/ログアウトフロー)

**レビューポイント**:
- JWT 検証ロジックの堅牢性
- セッション管理の安全性
- 認証エラーハンドリング
- E2E テストのカバレッジ

**作業時間見積**: 12-16 時間
**レビュー時間見積**: 3 時間

**テスト項目**:
- ログインフロー (Google OAuth)
- ダッシュボードアクセス (認証必須)
- ログアウトフロー
- 未認証ユーザーのリダイレクト
- JWT 検証 (有効/無効/期限切れ)

---

### Phase 3: 取引CRUD機能実装 (4 PRs)

#### PR #9: `feature/backend-transaction-domain`
**タスク**: 13.1, 13.2, 13.3, 14.1, 14.2, 14.3
**依存関係**: PR #8
**サイズ**: Medium
**並列実行**: ✅ (PR #9 と並列可能)

**成果物**:
- Transaction エンティティ (`internal/domain/transaction.go`)
- TransactionRepository Port (`internal/port/transaction_repository.go`)
- TransactionService (`internal/application/transaction_service.go`)
- Firestore クライアント初期化 (`internal/adapter/firestore/client.go`)
- TransactionRepository Adapter (`users/{userId}/transactions/{transactionId}`)
- Firestore トランザクション処理

**レビューポイント**:
- ドメインロジックのバリデーション
- Hexagonal Architecture の遵守
- Firestore データモデル設計
- トランザクション境界の適切性

**作業時間見積**: 8-10 時間
**レビュー時間見積**: 2 時間

**注意事項**:
- PR #10 と並列実行時、Backend コードベースのマージ競合に注意
- Firestore Emulator でのテスト実施

---

#### PR #10: `feature/backend-category`
**タスク**: 16.1, 16.2, 16.3, 16.4
**依存関係**: PR #8
**サイズ**: Small
**並列実行**: ✅ (PR #8 と並列可能)

**成果物**:
- Category エンティティ (`internal/domain/category.go`)
- CategoryRepository Port & Adapter (`users/{userId}/categories/{categoryId}`)
- CategoryService (デフォルトカテゴリ初期登録ロジック)
- Category API (`POST/GET/PUT/DELETE /api/v1/categories`)

**レビューポイント**:
- Category 削除時の使用チェックロジック
- デフォルトカテゴリの初期化処理

**作業時間見積**: 6-8 時間
**レビュー時間見積**: 1.5 時間

---

#### PR #11: `feature/backend-transaction-api`
**タスク**: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 18.1
**依存関係**: PR #9, PR #10
**サイズ**: Medium
**並列実行**: ❌ (PR #8, #9 に依存)

**成果物**:
- Transaction ルーター (`internal/adapter/http/transaction_handler.go`)
- CRUD エンドポイント (`POST/GET/PUT/DELETE /api/v1/transactions`)
- ユーザー権限チェック (自分の取引のみ操作可能)
- API ログ記録 (構造化ログ, JSON 形式)
- Backend Unit テスト (TransactionService, CategoryService, Firestore Adapter)

**レビューポイント**:
- API エンドポイントの RESTful 設計
- 権限チェックの完全性
- エラーレスポンスの一貫性
- Unit テストのカバレッジ

**作業時間見積**: 10-12 時間
**レビュー時間見積**: 2.5 時間

**テスト項目**:
- CRUD 操作の正常系
- バリデーションエラー (400)
- 権限エラー (403)
- 未認証エラー (401)

---

#### PR #12: `feature/frontend-transaction-ui`
**タスク**: 17.1, 17.2, 17.3, 17.4, 17.5, 18.2, 18.3
**依存関係**: PR #11
**サイズ**: Large
**並列実行**: ❌ (PR #10 に依存)

**成果物**:
- 取引一覧ページ (`app/transactions/page.tsx`, ページネーション)
- API クライアント (`lib/api/transactions.ts`)
- 取引作成フォーム (`app/transactions/new/page.tsx`)
- 取引編集フォーム (`app/transactions/[id]/edit/page.tsx`)
- 取引削除機能 (確認ダイアログ)
- カテゴリ管理 UI (`app/categories/page.tsx`)
- Frontend Unit テスト (API クライアント, フォームコンポーネント)
- E2E テスト (取引 CRUD フロー, データ隔離確認)

**レビューポイント**:
- フォームバリデーションの適切性
- ユーザー体験 (ローディング, エラー表示)
- E2E テストのシナリオ網羅性

**作業時間見積**: 16-20 時間
**レビュー時間見積**: 3.5 時間

**テスト項目**:
- 取引作成フロー
- 取引一覧表示 (ページネーション)
- 取引編集フロー
- 取引削除フロー
- データ隔離 (他ユーザーの取引が表示されない)
- カテゴリ管理 (作成/編集/削除)

---

### Phase 4: レシートOCR機能実装 (5 PRs)

#### PR #13: `feature/receipt-infrastructure`
**タスク**: 19.1, 19.2, 23.1, 23.2, 23.3
**依存関係**: PR #2
**サイズ**: Medium
**並列実行**: ✅ (PR #13 と並列可能)

**成果物**:
- Cloud Storage バケット (Terraform, ライフサイクルポリシー, 暗号化)
- IAM 権限設定 (Storage 書き込み権限, オブジェクトレベル ACL)
- Pub/Sub トピック & サブスクリプション (`receipt-uploaded`)
- Cloud Tasks キュー (レート制限, リトライポリシー, デッドレター)
- PubSubAdapter (`internal/adapter/pubsub/publisher.go`)

**レビューポイント**:
- ストレージライフサイクルポリシーの妥当性
- Pub/Sub → Cloud Tasks フローの設計
- リトライポリシーの適切性

**作業時間見積**: 8-10 時間
**レビュー時間見積**: 2 時間

**注意事項**:
- `terraform plan` の結果を PR に含める
- Pub/Sub エミュレーターでのテスト実施

---

#### PR #14: `feature/receipt-domain-storage`
**タスク**: 20.1, 20.2, 21.1, 21.2
**依存関係**: PR #8
**サイズ**: Small
**並列実行**: ✅ (PR #12 と並列可能)

**成果物**:
- Receipt エンティティ (`internal/domain/receipt.go`)
- ReceiptRepository Port & Adapter (`receipts/{receiptId}`)
- ImageStorage Port (`internal/port/image_storage.go`)
- CloudStorageAdapter (`internal/adapter/storage/cloud_storage.go`, 署名付きURL)

**レビューポイント**:
- Receipt ステータス管理 (Pending, Processing, Completed, Failed)
- CloudStorageAdapter のエミュレーター対応

**作業時間見積**: 6-8 時間
**レビュー時間見積**: 1.5 時間

---

#### PR #15: `feature/receipt-upload-api`
**タスク**: 22.1, 22.2, 22.3, 22.4
**依存関係**: PR #13, PR #14
**サイズ**: Medium
**並列実行**: ❌ (PR #12, #13 に依存)

**成果物**:
- ReceiptService (`internal/application/receipt_service.go`)
- ファイルアップロードバリデーション (JPEG/PNG/HEIC, 最大 10MB)
- `POST /api/v1/receipts/upload` (multipart/form-data)
- `GET /api/v1/receipts/:id`, `GET /api/v1/receipts`
- Pub/Sub イベント発行

**レビューポイント**:
- ファイルバリデーションの堅牢性
- アップロードエラーハンドリング

**作業時間見積**: 8-10 時間
**レビュー時間見積**: 2 時間

**テスト項目**:
- ファイル形式チェック (JPEG/PNG/HEIC のみ許可)
- ファイルサイズチェック (10MB 超過で拒否)
- アップロード成功時の Receipt 作成
- Pub/Sub イベント発行確認

---

#### PR #16: `feature/ocr-worker`
**タスク**: 24.1, 24.2, 24.3, 25.1, 25.2, 25.3, 25.4, 27.1, 27.2
**依存関係**: PR #15
**サイズ**: Large
**並列実行**: ❌ (PR #14 に依存)

**成果物**:
- OCRService Port (`internal/port/ocr_service.go`)
- CloudVisionAdapter (`internal/adapter/vision/cloud_vision.go`, DOCUMENT_TEXT_DETECTION)
- OCR 結果パース (金額, 日付, 店舗名抽出)
- OCR Worker エンドポイント (`POST /api/v1/workers/ocr`)
- 冪等性実装 (receiptId 重複チェック)
- OCR エラーハンドリング (Failed ステータス, デッドレター)
- Backend Unit テスト (ReceiptService, CloudStorageAdapter, CloudVisionAdapter, OCR Worker)
- 統合テスト (Pub/Sub → Cloud Tasks → OCR Worker)

**レビューポイント**:
- OCR パースロジックの精度
- Worker 冪等性の実装
- 非同期処理のエラーハンドリング
- 統合テストのカバレッジ

**作業時間見積**: 16-20 時間
**レビュー時間見積**: 3.5 時間

**テスト項目**:
- Cloud Vision API 呼び出し (モック)
- 金額抽出ロジック (複数金額検出時の合計選択)
- 日付抽出ロジック (複数フォーマット対応)
- 店舗名抽出ロジック
- Worker 冪等性 (重複処理の防止)
- エラーハンドリング (リトライ, デッドレター)

---

#### PR #17: `feature/receipt-ui`
**タスク**: 26.1, 26.2, 26.3, 26.4, 27.3
**依存関係**: PR #16
**サイズ**: Medium
**並列実行**: ❌ (PR #15 に依存)

**成果物**:
- レシート画像アップロードフォーム (ドラッグ&ドロップ, プレビュー)
- OCR 処理状態表示 (アップロード中, 処理中, 完了通知, エラーメッセージ)
- OCR 結果の取引フォーム自動入力 (ポーリング or WebSocket)
- レシート画像表示機能 (サムネイル, モーダル)
- E2E テスト (ファイルアップロード, OCR 処理完了待機, 自動入力確認)

**レビューポイント**:
- ファイルアップロード UX
- 非同期処理の進捗表示
- E2E テストの安定性

**作業時間見積**: 10-12 時間
**レビュー時間見積**: 2.5 時間

**テスト項目**:
- ドラッグ&ドロップでのファイルアップロード
- OCR 処理中のインジケーター表示
- OCR 完了時の自動入力
- OCR エラー時のエラーメッセージ表示

---

### Phase 5: ナレッジ機能（メモ・タグ）実装 (1 PR)

#### PR #18: `feature/memo-knowledge`
**タスク**: 28.1, 28.2, 28.3, 28.4, 29.1, 29.2, 29.3, 29.4, 30.1, 30.2, 30.3
**依存関係**: PR #12
**サイズ**: Medium
**並列実行**: ❌ (PR #11 に依存)

**成果物**:
- Memo エンティティ (`internal/domain/memo.go`, 最大 5000 文字)
- MemoRepository Port & Adapter (`users/{userId}/memos/{memoId}`)
- KnowledgeService (`internal/application/knowledge_service.go`)
- Memo API (`POST/GET/PUT/DELETE /api/v1/transactions/:id/memos`)
- メモ追加フォーム (Markdown エディタ, プレビュー)
- メモ表示機能 (アイコン, ポップアップ, Markdown レンダリング)
- タグ入力機能 (自動補完, タグ削除)
- XSS 対策 (DOMPurify サニタイズ)
- Backend/Frontend Unit テスト
- E2E テスト (メモ追加, Markdown プレビュー, タグ付け)

**レビューポイント**:
- Markdown エディタの使いやすさ
- XSS 対策の完全性
- タグ機能の UX

**作業時間見積**: 12-14 時間
**レビュー時間見積**: 2.5 時間

**テスト項目**:
- メモ追加フロー
- Markdown プレビュー (ライブレンダリング)
- タグ付けフロー (自動補完)
- XSS 対策 (スクリプトタグのサニタイズ)

---

### Phase 6: 検索・レポート機能実装 (2 PRs)

#### PR #19: `feature/search-functionality`
**タスク**: 31.1, 31.2, 33.1, 33.2, 34.1, 34.3
**依存関係**: PR #18
**サイズ**: Medium
**並列実行**: ✅ (PR #19 と並列可能)

**成果物**:
- SearchService (`internal/application/search_service.go`)
- 全文検索ロジック (Firestore クエリ + アプリケーション層フィルタリング)
- 検索 API (`GET /api/v1/transactions/search`)
- 検索フォーム (キーワード, 日付範囲, カテゴリ, タグフィルタ)
- 検索結果表示 (ハイライト, フィルタ条件表示, 0 件メッセージ)
- Backend Unit テスト (SearchService)
- E2E テスト (検索フロー, フィルタ適用, ハイライト確認)

**レビューポイント**:
- 検索パフォーマンス
- ハイライト表示の正確性
- フィルタ組み合わせの動作

**作業時間見積**: 10-12 時間
**レビュー時間見積**: 2.5 時間

**注意事項**:
- PR #20 と並列実行時、Backend コードベースのマージ競合に注意

---

#### PR #20: `feature/report-functionality`
**タスク**: 32.1, 32.2, 33.3, 33.4, 34.2, 34.4
**依存関係**: PR #18
**サイズ**: Medium
**並列実行**: ✅ (PR #18 と並列可能)

**成果物**:
- ReportService (`internal/application/report_service.go`)
- 集計ロジック (期間別, カテゴリ別, 月次/週次/年次, 前月比較)
- レポート API (`GET /api/v1/reports/summary`, CSV エクスポート)
- ダッシュボード更新 (収入・支出・残高, カテゴリ別円グラフ, 月次推移折れ線グラフ)
- グラフドリルダウン機能
- CSV エクスポート機能
- Backend/Frontend Unit テスト
- E2E テスト (ダッシュボード表示, ドリルダウン, CSV エクスポート)

**レビューポイント**:
- 集計ロジックの正確性
- グラフの視覚的な分かりやすさ
- CSV エクスポートのデータ完全性

**作業時間見積**: 12-14 時間
**レビュー時間見積**: 2.5 時間

**テスト項目**:
- 期間別集計 (月次, 週次, 年次)
- カテゴリ別集計
- 前月比較データ生成
- グラフクリックでドリルダウン
- CSV エクスポート

---

### Phase 7: 運用・監視機能実装 (4 PRs)

#### PR #21: `ops/logging-monitoring`
**タスク**: 35.1, 35.2, 35.3, 35.4
**依存関係**: PR #11 (API ログ記録の拡張)
**サイズ**: Medium
**並列実行**: ✅ (PR #21 と並列可能)

**成果物**:
- 構造化ログ (JSON 形式, ログレベル, 機密情報マスキング)
- Cloud Monitoring 統合 (API レスポンスタイム, エラーレート, リクエスト数)
- Cloud Trace 統合 (分散トレーシング, コンテキスト伝播)
- アラート設定 (レスポンスタイム > 3秒, エラーレート > 1%, コスト超過)

**レビューポイント**:
- ログの構造化とクエリのしやすさ
- メトリクス収集の網羅性
- アラートしきい値の妥当性

**作業時間見積**: 10-12 時間
**レビュー時間見積**: 2.5 時間

---

#### PR #22: `ops/security-hardening`
**タスク**: 36.1, 36.2, 36.3, 36.4, 36.5
**依存関係**: PR #8
**サイズ**: Medium
**並列実行**: ✅ (PR #20 と並列可能)

**成果物**:
- HTTPS 強制 (Cloud Run 設定, HTTP → HTTPS リダイレクト)
- データ暗号化確認 (TLS 1.3, Cloud Storage 暗号化, Firestore 暗号化)
- Cloud KMS セットアップ (Terraform, キーローテーションポリシー)
- レート制限 (アップロード 10回/時間, API 将来対応)
- アカウントロック機能 (ログイン失敗 5 回でロック)

**レビューポイント**:
- HTTPS 設定の完全性
- KMS 鍵管理の安全性
- レート制限の実装方法

**作業時間見積**: 10-12 時間
**レビュー時間見積**: 2.5 時間

**注意事項**:
- `terraform plan` の結果を PR に含める
- KMS 鍵のローテーションポリシーを確認

---

#### PR #23: `ops/performance-optimization`
**タスク**: 37.1, 37.2, 37.3
**依存関係**: PR #20 (レポート機能の最適化)
**サイズ**: Small
**並列実行**: ❌ (PR #19 に依存)

**成果物**:
- API パフォーマンステスト (JMeter or Locust, 95 パーセンタイル < 1秒)
- OCR 処理パフォーマンステスト (平均 < 15秒, 最大 < 30秒)
- Frontend パフォーマンステスト (Lighthouse, LCP < 2.5秒)

**レビューポイント**:
- パフォーマンステスト結果の達成度
- ボトルネックの特定と改善

**作業時間見積**: 8-10 時間
**レビュー時間見積**: 2 時間

**テスト項目**:
- API レスポンスタイム (95 パーセンタイル < 1秒)
- OCR 処理時間 (平均 < 15秒, 最大 < 30秒)
- Lighthouse スコア (LCP < 2.5秒)

---

#### PR #24: `ops/production-setup`
**タスク**: 38.1, 38.2, 38.3
**依存関係**: PR #21, PR #22, PR #23
**サイズ**: Medium
**並列実行**: ❌ (すべての運用機能に依存)

**成果物**:
- Production 環境 Terraform 定義 (`terraform/environments/prod/`)
- Production デプロイパイプライン (`.github/workflows/deploy-production.yml`, 手動承認ゲート)
- ブルー/グリーンデプロイ (または Canary)
- Production デプロイ実行とロールバック手順確認

**レビューポイント**:
- Production 設定の本番環境適合性
- デプロイパイプラインの安全性
- ロールバック手順の明確性

**作業時間見積**: 10-12 時間
**レビュー時間見積**: 2.5 時間

**注意事項**:
- `terraform plan` の結果を PR に含める
- Staging 環境で最終確認後、Production デプロイ
- ロールバック手順をドキュメント化

---

## 並列実行グループ

### Group 1 (Phase 0, 並列実行可能)
- **PR #1**: `setup/project-structure` (先行実行)
- **PR #2**: `setup/terraform-infrastructure` (PR #1 と並列)

### Group 2 (Phase 0, Group 1 依存)
- **PR #3**: `setup/ci-quality-gate` (PR #1 後、PR #2 と並列可能)
- **PR #5**: `setup/local-dev-environment` (PR #1 後、PR #2, #3 と並列可能)

### Group 3 (Phase 0, Group 2 依存)
- **PR #4**: `setup/cloud-run-deploy` (PR #2, #3 後)

### Group 4 (Phase 1)
- **PR #6**: `feature/hello-world-deployment` (PR #3, #5 後)

### Group 5 (Phase 2)
- **PR #7**: `feature/auth-infrastructure` (PR #2, #6 後)
- **PR #8**: `feature/authentication` (PR #7 後)

### Group 6 (Phase 3, 並列実行可能)
- **PR #9**: `feature/backend-transaction-domain` (PR #8 後)
- **PR #10**: `feature/backend-category` (PR #8 後, PR #9 と並列)

### Group 7 (Phase 3)
- **PR #11**: `feature/backend-transaction-api` (PR #9, #10 後)
- **PR #12**: `feature/frontend-transaction-ui` (PR #11 後)

### Group 8 (Phase 4, 並列実行可能)
- **PR #13**: `feature/receipt-infrastructure` (PR #2 後)
- **PR #14**: `feature/receipt-domain-storage` (PR #8 後, PR #13 と並列)

### Group 9 (Phase 4)
- **PR #15**: `feature/receipt-upload-api` (PR #13, #14 後)
- **PR #16**: `feature/ocr-worker` (PR #15 後)
- **PR #17**: `feature/receipt-ui` (PR #16 後)

### Group 10 (Phase 5)
- **PR #18**: `feature/memo-knowledge` (PR #12 後)

### Group 11 (Phase 6, 並列実行可能)
- **PR #19**: `feature/search-functionality` (PR #18 後)
- **PR #20**: `feature/report-functionality` (PR #18 後, PR #19 と並列)

### Group 12 (Phase 7, 並列実行可能)
- **PR #21**: `ops/logging-monitoring` (PR #11 後)
- **PR #22**: `ops/security-hardening` (PR #8 後, PR #21 と並列)

### Group 13 (Phase 7)
- **PR #23**: `ops/performance-optimization` (PR #20 後)
- **PR #24**: `ops/production-setup` (PR #21, #22, #23 後)

---

## 依存関係グラフ

```
Phase 0:
  PR #1 (setup/project-structure)
    ├─→ PR #3 (setup/ci-quality-gate)
    └─→ PR #5 (setup/local-dev-environment)

  PR #2 (setup/terraform-infrastructure) [並列実行可能、PR #1と並列]

  PR #2, #3 → PR #4 (setup/cloud-run-deploy)

Phase 1:
  PR #3, #5 → PR #6 (feature/hello-world-deployment)

Phase 2:
  PR #2, #6 → PR #7 (feature/auth-infrastructure)
             → PR #8 (feature/authentication)

Phase 3:
  PR #8 → PR #9 (feature/backend-transaction-domain) [並列実行可能]
       → PR #10 (feature/backend-category) [並列実行可能]
       → PR #11 (feature/backend-transaction-api)
       → PR #12 (feature/frontend-transaction-ui)

Phase 4:
  PR #2 → PR #13 (feature/receipt-infrastructure) [並列実行可能]
  PR #8 → PR #14 (feature/receipt-domain-storage) [並列実行可能]
  PR #13, #14 → PR #15 (feature/receipt-upload-api)
             → PR #16 (feature/ocr-worker)
             → PR #17 (feature/receipt-ui)

Phase 5:
  PR #12 → PR #18 (feature/memo-knowledge)

Phase 6:
  PR #18 → PR #19 (feature/search-functionality) [並列実行可能]
        → PR #20 (feature/report-functionality) [並列実行可能]

Phase 7:
  PR #11 → PR #21 (ops/logging-monitoring) [並列実行可能]
  PR #8 → PR #22 (ops/security-hardening) [並列実行可能]
  PR #20 → PR #23 (ops/performance-optimization)
  PR #21, #22, #23 → PR #24 (ops/production-setup)
```

---

## リスクと注意事項

### 1. Large サイズの PR

以下の PR は Large サイズであり、レビュー時間を十分に確保する必要があります:

- **PR #8** (`feature/authentication`): 認証機能が大規模。レビュー時間 3 時間を見積もる。
- **PR #12** (`feature/frontend-transaction-ui`): Frontend UI が複雑。UI/UX レビューが必要。
- **PR #16** (`feature/ocr-worker`): OCR 処理が複雑。統合テストの安定性に注意。

### 2. 依存関係の複雑性

- **Phase 4 (レシートOCR)** は **Phase 3 (取引CRUD)** に強く依存。Phase 3 完了まで Phase 4 は待機。
- **Phase 7 (運用・監視)** は **Phase 6** 完了まで待機。

### 3. 並列実行時の競合

以下の PR 組み合わせは並列実行可能ですが、マージ時の競合に注意:

- **PR #9 と PR #10**: 両方が Backend コードベースを変更するため、マージ時の競合に注意。
- **PR #19 と PR #20**: 同様に Backend コードベースの競合に注意。

**競合回避策**:
- 並列実行時は、頻繁に `main` ブランチを取り込む (リベース)
- マージ順序を決めておく (例: PR #9 → PR #10)

### 4. テストの独立性

- 各 PR は E2E テストを含むため、テスト環境のデータ隔離を確保。
- Firebase Emulator Suite の並列実行時のポート競合に注意。

**テスト環境の管理**:
- 各 PR ごとに独立した Firestore コレクションを使用
- E2E テスト実行前にデータをクリア

### 5. Infrastructure as Code の変更

以下の PR では Terraform 変更が含まれるため、`terraform plan` の結果を PR に含める:

- PR #2: `setup/terraform-infrastructure`
- PR #13: `feature/receipt-infrastructure`
- PR #21: `ops/logging-monitoring`
- PR #22: `ops/security-hardening`
- PR #24: `ops/production-setup`

**Terraform ワークフロー**:
1. `terraform plan` の結果を PR コメントに貼り付け
2. Staging 環境で `terraform apply` を実行
3. Staging 環境でテスト確認
4. レビュー承認後、マージ

### 6. デプロイの安全性

- **PR #6, #8, #11, #15, #16, #24** はデプロイを伴うため、Staging 環境での動作確認が必須。
- **PR #24** (Production セットアップ) は、手動承認ゲートを含む。

### 7. パフォーマンステストの実施タイミング

- **PR #23** (パフォーマンス最適化) は、**PR #20** (レポート機能) 完了後に実施。
- パフォーマンステストで基準未達の場合、改善作業が必要。

### 8. セキュリティレビュー

以下の PR はセキュリティレビューを重点的に実施:

- **PR #8**: 認証機能 (JWT 検証, セッション管理)
- **PR #15**: ファイルアップロード (バリデーション, アップロードパス)
- **PR #18**: XSS 対策 (DOMPurify サニタイズ)
- **PR #22**: セキュリティ強化 (HTTPS, KMS, レート制限)

---

## 推奨ワークフロー

### 1. Phase 0 を最優先で完了

CI/CD とローカル環境がないと後続作業が非効率になるため、Phase 0 を最優先で完了する。

**実施順序**:
1. **PR #1** (`setup/project-structure`) を先行実行
2. **PR #2** (`setup/terraform-infrastructure`) を並列実行
3. **PR #3** (`setup/ci-quality-gate`) を PR #1 完了後に実行
4. **PR #5** (`setup/local-dev-environment`) を PR #1 完了後に実行
5. **PR #4** (`setup/cloud-run-deploy`) を PR #2, #3 完了後に実行

### 2. 並列実行を積極活用

Group ごとに複数のブランチで同時作業し、開発期間を短縮する。

**並列実行例**:
- **Group 6**: PR #9 と PR #10 を並列実行
- **Group 11**: PR #19 と PR #20 を並列実行
- **Group 12**: PR #21 と PR #22 を並列実行

### 3. PR サイズに応じてレビュー時間を確保

Large PR は 2-3 時間のレビュー時間を見積もる。

**レビュー時間見積**:
- Small: 1 時間
- Medium: 1.5-2.5 時間
- Large: 3-3.5 時間

### 4. テストを必ず含める

各 PR は Unit/Integration/E2E テストを含め、品質ゲートをパス。

**品質ゲート**:
- Lint: ESLint (Frontend), golangci-lint (Backend)
- TypeCheck: TypeScript (Frontend)
- Test: Vitest (Frontend), `go test` (Backend)
- Build: `npm run build` (Frontend), `go build` (Backend)

### 5. ドキュメント更新

各 PR で README や API ドキュメントを更新。

**ドキュメント更新項目**:
- README.md: セットアップ手順, 環境変数, ローカル開発
- API ドキュメント: エンドポイント, リクエスト/レスポンス形式
- CHANGELOG.md: 変更内容のサマリー

### 6. PR テンプレートの活用

以下の PR テンプレートを使用:

```markdown
## 概要
<!-- この PR で実装する機能の概要 -->

## 関連タスク
<!-- tasks.md のタスク番号 -->

## 変更内容
<!-- 主な変更内容をリスト形式で記載 -->

## テスト
<!-- 実施したテストの内容 -->

## レビューポイント
<!-- レビュアーに重点的に確認してほしいポイント -->

## スクリーンショット (オプション)
<!-- UI 変更がある場合、スクリーンショットを添付 -->

## チェックリスト
- [ ] Unit テストを追加/更新
- [ ] E2E テストを追加/更新
- [ ] ドキュメントを更新
- [ ] Lint/TypeCheck がパス
- [ ] ローカル環境で動作確認
- [ ] Staging 環境で動作確認 (デプロイを伴う場合)
```

### 7. デプロイフロー

1. **PR 作成**: ブランチを `main` に向けて PR 作成
2. **品質ゲート**: GitHub Actions で Lint/Test/Build を実行
3. **レビュー**: レビュアーが承認
4. **マージ**: `main` ブランチにマージ
5. **自動デプロイ**: Staging 環境に自動デプロイ
6. **動作確認**: Staging 環境で動作確認
7. **Production デプロイ**: 手動承認後、Production にデプロイ (Phase 7 完了後)

---

## 作業時間見積サマリー

| Phase | PR 数 | 合計作業時間 | 合計レビュー時間 |
|-------|------|-------------|----------------|
| Phase 0 | 5 | 28-38 時間 | 6.5 時間 |
| Phase 1 | 1 | 8-10 時間 | 2 時間 |
| Phase 2 | 2 | 16-22 時間 | 4 時間 |
| Phase 3 | 4 | 40-50 時間 | 9.5 時間 |
| Phase 4 | 5 | 48-60 時間 | 11.5 時間 |
| Phase 5 | 1 | 12-14 時間 | 2.5 時間 |
| Phase 6 | 2 | 22-26 時間 | 5 時間 |
| Phase 7 | 4 | 38-46 時間 | 9.5 時間 |
| **合計** | **24** | **212-270 時間** | **51.5 時間** |

**開発期間見積** (1人で作業する場合):
- **最短**: 212 時間 ÷ 8 時間/日 = **26.5 営業日 (約 5.5 週間)**
- **最長**: 270 時間 ÷ 8 時間/日 = **33.75 営業日 (約 6.75 週間)**

**開発期間見積** (並列実行を活用する場合):
- 並列実行可能な PR を同時に作業することで、**約 4-5 週間** に短縮可能

---

## まとめ

この計画で **24 個の PR** に分割され、**並列実行可能な箇所** を最大限活用することで、開発期間を短縮できます。各 PR のレビューポイントを明確にし、品質を担保しながら効率的に進めてください。

**重要なポイント**:
1. **Phase 0** を最優先で完了する
2. **並列実行** を積極的に活用する
3. **Large サイズの PR** はレビュー時間を十分に確保する
4. **テスト** を必ず含める
5. **ドキュメント** を更新する
6. **Terraform 変更** は `terraform plan` の結果を PR に含める
7. **セキュリティレビュー** を重点的に実施する

この計画に沿って実装を進めれば、レビューの質を保ちながら効率的に開発できます！
