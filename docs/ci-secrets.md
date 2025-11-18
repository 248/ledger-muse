# CI/CD Secrets (Firebase App Hosting)

Firebase App Hosting のワークフローで必要な GitHub Secrets:

- `FIREBASE_PROJECT_ID`: Firebase プロジェクト ID（例: `ledger-muse`）
- `FIREBASE_SERVICE_ACCOUNT`: デプロイ用サービスアカウントの JSON 資格情報（必須権限: App Hosting Admin/Editor 相当）
- `FIREBASE_APPHOSTING_SITE_PROD`: `main` 用の App Hosting サイト ID
- `FIREBASE_APPHOSTING_SITE_STAGING`: `develop`／PR 用の App Hosting サイト ID

メモ:
- サイト ID は Firebase コンソールの App Hosting で確認可能。
- PR では `GITHUB_HEAD_REF` をブランチ名としてデプロイしプレビュー URL が生成される。
