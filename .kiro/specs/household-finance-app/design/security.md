# セキュリティ設計

本ドキュメントでは、認証・認可、データ保護、エラーハンドリングに関するセキュリティ対策を記載します。

## Threat Modeling

### 主要な脅威と対策

1. **不正アクセス（他ユーザーのデータへのアクセス）**
   - 対策: JWT トークン検証、userId ベースのデータ隔離、Firestore セキュリティルール

2. **XSS 攻撃（マークダウンメモの悪意あるスクリプト）**
   - 対策: フロントエンドで DOMPurify による sanitize 処理

3. **CSRF 攻撃（偽造リクエスト）**
   - 対策: NextAuth.js の CSRF トークン、SameSite Cookie 設定

4. **機密情報漏洩（ログにトークン出力）**
   - 対策: ログマスキング処理、Cloud Logging のアクセス制御

## Authentication and Authorization

### 認証フロー

- **Identity Platform** による OAuth 2.0 認証
- **JWT トークンベース**の認証（Bearer Token）
- ユーザーデータ隔離（userId でフィルタリング）
- API エンドポイントごとの認可チェック（JWTMiddleware）

### 認可パターン

- すべてのAPIリクエストでJWT検証（JWTMiddleware）
- userId によるデータ隔離（他ユーザーのデータアクセス拒否）
- Firestoreセキュリティルール: `allow read, write: if request.auth.uid == userId`

## Data Protection and Privacy

### データ暗号化

- **転送中**: HTTPS 通信の強制（TLS 1.3）
- **保存中**:
  - Cloud Storage サーバー側暗号化（AES-256）
  - Firestore データ暗号化（デフォルト有効）
  - 将来: Cloud KMS による暗号鍵管理

### プライバシー対応

- **GDPR 対応**: ユーザーデータの削除リクエスト（Right to be Forgotten）
- **個人情報保護法（日本）**: ユーザーデータの適切な管理、削除権の提供

## Error Handling

### Error Strategy

エラーを **User Errors (4xx)**、**System Errors (5xx)**、**Business Logic Errors (422)** の 3 カテゴリに分類します。

### Error Categories

#### User Errors (4xx)

| Code | Type | Example | Response Format |
|------|------|---------|-----------------|
| 400 | Bad Request | 無効な入力（日付形式エラー、負の金額） | `{ "error": { "type": "VALIDATION_ERROR", "field": "amount", "message": "金額は正の数値を入力してください" } }` |
| 401 | Unauthorized | 認証トークン無効/期限切れ | `{ "error": { "type": "UNAUTHORIZED", "message": "ログインが必要です" } }` |
| 403 | Forbidden | アカウントロック/権限不足 | `{ "error": { "type": "FORBIDDEN", "message": "アカウントが一時的にロックされています" } }` |
| 404 | Not Found | リソース不存在 | `{ "error": { "type": "NOT_FOUND", "resource": "transaction", "id": "txn_12345" } }` |

#### System Errors (5xx)

| Code | Type | Handling |
|------|------|----------|
| 500 | Internal Server Error | Cloud Loggingにスタックトレース記録、アラート発報 |
| 503 | Service Unavailable | Circuit Breakerでリトライ制御、DLQに移動 |

#### Business Logic Errors (422)

- ビジネスルール違反（例: 使用中のカテゴリ削除）
- Response: `{ "error": { "type": "CATEGORY_IN_USE", "transactionCount": 15, "message": "このカテゴリは 15 件の取引で使用されています" } }`

### Error Monitoring

- **Cloud Logging**: 全エラーレスポンスを記録（severity: ERROR, WARNING）
- **構造化ログ**: JSON 形式、機密情報マスキング
- **SLO 設定**: エラーレート < 1%（月間）
- **Health Endpoint**: `/health` でFirestore接続状態確認

## Compliance Requirements

- **個人情報保護法（日本）**: ユーザーデータの適切な管理、削除権の提供
- **GDPR（将来的な商用運用時）**: データポータビリティ、削除権、同意管理

## Security Best Practices

1. **最小権限の原則**: IAM ロールを最小限に設定
2. **定期的なセキュリティレビュー**: 四半期ごとに脅威モデル見直し
3. **依存ライブラリの脆弱性スキャン**: GitHub Dependabot 有効化
4. **ログ監視とアラート**: 異常なアクセスパターン検出
5. **インシデント対応計画**: セキュリティインシデント発生時の対応手順文書化
