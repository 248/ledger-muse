# テスト戦略

## Unit Tests

### Core Functions / Modules

1. **AuthService.signUp**: 正常系（ユーザー作成成功）、異常系（重複メール、無効なパスワード）
2. **TransactionService.createTransaction**: 正常系（取引作成成功）、異常系（カテゴリ不存在、無効な金額）
3. **OCRWorker.processReceipt**: 正常系（OCR 成功）、異常系（Cloud Vision API エラー、低信頼度スコア）
4. **CloudVisionAdapter.extractData**: 正常系（金額・日付・店舗名抽出）、異常系（テキスト検出失敗）
5. **JWTMiddleware.verifyToken**: 正常系（有効なトークン）、異常系（期限切れ、無効な署名）

### Testing Approach

- **Go**: `testing` パッケージ + モック（`gomock` または手動モック実装）
- **TypeScript**: Jest + React Testing Library
- **Repository ポート**のモック実装でインメモリテスト

## Integration Tests

### Cross-Component Flows

1. **Authentication Flow**: NextAuth.js → Identity Platform → Backend API JWT 検証
2. **Receipt Upload Flow**: Frontend → Backend API → Cloud Storage → Pub/Sub → Cloud Tasks → OCR Worker → Firestore
3. **Transaction CRUD Flow**: Frontend → Backend API → Firestore CRUD 操作
4. **Search Flow**: Frontend → Backend API → Firestore クエリ + アプリケーション層フィルタリング
5. **Category Deletion Flow**: Frontend → Backend API → TransactionRepository.countByCategory → CategoryRepository.delete

### Testing Approach

- **Go**: Firestore エミュレーター + Cloud Storage エミュレーター使用
- **E2E**: Playwright または Cypress でブラウザテスト

## E2E / UI Tests

### Critical User Paths

1. **ユーザー登録 → ログイン → ダッシュボード表示**: 新規ユーザーが初回ログイン後にダッシュボードを確認できる
2. **取引作成 → 一覧表示 → 編集 → 削除**: 取引の CRUD 操作が正常に動作する
3. **レシート画像アップロード → OCR 処理 → 結果確認**: レシート画像をアップロードし、OCR 結果が取引フォームに反映される
4. **カテゴリ作成 → 取引に関連付け → カテゴリ削除の警告表示**: カテゴリを作成し、取引に使用されている場合に削除警告が表示される
5. **検索フォーム入力 → 検索結果表示 → ハイライト確認**: キーワード検索で結果が表示され、マッチ箇所がハイライトされる

### Testing Approach

- **Playwright** でブラウザ自動化テスト
- テストデータのセットアップ・クリーンアップ（Firestore エミュレーター使用）

## Performance / Load Tests

### Performance Targets

1. **API レスポンスタイム**: 95 パーセンタイル < 1 秒（全エンドポイント）
2. **OCR 処理時間**: アップロードから完了まで < 30 秒
3. **ページ読み込み時間**: First Contentful Paint (FCP) < 1.5 秒、Largest Contentful Paint (LCP) < 2.5 秒
4. **同時ユーザー数**: 100 ユーザーが同時アクセスしても API レスポンスタイムが 2 秒未満

### Testing Approach

- **Apache JMeter** または **Locust** で負荷テスト
- Cloud Run の自動スケーリング動作を検証（min: 0, max: 10 インスタンス）

## Test Coverage Goals

- **Unit Tests**: コードカバレッジ 80% 以上
- **Integration Tests**: 主要フロー 100% カバー
- **E2E Tests**: クリティカルパス 100% カバー

## CI/CD Integration

- **Cloud Build** または **GitHub Actions** で自動テスト実行
- Pull Request マージ前に全テストを自動実行
- テスト失敗時はマージをブロック
