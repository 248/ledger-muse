# Terraform Bootstrap 手順書（リモートステートバケット）

この手順は Terraform state を格納する GCS バケットを作成するための最小構成です。実リソースはまだ作成していません。

## 前提
- gcloud で対象プロジェクトに認証済み (`gcloud auth application-default login` 等)
- Terraform v1.6+ / google provider v5+
- `terraform/common.auto.tfvars` に `project_id` / `region` を設定済み（`common.auto.tfvars.example` をコピーして編集）

## 使い方
1) 共通変数を設定  
`terraform/common.auto.tfvars` を編集。未作成なら `common.auto.tfvars.example` をコピー。

2) 個別変数を設定  
`terraform/bootstrap/terraform.tfvars.example` を `terraform.tfvars` にコピーし、`state_admin_members` を編集。  
初回は人のアカウントでOK。あとで作成する Terraform Runner SA を追加することを推奨します。  
例:  
```hcl
state_admin_members = [
  "user:you@example.com",
  "serviceAccount:terraform-runner@${project_id}.iam.gserviceaccount.com",
]
```
location を変えたい場合のみ上書き。

3) 実行  
```bash
cd terraform/bootstrap
terraform init
terraform plan  -var-file=../common.auto.tfvars
terraform apply -var-file=../common.auto.tfvars
```

## できあがるもの
- バケット: `${project_id}-terraform-state`（region は `common.auto.tfvars` の `region` を使用）
  - UBLA 有効、Public Access Prevention enforced、Versioning ON、prevent_destroy 付き
- IAM: `roles/storage.objectAdmin` を `state_admin_members` に付与

## 検証
```bash
gsutil ls "gs://${TF_VAR_project_id}-terraform-state"
gsutil iam get "gs://${TF_VAR_project_id}-terraform-state"
```

## 運用上の注意
- バケットは `prevent_destroy` を設定。削除が必要な場合は一時的に外してから実施
- 後続の Terraform ワークスペース（staging/prod）で `backend.tf` を GCS バックエンドに切り替える前に、このバケットを作成・確認
- IAM 付与は objectAdmin のみ。組織ポリシーで Block Public Access が強制されている場合でも、この設定はそれに従う
