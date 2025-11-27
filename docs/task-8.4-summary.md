# タスク 8.4 実装サマリー: App Hosting 環境変数のTerraform管理

## 実装日時
2025-11-26

## 実装方針
Test-Driven Development (TDD) に基づく strict モードで実装

## 実装内容

### 1. Secret Manager モジュールの作成

**場所**: `terraform/modules/secret-manager/`

**ファイル構成**:
- `main.tf`: Secret リソース、バージョン管理、IAM権限設定
- `variables.tf`: モジュール入力変数定義
- `outputs.tf`: Secret 名、ID、バージョンの出力
- `README.md`: モジュール使用ガイド

**主な機能**:
- Google Cloud Secret Manager での Secret 作成
- Secret のバージョン管理
- サービスアカウントへの IAM アクセス制御（`roles/secretmanager.secretAccessor`）
- 自動レプリケーション設定
- カスタムラベル対応

### 2. Staging環境への統合

**変更ファイル**:
- `terraform/environments/staging/main.tf`:
  - Secret Manager API の有効化
  - `backend_api_url_secret` モジュールの追加
- `terraform/environments/staging/variables.tf`:
  - `backend_api_url`: Backend API の URL
  - `backend_api_url_secret_id`: Secret ID（`BACKEND_API_BASE_STAGING`）
  - `backend_api_url_secret_accessors`: アクセス権を持つサービスアカウントリスト
- `terraform/environments/staging/outputs.tf`:
  - `backend_api_url_secret_name`: Secret のフルリソース名
  - `backend_api_url_secret_id`: Secret ID

### 3. App Hosting 設定ファイルの作成

**ファイル**:
- `frontend/apphosting.yaml`: Production 環境設定（プレースホルダー）
- `frontend/apphosting.staging.yaml`: Staging 環境設定

**Staging 設定のポイント**:
```yaml
env:
  - variable: NEXT_PUBLIC_BACKEND_API_BASE
    secret: BACKEND_API_BASE_STAGING
    availability:
      - BUILD
      - RUNTIME
```

これにより、App Hosting は Secret Manager から環境変数を動的に読み込みます。

### 4. テストの作成

**新規テスト**:
- `tests/terraform-secret-manager.test.sh`:
  - Secret Manager モジュールの構造検証
  - Staging 環境への統合検証
  - App Hosting YAML ファイルの存在確認
  - Secret 参照設定の検証

**既存テストの更新**:
- `tests/terraform-modules.test.sh`:
  - Secret Manager モジュールの検証ルールを追加

### 5. ドキュメントの作成・更新

**新規ドキュメント**:
- `docs/terraform/secret-manager.md`: デプロイガイド
- `terraform/modules/secret-manager/README.md`: モジュールドキュメント
- `terraform/environments/staging/secret-manager.auto.tfvars.example`: 設定例

**更新ドキュメント**:
- `docs/terraform/README.md`: モジュールカタログに Secret Manager を追加

## TDD サイクル

### RED (失敗するテストの作成)
- `tests/terraform-secret-manager.test.sh` を作成
- 実行結果: FAIL（モジュールが存在しない）

### GREEN (最小限のコードで実装)
- Secret Manager モジュールの作成
- Staging 環境への統合
- App Hosting YAML ファイルの作成
- 実行結果: PASS（すべてのテスト成功）

### REFACTOR (リファクタリング)
- モジュール README の追加
- デプロイガイドの作成
- 既存テストへの統合
- ドキュメントの更新

### VERIFY (品質検証)
- Terraform 構文検証: ✅ PASS
- 全テスト実行: ✅ PASS
- モジュール単体テスト: ✅ PASS
- 統合テスト: ✅ PASS

## 成果物

1. **Terraform モジュール**: `terraform/modules/secret-manager/`
2. **環境設定**: `terraform/environments/staging/` の更新
3. **App Hosting 設定**: `frontend/apphosting.yaml`, `frontend/apphosting.staging.yaml`
4. **テストスイート**: `tests/terraform-secret-manager.test.sh`
5. **ドキュメント**: `docs/terraform/secret-manager.md`

## 検証方法

### ローカルテスト（デプロイ前）
```bash
# 全テスト実行
./tests/terraform-modules.test.sh
./tests/terraform-secret-manager.test.sh

# Terraform 構文検証
cd terraform/modules/secret-manager
terraform init
terraform validate
```

### デプロイ後の検証
```bash
# Secret の確認
gcloud secrets list --filter="name:BACKEND_API_BASE_STAGING"
gcloud secrets versions access latest --secret="BACKEND_API_BASE_STAGING"

# IAM 権限の確認
gcloud secrets get-iam-policy BACKEND_API_BASE_STAGING
```

## デプロイ手順

詳細は `docs/terraform/secret-manager.md` を参照してください。

### 概要
1. App Hosting サービスアカウントの確認
2. `secret-manager.auto.tfvars` の作成
3. Terraform 実行（init, plan, apply）
4. Secret の検証

## セキュリティ対策

1. **最小権限の原則**: App Hosting SA のみにアクセス権付与
2. **Secret のバージョン管理**: Terraform が自動管理
3. **ログへの記録禁止**: `sensitive = true` マーク
4. **暗号化**: Secret Manager の自動暗号化を使用

## 今後のアクション

1. **デプロイ実施**: Staging 環境へ Terraform apply
2. **App Hosting 連携**: Firebase Console で App Hosting を Staging ブランチに接続
3. **動作確認**: フロントエンドから Backend API への疎通確認
4. **本番環境準備**: Production 環境用の Secret 設定

## 参照リンク

- [Secret Manager モジュール](../terraform/modules/secret-manager/README.md)
- [デプロイガイド](terraform/secret-manager.md)
- [Terraform 総合ガイド](terraform/README.md)
- [Firebase App Hosting 公式ドキュメント](https://firebase.google.com/docs/app-hosting/configure)

## 要件トレーサビリティ

- **Requirement 11.8**: 機密情報管理（Secret Manager）
- **Requirement 17.5**: Terraform モジュール
- **Requirement 19.5**: 機密情報のログ記録禁止
