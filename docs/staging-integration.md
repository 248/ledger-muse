# Staging フロントエンド ⇔ バックエンド疎通確認手順 (Phase 1 / Task 8.2)

Firebase App Hosting (Frontend) から Cloud Run (Backend) への HTTPS 呼び出しを検証するための手順です。CORS とレスポンスタイム (<1s 目標) を確認します。

## 事前準備

### 1. Secret Manager にバックエンド URL を登録

Cloud Run Staging サービス URL を Secret Manager に登録します。

```bash
# Secret の作成
echo -n "https://ledger-muse-api-staging-xxxx.a.run.app" | \
  gcloud secrets create BACKEND_API_BASE_STAGING \
  --data-file=- \
  --project=ledger-muse-staging

# または既存の Secret を更新
echo -n "https://ledger-muse-api-staging-xxxx.a.run.app" | \
  gcloud secrets versions add BACKEND_API_BASE_STAGING \
  --data-file=- \
  --project=ledger-muse-staging
```

### 2. App Hosting の `apphosting.yaml` で Secret を参照

```yaml
# apphosting.yaml または apphosting.staging.yaml
env:
  - variable: NEXT_PUBLIC_BACKEND_API_BASE
    secret: BACKEND_API_BASE_STAGING
    availability:
      - BUILD
      - RUNTIME
```

> **注意**: 
> - Firebase Console の App Hosting 画面には環境変数を直接編集する UI はありません
> - 環境変数は `apphosting.yaml` + Secret Manager で管理します
> - Secret Manager を使うことで、機密情報をリポジトリにコミットせずに管理できます

### 3. App Hosting に Secret Manager へのアクセス権限を付与

App Hosting が Secret Manager にアクセスできるよう、サービスアカウントに権限を付与します。

```bash
# App Hosting のサービスアカウントに Secret Manager の権限を付与
gcloud secrets add-iam-policy-binding BACKEND_API_BASE_STAGING \
  --member="serviceAccount:firebase-app-hosting@ledger-muse-staging.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=ledger-muse-staging
```

> **注意**: サービスアカウント名は環境によって異なる場合があります。Firebase Console の App Hosting > 設定 からサービスアカウントを確認してください。

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

