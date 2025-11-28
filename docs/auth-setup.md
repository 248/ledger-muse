# NextAuth ローカルセットアップ手順 (Google OAuth)

フロントエンドの NextAuth v5(beta) をローカルで動かすための最小手順です。認証は Google OAuth を前提にしています。

## 前提
- Google Cloud または Google アカウントで OAuth クライアントID/シークレットを作成できること
- フロントエンド依存がインストール済み (`npm install`)

## 1. Google OAuth クライアント作成
1. Google Cloud Console → 「API とサービス」→「認証情報」→「認証情報を作成」→「OAuth クライアント ID」
2. アプリケーションの種類: 「ウェブアプリケーション」
3. 生成された `クライアントID` と `クライアント シークレット` を控える
4. 生成後に「承認済みのリダイレクト URI」を追加  
   - ローカル開発: `http://localhost:3000/api/auth/callback/google`

## 2. 環境変数を設定 (.env.local)
`frontend/.env.local.example` をコピーして `.env.local` を作成し、以下を埋めます:
```
AUTH_SECRET=ランダム文字列
AUTH_GOOGLE_ID=<上で控えたクライアントID>
AUTH_GOOGLE_SECRET=<上で控えたクライアントシークレット>
# Identity Platform を issuer にする場合のみ設定
# AUTH_GOOGLE_ISSUER=https://accounts.google.com
# AUTH_TOKEN_ENDPOINT=https://oauth2.googleapis.com/token
```

## 3. 起動と確認
```bash
cd frontend
npm run dev
# ブラウザで http://localhost:3000/login にアクセスし Google ログインボタンを押下
```
- ログイン成功後は `/dashboard` にリダイレクトされ、ユーザー名とメールが表示されます。

## 4. Backend `/api/v1/me` のローカル確認
NextAuth から取得した ID トークンを Echo 側で検証します。エミュレーター利用時は認証レスポンスが匿名になるため、実トークンでの疎通確認は Identity Platform / Firebase Auth 本番プロジェクトを想定してください（学習用にはエミュレーターで 200 応答までを確認）。

### 環境変数
`backend/.env` を用意し、少なくとも以下を設定:
```
PORT=8080
GO_ENV=local
FIREBASE_PROJECT_ID=demo-no-project        # プロジェクトID（必須）
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 # エミュレーターを使う場合
```
※ 実トークンを検証する場合は `FIREBASE_AUTH_EMULATOR_HOST` を空にし、適切なサービスアカウント認証を別途設定してください。

### 起動と疎通
```bash
cd backend
go run ./cmd/api
# または air 等のホットリロードで起動
```

NextAuth 側でサインイン後、ブラウザのネットワークタブや curl で:
```bash
curl -H "Authorization: Bearer <id_token>" http://localhost:8080/api/v1/me
```
期待値: `{"userId":"...","email":"..."}` が返却され、無効トークンやヘッダー欠落時は 401 となる。

### 実トークンを検証する場合（Identity Platform / Firebase Auth 本番）
1. `FIREBASE_PROJECT_ID` に本番/テストの GCP プロジェクトIDを設定（エミュレーター環境変数は外す）。
2. サービスアカウントを用意してキーを取得し、`GOOGLE_APPLICATION_CREDENTIALS` で指定:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
   export FIREBASE_PROJECT_ID=<your-project-id>
   go run ./cmd/api
   ```
   - 権限は最小で「Firebase Admin SDK（Identity Platform）」相当が必要（例: `roles/identitytoolkit.admin` または Firebase Admin 権限を含むカスタムロール）。
   - gcloud の ADC を使う場合は `gcloud auth application-default login` でも可（ただし個人資格に依存するのでサービスアカウント推奨）。
3. フロントで Google サインインして得た ID トークンを `/api/v1/me` に付与して確認。

## 4. よくあるハマりどころ
- リダイレクト URI 未設定: Google で `redirect_uri_mismatch` が出る。上記 URI を追加して再試行。
- シークレット未設定: 500 エラーになる。`.env.local` を再確認。
- issuer を Identity Platform に切り替える場合: `AUTH_GOOGLE_ISSUER` を IdP の issuer に設定し、IdP 側で同じリダイレクト URI を許可する。
