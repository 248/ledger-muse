# CI/CD Secrets (Firebase App Hosting)

Firebase App Hosting のワークフローで必要な GitHub Secrets:

- `FIREBASE_PROJECT_ID`: Firebase プロジェクト ID（例: `ledger-muse`）
- `FIREBASE_SERVICE_ACCOUNT`: デプロイ用サービスアカウントの JSON 資格情報（必須権限: App Hosting Admin/Editor 相当）
- `FIREBASE_APPHOSTING_SITE_PROD`: `main` 用の App Hosting サイト ID
- `FIREBASE_APPHOSTING_SITE_STAGING`: `develop`／PR 用の App Hosting サイト ID

メモ:
- サイト ID は Firebase コンソールの App Hosting で確認可能。
- PR では `GITHUB_HEAD_REF` をブランチ名としてデプロイしプレビュー URL が生成される。
- キーはリポジトリに置かず、GitHub Actions の Secrets にのみ保存する。

### 発行手順（例）
1. GCP コンソール → 「IAM と管理」→「サービス アカウント」→ 新規作成（例: `firebase-apphosting-deployer`）。
2. 権限例: Firebase Hosting Admin（App Hosting 管理を含む）＋必要なら Service Usage Admin / Storage Admin。
3. サービスアカウント詳細 →「鍵」→「鍵を追加」→「新しい鍵を作成」→「JSON」でダウンロード。
4. ダウンロードした JSON の内容を `FIREBASE_SERVICE_ACCOUNT` にそのまま貼り付けて GitHub Secrets に登録。
5. `FIREBASE_PROJECT_ID` は Firebase プロジェクト ID を手入力。`FIREBASE_APPHOSTING_SITE_*` は App Hosting のサイト ID をコンソールで確認。
6. Terraformで自動化できる部分: サービスアカウント作成・ロール付与（`google_service_account`、`google_project_iam_member`）。App Hosting サイト作成や GH Secrets 登録は手作業。

---

# CI/CD Secrets (Cloud Run Deploy)

GitHub Actions `.github/workflows/deploy-backend.yml` で必要な Secrets/設定:

- `GCP_PROJECT_ID`: デプロイ先 Google Cloud プロジェクト ID
- `WIF_PROVIDER`: Workload Identity Federation Provider リソースパス（例: `projects/123456/locations/global/workloadIdentityPools/gh-pool/providers/gh`）
- `WIF_SERVICE_ACCOUNT`: Workload Identity で紐づけるサービスアカウント（例: `github-deployer@<project>.iam.gserviceaccount.com`）
- （任意）`REGION`: 既定は `asia-northeast1`、変更時はワークフロー env を更新

Deploy では Artifact Registry `asia-northeast1-docker.pkg.dev/<PROJECT_ID>/ledger-muse/<SERVICE_NAME>` へ push したイメージを Cloud Run へデプロイする。

### 発行手順（WIF の例）
1. GCP コンソール → IAM と管理 → Workload Identity プールを作成（`gh-pool` など）。
2. プール内でプロバイダを作成（GitHub OIDC 用）。`WIF_PROVIDER` に表示されたリソースパスを控える。
3. デプロイ用サービスアカウント作成（例: `github-deployer@<project>.iam.gserviceaccount.com`）、必要なロール（Cloud Run Admin、Artifact Registry Writer、Service Account Token Creator、など最小権限）を付与。
4. サービスアカウントの「Workload Identity ユーザー」権限を、上記プロバイダに紐づく主体へ付与。
5. GitHub Secrets に `GCP_PROJECT_ID`, `WIF_PROVIDER`, `WIF_SERVICE_ACCOUNT` を登録。キーは不要（WIF 認証のため）。

Terraformで自動化できる部分:
- `google_service_account`, `google_project_iam_member` で SA 作成とロール付与
- `google_iam_workload_identity_pool`, `google_iam_workload_identity_pool_provider` で WIF プール/プロバイダ
- `google_service_account_iam_member` で `roles/iam.workloadIdentityUser` を GitHub OIDC principal に付与  
手作業が必要な部分:
- GitHub Actions Secrets 登録（Terraform では GH Secrets へ書き込めない）
- App Hosting サイト ID の生成/確認（コンソールまたは `firebase apphosting:sites:create` / `:list`）
- 詳細な Terraform 手順は `docs/terraform-wif.md` を参照。
