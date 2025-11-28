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

## 4. よくあるハマりどころ
- リダイレクト URI 未設定: Google で `redirect_uri_mismatch` が出る。上記 URI を追加して再試行。
- シークレット未設定: 500 エラーになる。`.env.local` を再確認。
- issuer を Identity Platform に切り替える場合: `AUTH_GOOGLE_ISSUER` を IdP の issuer に設定し、IdP 側で同じリダイレクト URI を許可する。
