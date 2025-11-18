# Terraform での WIF / デプロイ SA 設定手順

このディレクトリを用いて GitHub OIDC (WIF) + デプロイ用サービスアカウントを作成します。GitHub Secrets への設定のみ手作業が必要です。

## 前提
- Terraform 1.6+ / google provider 5.x
- GCP プロジェクトと課金有効化済み
- 実行者がプロジェクトオーナー相当の権限を持つこと

## 主要リソース
- `google_service_account`：デプロイ用 SA（既定ID: `github-deployer`）
- `google_iam_workload_identity_pool` / `..._provider`：GitHub OIDC 用 WIF プール/プロバイダ
- `google_service_account_iam_member`：`roles/iam.workloadIdentityUser` を GitHub リポジトリに付与
- `google_project_iam_member`：Run/Admin, Artifact Registry Writer, Service Account User などデプロイ権限

## 使い方
```bash
cd terraform/wif

cat > terraform.tfvars <<'EOF'
project_id           = "your-gcp-project-id"
github_repository    = "owner/repo"              # 例: ledger-muse/ledger-muse
service_account_id   = "github-deployer"
service_account_roles = [
  "roles/run.admin",
  "roles/artifactregistry.writer",
  "roles/iam.serviceAccountUser"
]
EOF

terraform init
terraform plan
terraform apply
```

エラー回避のヒント:
- Workload Identity Provider の `attribute_condition` は `attribute.repository` によるリポジトリ限定を設定済み。`github_repository` を存在する `owner/repo` 形式で指定すること。
- それでも 400 エラー（conditions まわり）が出る場合は、`terraform state rm` などで既存プロバイダ差分を整理し、`apply` を再実行。

## GitHub Actions への反映（手作業）
- `GCP_PROJECT_ID`: `project_id`
- `WIF_PROVIDER`: `terraform output wif_provider_name`
- `WIF_SERVICE_ACCOUNT`: `terraform output service_account_email`
- Firebase/App Hosting 用キー(`FIREBASE_SERVICE_ACCOUNT`)は別途サービスアカウントキーを発行し Secrets に保存
- App Hosting のサイト ID はコンソールまたは `firebase apphosting:sites:list` で確認し Secrets へ

## カスタマイズ例
- 特定ブランチのみ許可: `github_repository` の代わりに `google_service_account_iam_member.member` を `principal://.../attribute.sub==\"repo:owner/repo:ref:refs/heads/main\"` などへ編集
- 付与ロールの追加/削除: `service_account_roles` を編集
- プール/プロバイダの ID 変更: `wif_pool_id`, `wif_provider_id` を tfvars で上書き
