# Requirements Document

## Project Description (Input)
個人利用から始めて将来的に商用運用も視野に、クラウド基盤（Google Cloud）上で「家計簿機能＋レシート画像OCR＋ナレッジ（メモ・検索）機能」を備えた Web アプリを構築し、認証・ファイルアップロード・DB接続など実務で使う API／インフラ設計を学習する。

## Introduction
本仕様書は、Google Cloud 上で動作する家計簿管理 Web アプリケーション「Ledger Muse」の要件を定義します。本アプリケーションは、収支管理、レシート画像からの自動データ抽出、メモ・検索機能を統合し、個人利用から将来的な商用展開までをカバーする拡張可能なアーキテクチャを目指します。

### 技術スタック概要
- **フロントエンド**: Next.js (TypeScript)
- **バックエンド**: Go + Echo フレームワーク
- **認証**: Google Cloud Identity Platform
- **データベース**: Firestore（学習期）→ Cloud SQL (PostgreSQL)（将来移行）
- **ストレージ**: Cloud Storage
- **OCR**: Cloud Vision API
- **非同期処理**: Pub/Sub + Cloud Tasks
- **インフラ管理**: Terraform (IaC)
- **CI/CD**: Cloud Build + Artifact Registry
- **監視**: Cloud Monitoring + Cloud Logging + Cloud Trace
- **セキュリティ**: Cloud Armor (WAF) + IAM 最小権限設計

### プロジェクト方針
- 学習目的かつ低コスト運用を前提とし、将来的な商用化に対応できる設計とする
- 2025年11月時点で安定実績のある技術を選定し、ベータ版や極端に採用例の少ないライブラリは避ける
- インフラ構成管理を Terraform でコード化し、環境分離（dev/staging/prod）を実践する

## Requirements

### Requirement 1: ユーザー認証・アカウント管理
**Objective:** As a ユーザー, I want 安全にログインしてアカウントを管理したい, so that 自分のデータを保護し、複数デバイスからアクセスできる

#### Acceptance Criteria
1. The Ledger Muse システム shall Google Cloud Identity Platform を使用して認証機能を実装する
2. When ユーザーが新規登録フォームを送信した時, the Ledger Muse システム shall Identity Platform 経由でメールアドレスとパスワードでアカウントを作成する
3. When ユーザーがログインフォームを送信した時, the Ledger Muse システム shall Identity Platform で認証情報を検証し、成功時にIDトークンを発行する
4. If 無効な認証情報が入力された場合, then the Ledger Muse システム shall エラーメッセージを表示し、ログインを拒否する
5. When ユーザーがログアウトボタンをクリックした時, the Ledger Muse システム shall セッションを無効化し、ログイン画面にリダイレクトする
6. The Ledger Muse システム shall パスワードをハッシュ化して保存する（Identity Platform 管理）
7. While セッションが有効な間, the Ledger Muse システム shall ユーザーのアクセストークンを自動更新する
8. When パスワードリセットがリクエストされた時, the Ledger Muse システム shall 登録メールアドレスに確認リンクを送信する
9. The Ledger Muse システム shall 将来的に多要素認証（MFA）を実装可能な構造を持つ

### Requirement 2: 収支記録の登録・管理
**Objective:** As a ユーザー, I want 収入と支出を記録・管理したい, so that 家計の状況を正確に把握できる

#### Acceptance Criteria
1. When ユーザーが取引登録フォームを送信した時, the Ledger Muse システム shall 日付、金額、カテゴリ、メモを含む取引レコードを作成する
2. When ユーザーが取引一覧画面を開いた時, the Ledger Muse システム shall 登録済み取引を新しい順に表示する
3. When ユーザーが取引を編集した時, the Ledger Muse システム shall 該当レコードを更新し、変更履歴を記録する
4. When ユーザーが取引を削除した時, the Ledger Muse システム shall 該当レコードを論理削除する
5. If 必須項目（日付、金額、カテゴリ）が未入力の場合, then the Ledger Muse システム shall 登録を拒否し、エラーメッセージを表示する
6. The Ledger Muse システム shall 収入と支出を区別して記録する
7. While 取引一覧を表示している間, the Ledger Muse システム shall 月次・週次・日次の集計情報を同時に表示する
8. The Ledger Muse システム shall ユーザー単位にデータを隔離し、他ユーザーのデータにアクセスできないようにする

### Requirement 3: カテゴリ管理
**Objective:** As a ユーザー, I want 収支のカテゴリを自由に設定・管理したい, so that 自分の家計状況に合わせた分類ができる

#### Acceptance Criteria
1. When ユーザーが新規カテゴリを作成した時, the Ledger Muse システム shall カテゴリ名と色情報を保存する
2. When ユーザーがカテゴリを編集した時, the Ledger Muse システム shall カテゴリ情報を更新し、関連する取引にも反映する
3. When ユーザーがカテゴリを削除しようとした時, the Ledger Muse システム shall 該当カテゴリを使用している取引の有無を確認する
4. If 使用中のカテゴリを削除しようとした場合, then the Ledger Muse システム shall 警告メッセージを表示し、代替カテゴリの選択を促す
5. The Ledger Muse システム shall 収入用と支出用のカテゴリを別々に管理する
6. The Ledger Muse システム shall デフォルトカテゴリ（食費、交通費、給与など）を初期登録時に提供する

### Requirement 4: レシート画像アップロード
**Objective:** As a ユーザー, I want レシート画像をアップロードしたい, so that 紙のレシートを保管せずにデジタル管理できる

#### Acceptance Criteria
1. When ユーザーがレシート画像を選択してアップロードボタンをクリックした時, the Ledger Muse システム shall 画像ファイルを Google Cloud Storage にアップロードする
2. When 画像アップロードが完了した時, the Ledger Muse システム shall アップロード完了通知を表示し、画像 URL を取引レコードに関連付ける
3. When 画像アップロードが完了した時, the Ledger Muse システム shall Pub/Sub にメッセージを発行してOCR処理をトリガーする
4. If アップロードファイルが画像形式でない場合, then the Ledger Muse システム shall アップロードを拒否し、エラーメッセージを表示する
5. If ファイルサイズが制限（10MB）を超える場合, then the Ledger Muse システム shall アップロードを拒否し、サイズ制限を通知する
6. The Ledger Muse システム shall JPEG, PNG, HEIC 形式の画像をサポートする
7. When ユーザーが取引詳細を表示した時, the Ledger Muse システム shall 関連するレシート画像のサムネイルを表示する
8. When ユーザーがサムネイルをクリックした時, the Ledger Muse システム shall レシート画像をフルサイズで表示する

### Requirement 5: レシート OCR 処理（非同期）
**Objective:** As a ユーザー, I want レシート画像から情報を自動抽出したい, so that 手入力の手間を省ける

#### Acceptance Criteria
1. When Pub/Sub から OCR 処理メッセージを受信した時, the Ledger Muse システム shall Cloud Tasks 経由でワーカーを起動する
2. When ワーカーが起動した時, the Ledger Muse システム shall Google Cloud Vision API を使用して OCR 処理を実行する
3. When OCR 処理が完了した時, the Ledger Muse システム shall 抽出された金額、日付、店舗名をデータベースに保存する
4. When OCR 処理結果が保存された時, the Ledger Muse システム shall フロントエンドに通知し、取引フォームに自動入力する
5. If OCR 処理が失敗した場合, then the Ledger Muse システム shall エラーログを記録し、ユーザーに手動入力モードを提示する
6. While OCR 処理中の間, the Ledger Muse システム shall フロントエンドで処理中インジケーターを表示する
7. When OCR 結果が取引フォームに反映された時, the Ledger Muse システム shall ユーザーが内容を確認・修正できる状態で表示する
8. The Ledger Muse システム shall OCR 抽出結果の信頼度スコアを記録する
9. If 金額が複数検出された場合, then the Ledger Muse システム shall 最も可能性の高い合計金額を選択する
10. The Ledger Muse システム shall OCR 処理がアップロードから30秒以内に完了することを目標とする

### Requirement 6: ナレッジ管理（メモ機能）
**Objective:** As a ユーザー, I want 取引に関するメモを自由に追加・編集したい, so that 後で詳細を思い出せる

#### Acceptance Criteria
1. When ユーザーが取引にメモを追加した時, the Ledger Muse システム shall メモ内容を取引レコードに関連付けて保存する
2. When ユーザーが取引一覧を表示した時, the Ledger Muse システム shall メモが存在する取引にアイコンを表示する
3. When ユーザーがメモアイコンをクリックした時, the Ledger Muse システム shall メモ内容をポップアップで表示する
4. The Ledger Muse システム shall メモ内容にマークダウン記法をサポートする
5. When ユーザーがメモを編集した時, the Ledger Muse システム shall 編集履歴のタイムスタンプを記録する
6. The Ledger Muse システム shall メモ内容の最大文字数を 5000 文字に制限する
7. The Ledger Muse システム shall メモにタグ付け機能を提供する

### Requirement 7: 検索機能
**Objective:** As a ユーザー, I want 取引やメモを検索したい, so that 過去の記録を素早く見つけられる

#### Acceptance Criteria
1. When ユーザーが検索キーワードを入力して検索ボタンをクリックした時, the Ledger Muse システム shall 取引の金額、カテゴリ、メモ、タグから該当する結果を検索する
2. When 検索結果が表示された時, the Ledger Muse システム shall マッチした箇所をハイライト表示する
3. When ユーザーが日付範囲を指定して検索した時, the Ledger Muse システム shall 指定期間内の取引のみを結果に含める
4. When ユーザーがカテゴリフィルタを適用した時, the Ledger Muse システム shall 選択されたカテゴリの取引のみを表示する
5. If 検索結果が 0 件の場合, then the Ledger Muse システム shall 「該当する取引が見つかりません」というメッセージを表示する
6. The Ledger Muse システム shall 部分一致検索をサポートする
7. While 検索フィルタが適用されている間, the Ledger Muse システム shall 現在のフィルタ条件を画面上部に表示する

### Requirement 8: 集計・レポート機能
**Objective:** As a ユーザー, I want 収支の集計やレポートを確認したい, so that 家計の傾向を把握できる

#### Acceptance Criteria
1. When ユーザーがダッシュボードを開いた時, the Ledger Muse システム shall 当月の収入・支出・残高の合計を表示する
2. When ユーザーが集計期間を選択した時, the Ledger Muse システム shall 選択期間のカテゴリ別支出をグラフで表示する
3. When ユーザーが月次レポートを表示した時, the Ledger Muse システム shall 前月比較データを含めて表示する
4. The Ledger Muse システム shall 円グラフ、棒グラフ、折れ線グラフで集計データを可視化する
5. When ユーザーがグラフをクリックした時, the Ledger Muse システム shall 該当期間・カテゴリの取引明細にドリルダウンする
6. The Ledger Muse システム shall 週次、月次、年次の集計を提供する
7. When ユーザーがレポートをエクスポートした時, the Ledger Muse システム shall CSV 形式でダウンロード可能にする
8. The Ledger Muse システム shall 将来的に BigQuery を使用した高度な分析機能を実装可能な構造を持つ

### Requirement 9: データベース設計・管理
**Objective:** As a システム管理者, I want データを安全かつ効率的に保存・管理したい, so that アプリケーションの信頼性とパフォーマンスを確保できる

#### Acceptance Criteria
1. The Ledger Muse システム shall 学習段階では Firestore をデータベースとして使用する
2. The Ledger Muse システム shall 将来的に Cloud SQL (PostgreSQL) へ移行可能なデータ構造を設計する
3. The Ledger Muse システム shall ユーザーデータ、取引レコード、カテゴリ、メモを正規化可能な構造で管理する
4. When データベース接続エラーが発生した時, the Ledger Muse システム shall 自動再接続を試行し、エラーログを記録する
5. The Ledger Muse システム shall トランザクション処理により、データの整合性を保証する
6. The Ledger Muse システム shall 定期的な自動バックアップを実行する
7. If データベース容量が 80% を超えた場合, then the Ledger Muse システム shall アラート通知を送信する
8. The Ledger Muse システム shall ユーザー単位にデータを隔離する設計を採用する

### Requirement 10: API 設計
**Objective:** As a 開発者, I want RESTful API を設計・実装したい, so that フロントエンドとバックエンドを疎結合に保てる

#### Acceptance Criteria
1. The Ledger Muse システム shall Go 言語と Echo フレームワークを使用して API を実装する
2. The Ledger Muse システム shall RESTful API 設計原則に従った エンドポイントを提供する
3. The Ledger Muse システム shall JSON 形式でリクエスト・レスポンスをやり取りする
4. When API リクエストが成功した時, the Ledger Muse システム shall 適切な HTTP ステータスコード（200, 201, 204）を返す
5. If API リクエストがエラーの場合, then the Ledger Muse システム shall エラー詳細を含むレスポンス（400, 401, 404, 500）を返す
6. The Ledger Muse システム shall 全ての API エンドポイントに認証トークンの検証を実装する
7. The Ledger Muse システム shall API バージョニング（/api/v1/）をサポートする
8. When API リクエストが受信された時, the Ledger Muse システム shall リクエストログを記録する

### Requirement 11: セキュリティ・認可
**Objective:** As a システム管理者, I want セキュアなアクセス制御を実装したい, so that ユーザーデータを不正アクセスから保護できる

#### Acceptance Criteria
1. The Ledger Muse システム shall Google Cloud Identity Platform のトークンベース認証を実装する
2. When ユーザーが他のユーザーのデータにアクセスしようとした時, the Ledger Muse システム shall アクセスを拒否し、403 エラーを返す
3. The Ledger Muse システム shall HTTPS 通信を強制する
4. The Ledger Muse システム shall 転送中のデータを TLS 暗号化で保護する
5. The Ledger Muse システム shall 保存中の機密データ（画像、DB）を暗号化する
6. The Ledger Muse システム shall CORS (Cross-Origin Resource Sharing) ポリシーを適切に設定する
7. If 連続してログイン失敗が 5 回発生した場合, then the Ledger Muse システム shall アカウントを一時的にロックする
8. The Ledger Muse システム shall 機密情報（パスワード、トークン）をログに記録しない
9. When セキュリティ関連のイベントが発生した時, the Ledger Muse システム shall セキュリティログに記録する
10. The Ledger Muse システム shall 将来的に Cloud Armor (WAF) を導入し、DDoS攻撃や不正アクセスから保護する

### Requirement 12: インフラストラクチャ（Google Cloud）
**Objective:** As a システム管理者, I want Google Cloud 上で拡張可能なインフラを構築したい, so that 将来的な商用運用に対応できる

#### Acceptance Criteria
1. The Ledger Muse システム shall Google Cloud Run でバックエンド API をホスティングする
2. The Ledger Muse システム shall Google Cloud Storage でレシート画像を保存する
3. The Ledger Muse システム shall Firestore（初期）または Cloud SQL（将来）でデータベースを管理する
4. The Ledger Muse システム shall Google Cloud Vision API で OCR 処理を実行する
5. The Ledger Muse システム shall Pub/Sub でメッセージングを実装する
6. The Ledger Muse システム shall Cloud Tasks で非同期処理ワーカーを管理する
7. When アプリケーションのトラフィックが増加した時, the Ledger Muse システム shall 自動スケーリングを実行する
8. The Ledger Muse システム shall Cloud Monitoring でアプリケーションのメトリクスを収集する
9. The Ledger Muse システム shall Cloud Logging でログを一元管理する
10. The Ledger Muse システム shall Cloud Trace で分散トレーシングを実装する
11. If システムエラーが発生した場合, then the Ledger Muse システム shall Cloud Logging にエラー詳細を記録する
12. The Ledger Muse システム shall 開発環境（dev）、ステージング環境（staging）、本番環境（prod）を分離する
13. The Ledger Muse システム shall 全てのインフラ構成を Terraform でコード化する

### Requirement 13: フロントエンド UI/UX
**Objective:** As a ユーザー, I want 使いやすく直感的な Web インターフェースを利用したい, so that ストレスなく家計簿を管理できる

#### Acceptance Criteria
1. The Ledger Muse システム shall Next.js (TypeScript) を使用してフロントエンドを実装する
2. The Ledger Muse システム shall レスポンシブデザインでモバイル・タブレット・デスクトップに対応する
3. When ユーザーが画面を操作した時, the Ledger Muse システム shall 300ms 以内にフィードバックを表示する
4. The Ledger Muse システム shall 日本語 UI を提供する
5. When データ読み込み中の時, the Ledger Muse システム shall ローディングインジケーターを表示する
6. If ユーザーが破壊的操作（削除など）を実行しようとした場合, then the Ledger Muse システム shall 確認ダイアログを表示する
7. The Ledger Muse システム shall アクセシビリティ標準（WCAG 2.1 AA）に準拠する
8. When ユーザーがフォームに無効なデータを入力した時, the Ledger Muse システム shall リアルタイムでバリデーションエラーを表示する

### Requirement 14: 拡張性・将来対応
**Objective:** As a プロダクトオーナー, I want 将来的な機能拡張に対応できる設計にしたい, so that 商用運用時にスムーズに移行できる

#### Acceptance Criteria
1. The Ledger Muse システム shall マルチテナント対応可能なデータ構造を採用する
2. The Ledger Muse システム shall 機能ごとにモジュール化された コードベースを維持する
3. Where 有料プラン機能が追加される場合, the Ledger Muse システム shall プラン別の機能制限を管理できる
4. The Ledger Muse システム shall API レート制限を実装可能な構造を持つ
5. The Ledger Muse システム shall 多言語対応（i18n）のための構造を用意する
6. The Ledger Muse システム shall サードパーティ連携（銀行 API など）のための拡張ポイントを持つ
7. The Ledger Muse システム shall 将来的にキャッシュ層（Memorystore/Redis）を導入可能な構造を持つ
8. The Ledger Muse システム shall 将来的に CDN 配信を導入可能な構造を持つ

### Requirement 15: 運用・監視
**Objective:** As a システム管理者, I want システムの健全性を監視・管理したい, so that 問題を早期に発見し対処できる

#### Acceptance Criteria
1. The Ledger Muse システム shall アプリケーションログを構造化ログ（JSON 形式）で出力する
2. When システムエラーが発生した時, the Ledger Muse システム shall エラーレベル（INFO, WARN, ERROR）に応じてログを記録する
3. The Ledger Muse システム shall API レスポンスタイム、エラー率、リクエスト数をメトリクスとして収集する
4. If API レスポンスタイムが 3 秒を超えた場合, then the Ledger Muse システム shall アラートを発報する
5. The Ledger Muse システム shall ヘルスチェックエンドポイント（/health）を提供する
6. When ヘルスチェックが実行された時, the Ledger Muse システム shall データベース接続状態を含むステータスを返す
7. The Ledger Muse システム shall 週次でシステム稼働レポートを生成する
8. The Ledger Muse システム shall Cloud Trace で分散トレーシングを実装し、パフォーマンスボトルネックを特定する
9. The Ledger Muse システム shall SLO（Service Level Objective）を定義し、達成状況を監視する
10. The Ledger Muse システム shall CI/CD パイプライン（Cloud Build）でユニットテストと E2E テストを自動実行する

### Requirement 16: 技術選定基準
**Objective:** As a 開発者, I want 安定した技術スタックを採用したい, so that 将来の保守性と拡張性を確保できる

#### Acceptance Criteria
1. The Ledger Muse システム shall 2025年11月時点で安定実績のある技術を採用する
2. If 新規技術を導入する場合, then the Ledger Muse システム shall 実務採用実績と将来性を評価する
3. The Ledger Muse システム shall ベータ版や極端に採用例の少ないライブラリを原則避ける
4. When 技術選定を行う時, the Ledger Muse システム shall コミュニティサポート、ドキュメント品質、セキュリティアップデート頻度を考慮する
5. The Ledger Muse システム shall 依存ライブラリのバージョン管理を厳密に行う

### Requirement 17: Terraform によるインフラ構成管理（IaC）
**Objective:** As a インフラ管理者, I want インフラをコードで管理したい, so that 環境の再現性と変更管理を確保できる

#### Acceptance Criteria
1. The Ledger Muse システム shall 全ての Google Cloud リソースを Terraform で定義する
2. The Ledger Muse システム shall 開発環境（dev）、ステージング環境（staging）、本番環境（prod）を Terraform で分離管理する
3. The Ledger Muse システム shall Terraform のリモート状態管理（Cloud Storage バックエンド）を使用する
4. When インフラ変更を行う時, the Ledger Muse システム shall terraform plan で変更内容を事前確認する
5. The Ledger Muse システム shall Terraform モジュールを使用して、再利用可能なインフラ構成を実装する
6. The Ledger Muse システム shall Terraform 実行ログをバージョン管理システムで追跡する
7. If Terraform 実行が失敗した場合, then the Ledger Muse システム shall ロールバック手順を実行する

### Requirement 18: 非同期処理アーキテクチャ
**Objective:** As a システム設計者, I want 非同期処理を適切に実装したい, so that ユーザー体験とシステムスケーラビリティを向上できる

#### Acceptance Criteria
1. The Ledger Muse システム shall Pub/Sub を使用してイベント駆動型アーキテクチャを実装する
2. When 画像アップロードが完了した時, the Ledger Muse システム shall Pub/Sub トピックにメッセージを発行する
3. When Pub/Sub からメッセージを受信した時, the Ledger Muse システム shall Cloud Tasks でワーカーをスケジューリングする
4. The Ledger Muse システム shall ワーカーの実行失敗時に自動リトライを実行する
5. If ワーカーが 3 回連続で失敗した場合, then the Ledger Muse システム shall デッドレターキューに移動し、アラートを発報する
6. The Ledger Muse システム shall 非同期処理の進行状況をユーザーに通知する
7. The Ledger Muse システム shall 非同期処理のタイムアウトを適切に設定する（例: OCR 処理 30 秒）

### Requirement 19: データ暗号化
**Objective:** As a セキュリティ管理者, I want データを暗号化したい, so that 機密情報を保護できる

#### Acceptance Criteria
1. The Ledger Muse システム shall 転送中のデータを TLS 1.3 以上で暗号化する
2. The Ledger Muse システム shall Cloud Storage に保存する画像ファイルをサーバー側暗号化で保護する
3. The Ledger Muse システム shall Firestore / Cloud SQL の保存データを暗号化する
4. The Ledger Muse システム shall Google Cloud KMS（Key Management Service）で暗号鍵を管理する
5. When 機密データをログに記録する時, the Ledger Muse システム shall マスキング処理を実行する
6. The Ledger Muse システム shall 暗号鍵のローテーションを定期的に実行する

### Requirement 20: パフォーマンス・KPI
**Objective:** As a プロダクトオーナー, I want システムパフォーマンスを測定・改善したい, so that ユーザー満足度を向上できる

#### Acceptance Criteria
1. The Ledger Muse システム shall API レスポンスタイムの 95 パーセンタイルが 1 秒以内であることを目標とする
2. The Ledger Muse システム shall OCR 処理がアップロードから 30 秒以内に完了することを目標とする
3. When ページ読み込み時間が 3 秒を超えた場合, then the Ledger Muse システム shall パフォーマンス改善を優先タスクとする
4. The Ledger Muse システム shall 月間エラー率を 1% 以下に維持する
5. The Ledger Muse システム shall システム稼働率（Uptime）を 99.5% 以上に維持する（学習段階）
6. The Ledger Muse システム shall 将来的に 99.9% 以上の稼働率を目指す（商用段階）

### Requirement 21: コスト管理・最適化
**Objective:** As a プロジェクトオーナー, I want 運用コストを管理・最適化したい, so that 持続可能な運用を実現できる

#### Acceptance Criteria
1. The Ledger Muse システム shall 学習段階での月間運用コストを数ドル〜数十ドルに抑える
2. The Ledger Muse システム shall Google Cloud の無料枠を最大限活用する
3. The Ledger Muse システム shall Cloud Billing Export と BigQuery でコストを分析する
4. If 月間コストが予算（例: $50）を超えた場合, then the Ledger Muse システム shall アラートを発報する
5. The Ledger Muse システム shall 使用していないリソース（未使用のストレージ、古いログなど）を定期的に削除する
6. The Ledger Muse システム shall リソースのライフサイクルポリシーを設定し、自動削除を実装する
7. When コスト増加が検出された時, the Ledger Muse システム shall コスト要因を特定し、最適化施策を実施する
