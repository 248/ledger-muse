# Terraform Environments

`terraform/environments` には staging / prod など環境ごとの root モジュールを配置します。各ディレクトリでは `main.tf` からモジュールを呼び出し、`backend.tf`/`provider.tf` は `terraform/` 直下の共通定義をベースにコピーして利用します。

- `staging/`: テスト・検証環境。Artifact Registry / Cloud Run / Firestore 等を段階的に構築予定。
- `prod/`: 本番環境。staging と同じ構造を保ちつつスケール・権限を本番向けに調整します。

後続タスク（2.3 以降）で各ディレクトリに `main.tf` や変数ファイルを追加し、`terraform -chdir=terraform/environments/<env>` で操作します。
