# システムフロー設計

本ドキュメントでは、主要なシステムフローをシーケンス図で定義します。

## ユーザー認証フロー

```mermaid
sequenceDiagram
    participant User as ユーザー
    participant AppHosting as Firebase App Hosting
    participant NextAuth as NextAuth.js
    participant IdP as Identity Platform
    participant API as Backend API (Cloud Run)
    participant Firestore as Firestore

    User->>AppHosting: ログインボタンクリック
    AppHosting->>NextAuth: signIn("google")
    NextAuth->>IdP: OAuth 2.0 認証リクエスト
    IdP->>User: Google ログイン画面表示
    User->>IdP: 認証情報入力
    IdP->>NextAuth: 認証成功、ID トークン発行
    NextAuth->>AppHosting: セッション作成（JWT）
    AppHosting->>User: ダッシュボードにリダイレクト

    Note over User,Firestore: 以降の API リクエスト

    User->>AppHosting: 取引一覧取得リクエスト
    AppHosting->>API: GET /api/v1/transactions<br/>Authorization: Bearer {idToken}
    API->>API: JWT トークン検証<br/>(Firebase Admin SDK)
    API->>Firestore: ユーザー ID でクエリ
    Firestore->>API: 取引データ返却
    API->>AppHosting: JSON レスポンス
    AppHosting->>User: 取引一覧表示
```

**フロー決定事項**:
- NextAuth.js が OAuth フロー、セッション管理を担当
- ID トークンは Authorization ヘッダーで Backend API に送信
- Backend は Firebase Admin SDK でトークン検証、ユーザー ID 抽出
- セッションは JWT 形式で保存（デフォルト 30 日間有効）

## レシート画像アップロード & OCR 処理フロー

```mermaid
sequenceDiagram
    participant User as ユーザー
    participant AppHosting as Firebase App Hosting
    participant API as Backend API (Cloud Run)
    participant CloudStorage as Cloud Storage
    participant PubSub as Pub/Sub
    participant CloudTasks as Cloud Tasks
    participant Worker as OCR Worker
    participant CloudVision as Cloud Vision API
    participant Firestore as Firestore

    User->>AppHosting: レシート画像選択
    AppHosting->>AppHosting: クライアント側検証<br/>(形式、サイズ)
    AppHosting->>API: POST /api/v1/receipts/upload<br/>(画像ファイル)
    API->>API: JWT 検証
    API->>CloudStorage: 画像アップロード<br/>(users/{userId}/receipts/{receiptId}.jpg)
    CloudStorage->>API: アップロード完了、URL 返却
    API->>Firestore: Receipt レコード作成<br/>(status: pending)
    API->>PubSub: receipt.uploaded イベント発行<br/>(receiptId, imageUrl, userId)
    API->>AppHosting: 202 Accepted<br/>(receiptId, status: pending)
    AppHosting->>User: アップロード完了通知、処理中表示

    PubSub->>CloudTasks: Pub/Sub サブスクリプション<br/>→ Cloud Tasks キュー
    CloudTasks->>Worker: OCR タスク実行
    Worker->>CloudVision: DOCUMENT_TEXT_DETECTION<br/>(imageUrl)
    CloudVision->>Worker: OCR 結果（JSON）
    Worker->>Worker: データ抽出<br/>(金額、日付、店舗名)
    Worker->>Firestore: OCR 結果保存<br/>(status: completed, extractedData)
    Worker->>Worker: 処理成功レスポンス

    Note over AppHosting,User: フロントエンドは Firestore リアルタイムリスナーまたはポーリングで更新取得

    AppHosting->>Firestore: Receipt ドキュメント監視
    Firestore->>AppHosting: status: completed 検知
    AppHosting->>User: OCR 結果を取引フォームに自動入力
```

**フロー決定事項**:
- 非同期処理により API レスポンスタイムを短縮（30 秒以内の OCR 処理時間を非ブロッキング化）
- Pub/Sub でイベント発行（将来的にサムネイル生成などの追加サブスクライバーを容易に追加可能）
- Cloud Tasks でレート制限（Vision API クォータ管理）
- Firestore リアルタイムリスナーで UI 更新（WebSocket 不要）
- OCR 失敗時はデッドレターキューに移動、アラート発報

## 取引検索フロー

```mermaid
sequenceDiagram
    participant User as ユーザー
    participant AppHosting as Firebase App Hosting
    participant API as Backend API (Cloud Run)
    participant Firestore as Firestore

    User->>AppHosting: 検索フォーム入力<br/>(キーワード、日付範囲、カテゴリ)
    AppHosting->>API: GET /api/v1/transactions/search<br/>?q={keyword}&from={date}&to={date}&category={id}
    API->>API: JWT 検証、クエリパラメータ検証
    API->>Firestore: 複合クエリ実行<br/>(where userId, where date, where category)
    Firestore->>API: マッチした取引リスト返却
    API->>API: キーワードフィルタリング<br/>(メモ、タグのテキスト検索)
    API->>AppHosting: JSON レスポンス<br/>(transactions, highlightedText)
    AppHosting->>User: 検索結果表示<br/>(マッチ箇所ハイライト)
```

**フロー決定事項**:
- Firestore の複合インデックスで日付・カテゴリフィルタを高速化
- テキスト検索（キーワード）はアプリケーション層で実装（Firestore はフルテキスト検索非対応）
- 将来的に BigQuery へのデータエクスポートで高度な検索・分析機能を追加可能
