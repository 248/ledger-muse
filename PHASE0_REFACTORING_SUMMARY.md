# Phase 0 タスク・設計書の修正サマリー

## 修正日時
2025-11-19

## 修正の背景

### 問題点
1. **タスク順序の矛盾**: タスク2.3（Cloud Runデプロイ）がタスク3.4（Artifact Registry作成）よりも先に実施され、デプロイが失敗
2. **設計書の不足**: インフラ（Terraform）の設計書が存在せず、CI/CDとインフラの依存関係が不明確
3. **Phase 0の目的不明確**: 何を達成すべきかが曖昧で、タスクの優先順位が不適切

### 根本原因
- CI/CDとインフラの実施順序が逆転していた
- Artifact RegistryやサービスアカウントなどのGCPリソースが、Cloud Runデプロイの前提条件であることが明示されていなかった

---

## 修正内容

### 1. 新規作成ファイル

#### `/Volumes/develop/github/ledger-muse/.kiro/specs/household-finance-app/design/infrastructure.md`

**概要**: Terraformによるインフラ構成管理（IaC）の設計書

**主要セクション**:
- **インフラストラクチャ概要**: GCPサービス構成、リージョン設定
- **環境分離戦略**: Local/Staging/Productionの分離方法
- **Terraform構成管理**: ディレクトリ構造、リモートステート、モジュール設計
- **Terraformモジュール設計**:
  - Artifact Registry（Dockerイメージレジストリ）
  - Cloud Run（Backend APIホスティング）
  - IAM（サービスアカウント、権限管理、WIF）
  - Storage（レシート画像保存）
  - Pub/Sub（非同期メッセージング）
  - Monitoring（アラート設定）
  - KMS（暗号鍵管理）
- **Phase 0でのインフラ構築順序**: 依存関係を明示した実施順序
- **IAM最小権限設計**: サービスアカウント構成、Workload Identity Federation
- **セキュリティ設定**: Cloud Run、Cloud Storageのセキュリティ対策
- **モニタリング・アラート**: 監視対象メトリクス、ログ保持ポリシー
- **コスト最適化**: 学習段階のコスト削減策、推定月間コスト

**重要な設計ポイント**:
```
1. リモートステートバケット作成（手動 or 初回Terraform）
   ↓
2. Terraformプロジェクト初期化
   ↓
3. Terraformモジュール作成（IAM、Artifact Registry）
   ↓
4. Artifact Registryリポジトリ作成 ← CI/CDのデプロイで必須
   ↓
5. Staging環境Terraform定義（Cloud Run、Backend SA）
   ↓
6. CI/CD Cloud Runデプロイパイプライン実装
   （この時点でArtifact Registryとサービスアカウントが存在）
```

---

### 2. 更新ファイル

#### `/Volumes/develop/github/ledger-muse/.kiro/specs/household-finance-app/design/cicd.md`

**追加セクション**: 「インフラストラクチャ前提条件」（47行目から101行目）

**追加内容**:
- **品質ゲート（Lint/Test/Build）の前提条件**: なし（GCP不要）
- **Firebase App Hostingデプロイの前提条件**: なし（Firebase側で完結）
- **Cloud Runデプロイの前提条件**: 以下のTerraformリソースが必須
  1. Artifact Registry リポジトリ
  2. Backend APIサービスアカウント（IAM権限付与済み）
  3. Workload Identity Federation（推奨）
  4. Cloud Run サービス（初回のみTerraformで作成）

**デプロイフロー**:
```
GitHub Actions
  ↓
1. Dockerイメージビルド
  ↓
2. Artifact Registryへプッシュ（Terraform作成済み）
  ↓
3. Cloud Runへデプロイ（サービスアカウント使用）
```

---

#### `/Volumes/develop/github/ledger-muse/.kiro/specs/household-finance-app/tasks.md`

**Phase 0の全面修正**

##### 修正方針
1. **タスク順序の修正**: インフラ（Terraform）→ CI/CD品質ゲート → Cloud Runデプロイ
2. **Phase 0の再構成**:
   - 1. 開発環境セットアップ
   - 2. Terraform基盤構築（★順序を前倒し）
   - 3. CI/CD品質ゲートとFirebase App Hosting
   - 4. Cloud Runデプロイパイプライン
   - 5. ローカル開発環境セットアップ
3. **タスクの分割と明確化**: 各タスクに以下を追加
   - **前提条件**: 依存するタスク番号
   - **成果物**: ファイルパスやリソース名
   - **検証方法**: 成功確認の手順
4. **既完了タスクの扱い**:
   - タスク1.1, 1.2, 1.3（開発環境）: ✅ 維持
   - タスク3.1（品質ゲート）: ✅ 維持
   - タスク3.2（App Hosting）: ✅ 維持
   - タスク4.1（Cloud Runデプロイ）: ⚠️ 「ワークフローファイル作成のみ完了、実行確認は未完了」として扱う

##### 新しいタスク構造

**1. 開発環境セットアップ**（変更なし）
- [x] 1.1 リポジトリとディレクトリ構造の初期化
- [x] 1.2 Frontend プロジェクトの初期化
- [x] 1.3 Backend プロジェクトの初期化

**2. Terraform基盤構築**（旧タスク3、順序を前倒し）
- [ ] 2.1 リモートステートバケット作成（Terraform Bootstrap）
- [ ] 2.2 Terraform プロジェクト初期化
- [ ] 2.3 (P) Terraform モジュール作成（基本リソース）
  - `modules/artifact-registry/`
  - `modules/iam/`
  - `modules/cloud-run/`
  - `modules/storage/`
- [ ] 2.4 (P) Artifact Registry リポジトリ作成（Terraform apply）
  - **重要**: このタスク完了後、CI/CDでDockerイメージをプッシュ可能になる
- [ ] 2.5 Backend API サービスアカウント作成（Terraform apply）
  - サービスアカウント作成（`backend-api-staging-sa`）
  - IAM権限付与（Firestore、Storage、Vision API、Pub/Sub）
  - Workload Identity Federation 設定
  - **重要**: このタスク完了後、Cloud Runデプロイ時にサービスアカウントを指定可能
- [ ] 2.6 Staging 環境 Cloud Run 初期定義（Terraform apply）
  - Cloud Run サービス作成（`ledger-muse-api-staging`）
  - コンテナイメージはプレースホルダー（`gcr.io/cloudrun/hello`）
  - 以降のデプロイはGitHub Actionsで更新
- [ ] 2.7* Queue/Async 基盤スキャフォールド（Terraform）
  - **注意**: Phase 4まで延期可能（OCR機能実装時に必須）
- [ ] 2.8* KMS キーリング/キー雛形（Terraform）
  - **注意**: Phase 7まで延期可能（暗号化強化時に必須）
- [ ] 2.9* Monitoring/Alerting 雛形（Terraform）
  - **注意**: Phase 7まで延期可能（運用監視強化時に必須）

**3. CI/CD品質ゲートとFirebase App Hosting**（旧タスク2.1, 2.2）
- [x] 3.1 GitHub Actions 品質ゲートワークフロー作成
  - **前提条件**: タスク1.2, 1.3完了
  - Frontend 品質ゲート（ESLint、TypeScript、Vitest）
  - Backend 品質ゲート（golangci-lint、`go test`、`go build`）
- [x] 3.2 (P) Firebase App Hosting の GitHub 統合
  - **前提条件**: なし（Firebase側で完結）

**4. Cloud Runデプロイパイプライン**（旧タスク2.3、依存関係を明確化）
- [ ] 4.1 (P) Cloud Run デプロイワークフロー実装
  - **前提条件**: タスク2.4, 2.5, 2.6完了（Artifact Registry、SA、Cloud Runが存在）
  - Workload Identity Federation による GCP 認証
  - Dockerイメージビルド
  - Artifact Registry へのイメージプッシュ
  - Cloud Run へのデプロイ（Staging環境、PR preview、Production）
  - デプロイ後のヘルスチェック
  - **検証方法**: PR作成→デプロイ成功→`curl https://{cloud-run-url}/health` で200 OK確認
  - **重要**: ワークフローファイル自体は既に作成済みだが、実行確認は未完了

**5. ローカル開発環境セットアップ**（旧タスク4）
- [ ] 5.1 Firebase Emulator Suite のセットアップ
- [ ] 5.2 Docker Compose 環境構築（Colima + Docker）
- [ ] 5.3 環境変数設定
- [ ] 5.4 ローカル環境の起動確認
- [ ] 5.5 (P) Cloud Vision API モックの実装
  - **注意**: Phase 4まで延期可能（OCR機能実装時に必須）

**Phase 0 完了基準**（新規追加）:
1. **開発環境**: Frontend/Backendプロジェクトが初期化され、品質ゲートが通過する
2. **Terraform基盤**: Artifact Registry、サービスアカウント、Cloud Runが作成され、Terraformで管理されている
3. **CI/CD**: 品質ゲート、Firebase App Hosting、Cloud Runデプロイが動作する
4. **ローカル環境**: Firebase Emulator、Docker Composeでローカル開発が可能
5. **検証**: PR作成→品質ゲート通過→Cloud Runデプロイ成功→エンドポイント確認

---

## 修正による影響

### 今後の実施順序（Phase 0）

```
【完了済み】
✅ 1. 開発環境セットアップ（1.1, 1.2, 1.3）
✅ 3. CI/CD品質ゲート（3.1）
✅ 3. Firebase App Hosting（3.2）
⚠️ 4. Cloud Runデプロイワークフロー（4.1: ファイル作成済み、実行確認は未完了）

【未実施、優先度高】
🔴 2. Terraform基盤構築（2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.6）
   ↓ この完了後に ↓
🟡 4. Cloud Runデプロイパイプライン実行確認（4.1）

【未実施、優先度中】
🟢 5. ローカル開発環境セットアップ（5.1 → 5.2 → 5.3 → 5.4）

【未実施、延期可能】
⚪ 2.7* Queue/Async 基盤（Phase 4まで延期可能）
⚪ 2.8* KMS（Phase 7まで延期可能）
⚪ 2.9* Monitoring/Alerting（Phase 7まで延期可能）
⚪ 5.5 (P) Cloud Vision API モック（Phase 4まで延期可能）
```

### 次のステップ

1. **タスク2.1**: リモートステートバケット作成
   - GCPプロジェクト確認
   - Terraform CLI インストール確認
   - バケット作成（手動 or bootstrap Terraform）

2. **タスク2.2**: Terraform プロジェクト初期化
   - `terraform/` ディレクトリ構造作成
   - `provider.tf`, `backend.tf`, `common.auto.tfvars` 作成
   - `terraform init` 実行

3. **タスク2.3**: Terraform モジュール作成
   - `modules/artifact-registry/`, `modules/iam/`, `modules/cloud-run/`, `modules/storage/` 作成
   - 各モジュールの `main.tf`, `variables.tf`, `outputs.tf` 実装

4. **タスク2.4, 2.5, 2.6**: Terraform apply
   - Artifact Registry作成
   - サービスアカウント作成
   - Cloud Run初期デプロイ

5. **タスク4.1**: Cloud Runデプロイパイプライン実行確認
   - PR作成
   - GitHub Actions実行確認
   - デプロイ成功確認
   - エンドポイント確認

---

## 変更の正当性

### なぜこの順序が正しいのか

1. **Artifact Registryが先**: Dockerイメージのプッシュ先が存在しないと、CI/CDデプロイが失敗する
2. **サービスアカウントが先**: Cloud Runサービスの実行アカウントが存在しないと、デプロイが失敗する
3. **Workload Identity Federationが先**: GitHub ActionsからGCPへの認証が必要
4. **Terraformでインフラを一元管理**: インフラをコード化し、環境再現性を確保

### CI/CDとインフラの分離

- **品質ゲート**: GCPリソースに依存しない→ インフラ構築前に実施可能
- **Firebase App Hosting**: Firebase側で完結→ GCPインフラと独立
- **Cloud Runデプロイ**: GCPリソース（Artifact Registry、SA）に依存→ インフラ構築後に実施

---

## 設計書の整合性

### infrastructure.md と cicd.md の関係

- **infrastructure.md**: 「何を」作るか（GCPリソース、Terraformモジュール）
- **cicd.md**: 「どうデプロイするか」（GitHub Actions、ワークフロー）
- **前提条件の明示**: cicd.mdの「インフラストラクチャ前提条件」セクションで、infrastructure.mdで定義されたリソースへの依存を明記

### tasks.md と設計書の整合性

- **tasks.md**: 設計書に基づいた具体的な実装手順
- **前提条件・成果物・検証方法**: 各タスクが設計書のどの部分を実装するかを明確化
- **Requirements紐付け**: 要件（requirements.md）との紐付けを維持

---

## まとめ

### 主な変更点

1. **インフラ設計書の新規作成** (`infrastructure.md`)
2. **CI/CD設計書の更新** (`cicd.md`): インフラ前提条件セクション追加
3. **タスク一覧の全面修正** (`tasks.md`): Phase 0の順序修正、依存関係明示

### 期待される効果

1. **タスク実施順序の明確化**: インフラ → CI/CDの順序が明確になり、デプロイ失敗を回避
2. **依存関係の可視化**: 各タスクの前提条件、成果物、検証方法が明示され、進捗管理が容易
3. **設計書の完備**: インフラ、CI/CD、タスクの3つが整合性を持って記述され、プロジェクト全体の見通しが向上
4. **学習効果の向上**: Terraformによるインフラ構成管理、CI/CDの実装順序を体系的に学習可能

### 今後の運用

- **Phase 0完了基準**: 明確な完了基準により、Phase 1への移行判断が容易
- **延期可能タスクの明示**: Queue/Async、KMS、Monitoring/Alertingは将来のフェーズで実施可能と明記
- **ローカル開発環境**: GCPに依存せず、ローカルで開発可能な環境を構築

---

## 補足: Phase 2以降について

**今回の修正範囲**: Phase 0のみ

**Phase 2以降の扱い**:
- タスク番号の調整は必要だが、今回は実施せず
- Phase 1完了後に、Phase 2以降のタスク番号を整理する予定

---

以上
