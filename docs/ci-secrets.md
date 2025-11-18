# CI/CD Secrets (Firebase App Hosting)

Firebase App Hosting のワークフローで必要な GitHub Secrets:

- `FIREBASE_PROJECT_ID`: Firebase プロジェクト ID（例: `ledger-muse`）
- `FIREBASE_SERVICE_ACCOUNT`: デプロイ用サービスアカウントの JSON 資格情報（必須権限: App Hosting Admin/Editor 相当）
- `FIREBASE_APPHOSTING_SITE_PROD`: `main` 用の App Hosting サイト ID
- `FIREBASE_APPHOSTING_SITE_STAGING`: `develop`／PR 用の App Hosting サイト ID

メモ:
- サイト ID は Firebase コンソールの App Hosting で確認可能。
- PR では `GITHUB_HEAD_REF` をブランチ名としてデプロイしプレビュー URL が生成される。

---

# CI/CD Secrets (Cloud Run Deploy)

GitHub Actions `.github/workflows/deploy-backend.yml` で必要な Secrets/設定:

- `GCP_PROJECT_ID`: デプロイ先 Google Cloud プロジェクト ID
- `WIF_PROVIDER`: Workload Identity Federation Provider リソースパス（例: `projects/123456/locations/global/workloadIdentityPools/gh-pool/providers/gh`）
- `WIF_SERVICE_ACCOUNT`: Workload Identity で紐づけるサービスアカウント（例: `github-deployer@<project>.iam.gserviceaccount.com`）
- （任意）`REGION`: 既定は `asia-northeast1`、変更時はワークフロー env を更新

Deploy では Artifact Registry `asia-northeast1-docker.pkg.dev/<PROJECT_ID>/ledger-muse/<SERVICE_NAME>` へ push したイメージを Cloud Run へデプロイする。
