# ledger-muse

モノレポ構成で Ledger Muse を構築します。

## ディレクトリ

- `frontend/`: Next.js (TypeScript) を置く予定のフロントエンド
- `backend/`: Go + Echo を置く予定のバックエンド
- `terraform/`: GCP リソースをコード化する Terraform 定義

## 初期セットアップ

- まずは各ディレクトリに実装を追加し、`tests/structure.test.sh` が通ることを確認してください。
