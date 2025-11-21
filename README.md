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
# コンテナのビルドと起動 (Docker Compose v2)
docker compose up -d --build

# Docker Compose v1 の場合
# docker-compose up --build -d

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

### フロントエンドの起動

フロントエンドはホストで起動します。

```bash
cd frontend
npm install
npm run dev
```

## 環境変数

### テンプレートの配置

- フロントエンド: `frontend/.env.local.example` をコピーして `frontend/.env.local` を作成
- バックエンド: `backend/.env.example` をコピーして `backend/.env` を作成

### 推奨設定（ローカル + エミュレータ）

`frontend/.env.local`

```
NEXT_PUBLIC_BACKEND_API_BASE=http://localhost:8080
NEXT_PUBLIC_FIREBASE_PROJECT_ID=demo-no-project
NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST=http://localhost:9099
NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST=localhost:8080
NEXT_PUBLIC_FIREBASE_STORAGE_EMULATOR_HOST=http://localhost:9199
```

`backend/.env`

```
PORT=8080
GO_ENV=local
FIREBASE_PROJECT_ID=demo-no-project
FIREBASE_AUTH_EMULATOR_HOST=http://localhost:9099
FIRESTORE_EMULATOR_HOST=localhost:8080
STORAGE_EMULATOR_HOST=http://localhost:9199
PUBSUB_EMULATOR_HOST=localhost:8085
```

### よくあるハマりどころ（Firebase Emulator）

- **Javaが無い**: `java -version` で失敗する場合、JDK をインストールして PATH を通す
- **webframeworks が有効でない**: `firebase experiments:enable webframeworks` を実行（Firebase Hosting を Emulator する場合のみ）
- **プロジェクト未指定エラー**: `firebase emulators:start --project demo-no-project --only auth,firestore,storage,pubsub` のように `--project` を明示
- **docker compose の --build フラグエラー**: Compose v2 では `docker compose up -d --build`（または `docker-compose up --build -d`）を使用
