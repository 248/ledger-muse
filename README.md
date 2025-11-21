# ledger-muse

モノレポ構成で Ledger Muse を構築します。

## ディレクトリ

- `frontend/`: Next.js (TypeScript) を置く予定のフロントエンド
- `backend/`: Go + Echo を置く予定のバックエンド
- `terraform/`: GCP リソースをコード化する Terraform 定義

## 初期セットアップ

- まずは各ディレクトリに実装を追加し、`tests/structure.test.sh` が通ることを確認してください。

## ローカル開発 (Firebase Emulator Suite)

- 前提: `npm install -g firebase-tools` で Firebase CLI を用意します。
- 実験フラグ: App Hosting を含む設定のため `firebase experiments:enable webframeworks` を 1 度だけ実行してください。
- プロジェクト指定: 実プロジェクト ID またはデモ ID を指定します（例: `--project demo-no-project`）。一度設定する場合は `firebase use --add` で選択可能。
- 起動: `firebase emulators:start --only auth,firestore,storage,pubsub --project demo-no-project` を実行すると、UI が http://localhost:4000 で立ち上がります。
- ポート: Auth 9099 / Firestore 8080 / Storage 9199 / Pub/Sub 8085 / Emulator UI 4000。
