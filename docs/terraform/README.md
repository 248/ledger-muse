# Terraform 手順 総合ガイド

目的: Terraform 手順を一本化し、共通前提と実行順序を示します。各モジュール固有の詳細は近接する README に記載し、このガイドからリンクします。

## 共通前提
- Terraform 1.9.0〜1.x / google provider 5.x
- `terraform/common.auto.tfvars` に `project_id` / `region` を設定（`common.auto.tfvars.example` をコピーして編集）
- `terraform init/plan/apply` 実行時は `-var-file=../common.auto.tfvars` を添付

### 環境ディレクトリ
`terraform/environments/{staging,prod}` は環境ごとの root モジュール置き場です。`terraform/backend.tf` / `provider.tf` をコピーして GCS backend + provider を揃え、`terraform -chdir=terraform/environments/<env>` で plan/apply を実行します。

## 実行順序
1) **リモートステートバケット (Bootstrap)**  
   - 目的: GCS に Terraform state を置くためのバケット作成  
   - ドキュメント: `docs/terraform/bootstrap.md`  
   - 変数: `terraform/bootstrap/terraform.tfvars` （`state_admin_members` を設定）

2) **Terraform Runner SA**  
   - 目的: Terraform を実行する専用 SA を用意し、state バケット操作やリソース作成を人に依存させない  
   - ドキュメント: `docs/terraform/iam-runner.md`  
   - 手順: `terraform/iam-runner/` で tfvars 作成 → `init/plan/apply -var-file=../common.auto.tfvars`

3) **WIF + デプロイ用 SA**  
   - 目的: GitHub Actions からのデプロイ権限付与 (Workload Identity + SA)  
   - ドキュメント: `docs/terraform/wif.md`  
   - 手順: `terraform/wif/` で tfvars 作成 → `init/plan/apply -var-file=../common.auto.tfvars`

4) **App Hosting 用 SA**  
   - 目的: Firebase App Hosting 用デプロイ SA 作成  
   - ドキュメント: `docs/terraform/apphosting.md`  
   - 手順: `terraform/apphosting/` で tfvars 作成 → `init/plan/apply -var-file=../common.auto.tfvars`

5) **環境ごとのモジュール適用**
  - 例: Artifact Registry / Cloud Run / Firestore / Storage / PubSub など
  - `terraform/environments/<env>/main.tf` で必要なモジュールを呼び出し、`-var-file=../common.auto.tfvars` を指定して plan/apply する
  - **TIP**: `main.tf` で新しいモジュールを追加・変更した場合は、`terraform init` を再実行して依存モジュールをダウンロードする
  - **Staging Artifact Registry (タスク2.4)**
    1. `terraform -chdir=terraform/environments/staging init -backend-config="bucket=${PROJECT_ID}-terraform-state"`
    2. `terraform -chdir=terraform/environments/staging plan -var-file=../../common.auto.tfvars`
    3. `terraform -chdir=terraform/environments/staging apply -var-file=../../common.auto.tfvars`
    4. CLI: `gcloud artifacts repositories list --location=asia-northeast1 --project=ledger-muse | grep ledger-muse`
    5. コンソール: Google Cloud Console → Artifact Registry → プロジェクト `ledger-muse` / リージョン `asia-northeast1` を選択し、`ledger-muse` リポジトリが表示されることを確認
  - **Backend API Service Account (タスク2.5)**
    1. (Artifact Registryと同じ `terraform/environments/staging` ディレクトリで) `terraform -chdir=terraform/environments/staging init -backend-config="bucket=${PROJECT_ID}-terraform-state"` を再実行して `modules/iam` を取得
    2. `terraform -chdir=terraform/environments/staging plan -var-file=../../common.auto.tfvars`
    3. `terraform -chdir=terraform/environments/staging apply -var-file=../../common.auto.tfvars`
    4. `module "backend_api_service_account"` が `modules/iam` を呼び出し、`backend_api_service_account_roles` に Firestore/Storage/PubSub + Service Usage のロールを付与（Vision API はまだ最小構成のため省略。必要になったら tfvars 側で追加可能）
    5. CLI: `gcloud iam service-accounts list --project=ledger-muse | grep backend-api-staging-sa`
    6. コンソール: Google Cloud Console → IAM と管理 → サービスアカウント → プロジェクト `ledger-muse` で `backend-api-staging-sa` が存在し、該当ロールが付与されていることを確認
    7. Cloud Run (タスク2.6) ではこの SA のメールアドレスを参照する
  - **Cloud Run 初期定義 (タスク2.6)**
    1. `terraform -chdir=terraform/environments/staging init -backend-config="bucket=${PROJECT_ID}-terraform-state"` （Cloud Run モジュール追加後に再取得）
    2. `terraform -chdir=terraform/environments/staging plan -var-file=../../common.auto.tfvars`
    3. `terraform -chdir=terraform/environments/staging apply -var-file=../../common.auto.tfvars`
    4. `module "backend_api_cloud_run"` が `modules/cloud-run` を呼び出し、`backend_api_cloud_run_*` 変数からサービス名/イメージ/スケーリング/ENVを注入し、`module.backend_api_service_account.service_account_email` を実行時 SA として紐付ける
    5. CLI: `gcloud run services list --region=asia-northeast1 --project=ledger-muse | grep ledger-muse-api-staging` でサービス存在を確認
    6. CLI: `gcloud run services describe ledger-muse-api-staging --region=asia-northeast1 --project=ledger-muse --format='value(status.url)'` → 得られた URL を `curl` して placeholder 応答を確認
    7. コンソール: Google Cloud Console → Cloud Run → プロジェクト `ledger-muse` / リージョン `asia-northeast1` を選択し、`ledger-muse-api-staging` サービスの `Details` タブで URL と Service Account (`backend-api-staging-sa`) が紐付いていることを確認
    8. 将来 GitHub Actions からイメージを差し替えるまでは、`backend_api_cloud_run_container_image` 変数 (現状 `gcr.io/cloudrun/hello`) を placeholder として保持する
  - モジュールを追加したらこのガイドに用途と順序を追記する

## モジュールカタログ

| モジュール | ディレクトリ | 主な役割 | 主な入出力 |
|------------|--------------|----------|------------|
| Artifact Registry | `terraform/modules/artifact-registry` | Docker レジストリを `format = \"DOCKER\"` で作成し、URL/リソース名を出力 | `repository_id`, `region` / `repository_url` |
| Backend IAM | `terraform/modules/iam` | Backend API 実行用のサービスアカウントを作成し、指定したロールを一括付与 | `service_account_id`, `service_account_roles` / `service_account_email` |
| Cloud Run | `terraform/modules/cloud-run` | 指定イメージを Cloud Run にデプロイし、min/max スケール注釈とメモリ/CPU を設定 | `service_name`, `container_image`, `service_account_email` / `service_url` |
| Storage | `terraform/modules/storage` | Cloud Storage バケットを作成し、ライフサイクル削除と任意の KMS 暗号化を設定 | `bucket_name`, `lifecycle_age_days`, `kms_key_name` / `bucket_url` |

> これらのモジュールは `tests/terraform-modules.test.sh` で構造を検証しており、新規変更時はテストも更新してください。

## 運用ルール
- 共通設定は本ガイドと `common.auto.tfvars` に集約し、モジュール README には差分・注意点のみを書く
- 新しいモジュールを追加したら: (a) モジュール直下に README を作成、(b) 本ガイドの「実行順序」に追記
- 機密情報（サービスアカウント鍵など）は手動発行し、GitHub Secrets 等で管理する。state に含めない
