# Terraform Runner サービスアカウント手順

目的: Terraform の実行主体を専用 SA に固定し、人依存を減らしつつ state 操作権限を明確化します。

## 前提
- Terraform 1.6+ / google provider 5.x
- `terraform/common.auto.tfvars` に `project_id` / `region` を設定済み
- state バケットは `bootstrap` 手順で作成済み（初回は人の権限で作成）

## 使い方
```bash
cd terraform/iam-runner

# 個別変数を用意（例をコピー）
cp terraform.tfvars.example terraform.tfvars
# 必要ロールを project_roles に追加（最小限に絞る）

terraform init
terraform plan  -var-file=../common.auto.tfvars
terraform apply -var-file=../common.auto.tfvars
```

### 推奨ロール例
- state バケット: `roles/storage.objectAdmin`（state_admin_members にも後で追加）
- 管理するリソースに合わせて最小権限を追加  
  - Artifact Registry 管理が必要なら: `roles/artifactregistry.admin`  
  - Cloud Run 管理が必要なら: `roles/run.admin`  
  - SA 作成が必要なら: `roles/iam.serviceAccountAdmin` + `roles/iam.serviceAccountUser`

### バケット権限への反映（具体的な手順）
1. runner のメールを取得  
   ```bash
   terraform -chdir=terraform/iam-runner output -raw service_account_email
   # 例: terraform-runner@ledger-muse-478602.iam.gserviceaccount.com
   ```
2. `terraform/bootstrap/terraform.tfvars` に追記  
   ```hcl
   state_admin_members = [
     "user:あなたのメール",
     "serviceAccount:terraform-runner@ledger-muse-478602.iam.gserviceaccount.com",
   ]
   ```
3. bootstrap を再適用（state バケットに権限付与）  
   ```bash
   terraform -chdir=terraform/bootstrap init
   terraform -chdir=terraform/bootstrap plan  -var-file=../common.auto.tfvars
   terraform -chdir=terraform/bootstrap apply -var-file=../common.auto.tfvars
   ```

### runner を使って Terraform を実行する
- 一時的に runner をインパーソネートして実行する例:  
  ```bash
  export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$(terraform -chdir=terraform/iam-runner output -raw service_account_email)
  terraform -chdir=terraform/wif plan  -var-file=../common.auto.tfvars
  terraform -chdir=terraform/wif apply -var-file=../common.auto.tfvars
  ```
- CI で WIF を使う場合は、GitHub Actions 側で同じ SA をインパーソネートする設定を行う。

## 運用の流れ（推奨）
1. bootstrap で state バケット作成（人権限）  
2. 本モジュールで runner SA 作成＋必要ロール付与  
3. bootstrap に runner を追加して再 `apply`（バケット操作権限を runner に付与）  
4. 以降の Terraform は runner SA（WIF/ADC）で実行
