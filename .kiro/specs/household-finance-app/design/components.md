# コンポーネント設計

本ドキュメントでは、各コンポーネントの責務、依存関係、契約（インターフェース）の概要を定義します。

> **注意**: 詳細なコンポーネント仕様（Service Interface、API Contract、Event Contract等）は、元の `design.md` ファイル（現在はアーカイブ）に記載されています。

## コンポーネント概要

| Component | Domain/Layer | Intent | Requirements | Key Dependencies |
|-----------|--------------|--------|--------------|------------------|
| **AuthService** | Backend/Domain | ユーザー認証・認可 | Req 1, 11 | UserRepository, Identity Platform |
| **TransactionService** | Backend/Domain | 取引 CRUD、集計 | Req 2, 8 | TransactionRepository, CategoryRepository |
| **CategoryService** | Backend/Domain | カテゴリ CRUD | Req 3 | CategoryRepository, TransactionRepository |
| **ReceiptService** | Backend/Domain | レシート管理 | Req 4, 5 | ReceiptRepository, ImageStorage, EventPublisher |
| **KnowledgeService** | Backend/Domain | メモ・タグ管理 | Req 6 | KnowledgeRepository |
| **SearchService** | Backend/Domain | 取引検索 | Req 7 | TransactionRepository, KnowledgeRepository |
| **OCRWorker** | Backend/Worker | 非同期 OCR 処理 | Req 5, 18 | OCRService, ReceiptRepository |
| **FirestoreAdapter** | Backend/Adapter | Firestore 実装 | Req 9 | Firestore SDK |
| **CloudStorageAdapter** | Backend/Adapter | Cloud Storage 実装 | Req 4, 12 | Cloud Storage SDK |
| **CloudVisionAdapter** | Backend/Adapter | Cloud Vision 実装 | Req 5 | Cloud Vision SDK |
| **PubSubAdapter** | Backend/Adapter | Pub/Sub 実装 | Req 5, 18 | Pub/Sub SDK |
| **JWTMiddleware** | Backend/Middleware | JWT トークン検証 | Req 11 | Firebase Admin SDK |
| **Next.js App** | Frontend | Web UI、SSR/SSG | Req 13 | NextAuth.js, Backend API |

## レイヤー構成

### Frontend Layer

#### Next.js App (Firebase App Hosting)

- **ホスティング**: Firebase App Hosting（SSR/SSG最適化、CDN統合）
- **認証**: NextAuth.js v5 + Google Cloud Identity Platform
- **主要UI**: 認証UI、取引管理UI、レシート管理UI、ナレッジUI、ダッシュボードUI
- **状態管理**: React Context API または Zustand
- **スタイリング**: Tailwind CSS（推奨）

### Backend / Domain Layer

主要なビジネスロジックを実装するサービス層：

- **AuthService**: ユーザー登録、ログイン、トークン検証
- **TransactionService**: 取引CRUD、集計計算
- **CategoryService**: カテゴリCRUD、使用チェック
- **ReceiptService**: 画像アップロード、OCRトリガー
- **KnowledgeService**: メモCRUD、タグ管理
- **SearchService**: 全文検索、フィルタリング

### Backend / Worker Layer

#### OCRWorker

- **トリガー**: Pub/Sub → Cloud Tasks
- **処理**: Cloud Vision APIでOCR実行 → Firestore更新
- **冪等性**: receiptId でレコード検索、status確認
- **リトライ**: 最大3回、失敗時はDLQへ

### Backend / Adapter Layer

- **FirestoreAdapter**: Repository Portsの実装
- **CloudStorageAdapter**: ImageStorage Portの実装
- **CloudVisionAdapter**: OCRService Portの実装
- **PubSubAdapter**: EventPublisher Portの実装

### Backend / Middleware Layer

#### JWTMiddleware

- **役割**: Authorization ヘッダーからJWT抽出 → Firebase Admin SDKで検証
- **設定**: Echo のミドルウェアチェーンに組み込み
- **エラーハンドリング**: 401 Unauthorized返却

## Repository Ports

以下のリポジトリインターフェースを定義：

- **UserRepository**: ユーザーCRUD
- **TransactionRepository**: 取引CRUD、検索、集計
- **CategoryRepository**: カテゴリCRUD、使用カウント
- **ReceiptRepository**: レシートCRUD、ステータス更新
- **KnowledgeRepository**: メモCRUD、タグ検索

## 主要なAPI Contract

### Authentication API

| Method | Endpoint | Request | Response |
|--------|----------|---------|----------|
| POST | /api/v1/auth/signup | `{ email, password }` | `{ userId, email }` |
| POST | /api/v1/auth/login | `{ email, password }` | `{ token, expiresAt }` |
| POST | /api/v1/auth/logout | `{ userId }` | `{ success }` |

### Transactions API

| Method | Endpoint | Request | Response |
|--------|----------|---------|----------|
| POST | /api/v1/transactions | `CreateTransactionRequest` | `Transaction` |
| GET | /api/v1/transactions | Query params | `TransactionList` |
| GET | /api/v1/transactions/{id} | - | `Transaction` |
| PUT | /api/v1/transactions/{id} | `UpdateTransactionRequest` | `Transaction` |
| DELETE | /api/v1/transactions/{id} | - | `{ success }` |

### Receipts API

| Method | Endpoint | Request | Response |
|--------|----------|---------|----------|
| POST | /api/v1/receipts/upload | Multipart form-data | `Receipt` (status: pending) |
| GET | /api/v1/receipts/{id} | - | `Receipt` |
| GET | /api/v1/receipts | Query params | `ReceiptList` |

### Search API

| Method | Endpoint | Request | Response |
|--------|----------|---------|----------|
| GET | /api/v1/transactions/search | Query params | `SearchResult` |

## Event Contracts

### Pub/Sub Events

#### receipt.uploaded

- **Topic**: `receipt-uploaded`
- **Payload**: `{ receiptId, userId, imageUrl, uploadedAt }`
- **Subscribers**: OCRWorker
- **Delivery**: At-least-once

## 詳細仕様の参照先

詳細なコンポーネント仕様（Service Interface、Preconditions/Postconditions、Implementation Notes等）は、このドキュメントでは省略しています。必要に応じて、以下のリソースを参照してください：

1. **元の design.md ファイル**（アーカイブ済み）: 全コンポーネントの詳細仕様
2. **research.md**: 技術選定根拠、アーキテクチャ評価
3. **requirements.md**: 要件トレーサビリティ
