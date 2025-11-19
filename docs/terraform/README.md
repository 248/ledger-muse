# Terraform 手順 総合ガイド

目的: Terraform 手順を一本化し、共通前提と実行順序を示します。各モジュール固有の詳細は近接する README に記載し、このガイドからリンクします。

## 共通前提
- Terraform 1.6+ / google provider 5.x
- `terraform/common.auto.tfvars` に `project_id` / `region` を設定（`common.auto.tfvars.example` をコピーして編集）
- `terraform init/plan/apply` 実行時は `-var-file=../common.auto.tfvars` を添付

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

5) **環境ごとのモジュール適用 (今後追加)**  
   - 例: Artifact Registry / Cloud Run / Firestore / Storage / PubSub など  
   - 追加モジュールはそれぞれのディレクトリに README を置き、このガイドにリンクを追記する

## 運用ルール
- 共通設定は本ガイドと `common.auto.tfvars` に集約し、モジュール README には差分・注意点のみを書く
- 新しいモジュールを追加したら: (a) モジュール直下に README を作成、(b) 本ガイドの「実行順序」に追記
- 機密情報（サービスアカウント鍵など）は手動発行し、GitHub Secrets 等で管理する。state に含めない
