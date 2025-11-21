# ledger-muse

モノレポ構成で Ledger Muse を構築します。

## ディレクトリ

- `frontend/`: Next.js (TypeScript) を置く予定のフロントエンド
- `backend/`: Go + Echo を置く予定のバックエンド
- `terraform/`: GCP リソースをコード化する Terraform 定義

## 初期セットアップ

- まずは各ディレクトリに実装を追加し、`tests/structure.test.sh` が通ることを確認してください。

## ローカル開発 (Docker Compose)

Docker Composeを使用してbackend + Firebase Emulatorを一括で起動できます。

### 必要なツール

- Docker Desktop または Colima + Docker
  - macOS (Colima): `brew install colima docker docker-compose`
  - Colima 初期化:
    ```bash
    colima start \
      --cpu 2 \
      --memory 4 \
      --mount /Volumes/develop:w
    ```
    ※ `/Volumes/develop:w` はプロジェクトのパスに応じて調整してください（`:w`は書き込み可能の意味）

### 起動方法

```bash
# コンテナのビルドと起動
docker-compose up --build -d

# ログの確認
docker-compose logs -f

# 停止
docker-compose down
```

### アクセス先

- **Backend API**: http://localhost:8080/health
- **Firebase Emulator UI**: http://localhost:4000
- **Firebase Auth**: http://localhost:9099
- **Firebase Firestore**: http://localhost:9000 (内部では8080)
- **Firebase Storage**: http://localhost:9199
- **Firebase Pub/Sub**: http://localhost:8085

### 開発時の注意

- **backendホットリロード**: `air`によるホットリロードが有効（ポーリングモード）
  - ファイルを変更すると自動的にリビルド・再起動されます
  - `.air.toml`で`poll = true`を設定済み
- **Firebase設定ファイル**: `firebase.json`, `firestore.rules`, `storage.rules`
- **Colimaマウント**: ホットリロードを有効にするため、プロジェクトディレクトリをマウントして起動してください
