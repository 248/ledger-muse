# Terraform で Firebase App Hosting 用サービスアカウントを作成する手順

App Hosting へのデプロイ専用サービスアカウント（例: `firebase-apphosting-deployer`）を Terraform で作成します。**鍵の発行と GH Secrets 登録は手作業**で行ってください（秘密鍵を state に残さないため）。

## 前提
- Terraform 1.6+ / google provider 5.x
- プロジェクトの課金有効化と App Hosting 利用（Blaze プラン）

## 手順
```bash
cd terraform/apphosting

# 共通変数: ../common.auto.tfvars を編集（project_id/region）。初回のみ。
# 個別変数はサンプルをコピーして編集。
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform plan  -var-file=../common.auto.tfvars
terraform apply -var-file=../common.auto.tfvars
```

## GitHub Actions への反映（手作業）
- `FIREBASE_SERVICE_ACCOUNT`: 上記で作成した SA の JSON キーをコンソール/`gcloud iam service-accounts keys create` で発行し、GitHub Secrets にそのまま貼り付け（鍵をリポジトリには置かない）。
- `FIREBASE_PROJECT_ID`: Firebase プロジェクト ID
- `FIREBASE_APPHOSTING_SITE_*`: App Hosting で作成したサイト ID（コンソール or `firebase apphosting:sites:list` で確認）

## 注意
- 秘密鍵は Terraform で生成しない。state に残るため、必ず手作業でキーを発行し Secrets で管理する。 
- 必要に応じてロールを追加する場合は `service_account_roles` を編集。
