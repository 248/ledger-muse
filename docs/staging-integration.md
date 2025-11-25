# Staging フロントエンド ⇔ バックエンド疎通確認手順 (Phase 1 / Task 8.2)

Firebase App Hosting (Frontend) から Cloud Run (Backend) への HTTPS 呼び出しを検証するための手順です。CORS とレスポンスタイム (<1s 目標) を確認します。

## 事前準備
- Cloud Run Staging サービス URL（例: `https://ledger-muse-api-staging-xxxx.a.run.app`）
- Firebase App Hosting (Staging/Preview) の URL（PR プレビューまたは main/develop 用）
- App Hosting 環境変数 `NEXT_PUBLIC_BACKEND_API_BASE` を Cloud Run URL に設定
  - Firebase Console > App Hosting > Environment variables で更新
  - または `firebase hosting:channel:deploy` 時に `.env.staging` 等で指定

## 確認手順
1. デプロイ後、フロント URL にアクセスし、ヒーロー下の「バックエンド接続」カードで「バックエンド: OK (vX.X.X)」が表示されることを確認。エラーメッセージが出る場合は CORS/URL を再確認。
2. Cloud Run `/health` を直接確認（レスポンス <1s 目標、HTTPS 必須）:
   ```bash
   curl -w "status=%{http_code} time_total=%{time_total}\n" \
     -s -o /dev/null https://ledger-muse-api-staging-xxxx.a.run.app/health
   ```
   - 200 が返り、`time_total` が 1 秒未満であることを確認。
3. CORS 失敗時は Cloud Run 側のレスポンスヘッダ、または App Hosting 側の `NEXT_PUBLIC_BACKEND_API_BASE` を再確認。ローカル再現は `NEXT_PUBLIC_BACKEND_API_BASE=http://localhost:8080 npm run dev` で可能。

## 成果物
- ブラウザでの表示確認（「バックエンド: OK ...」）
- `/health` への HTTPS curl ログ（200 / <1s）

