# Requirements Document

## Project Description (Input)
個人利用から始めて将来的に商用運用も視野に、クラウド基盤（Google Cloud）上で「家計簿機能＋レシート画像OCR＋ナレッジ（メモ・検索）機能」を備えた Web アプリを構築し、認証・ファイルアップロード・DB接続など実務で使う API／インフラ設計を学習する。

## Introduction
本仕様書は、Google Cloud 上で動作する家計簿管理 Web アプリケーション「Ledger Muse」の要件を定義します。本アプリケーションは、収支管理、レシート画像からの自動データ抽出、メモ・検索機能を統合し、個人利用から将来的な商用展開までをカバーする拡張可能なアーキテクチャを目指します。

## Requirements

### Requirement 1: ユーザー認証・アカウント管理
**Objective:** As a ユーザー, I want 安全にログインしてアカウントを管理したい, so that 自分のデータを保護し、複数デバイスからアクセスできる

#### Acceptance Criteria
1. When ユーザーが新規登録フォームを送信した時, the Ledger Muse システム shall メールアドレスとパスワードでアカウントを作成する
2. When ユーザーがログインフォームを送信した時, the Ledger Muse システム shall 認証情報を検証し、成功時にセッショントークンを発行する
3. If 無効な認証情報が入力された場合, then the Ledger Muse システム shall エラーメッセージを表示し、ログインを拒否する
4. When ユーザーがログアウトボタンをクリックした時, the Ledger Muse システム shall セッションを無効化し、ログイン画面にリダイレクトする
5. The Ledger Muse システム shall パスワードをハッシュ化して保存する
6. While セッションが有効な間, the Ledger Muse システム shall ユーザーのアクセストークンを自動更新する
7. When パスワードリセットがリクエストされた時, the Ledger Muse システム shall 登録メールアドレスに確認リンクを送信する

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
3. If アップロードファイルが画像形式でない場合, then the Ledger Muse システム shall アップロードを拒否し、エラーメッセージを表示する
4. If ファイルサイズが制限（10MB）を超える場合, then the Ledger Muse システム shall アップロードを拒否し、サイズ制限を通知する
5. The Ledger Muse システム shall JPEG, PNG, HEIC 形式の画像をサポートする
6. When ユーザーが取引詳細を表示した時, the Ledger Muse システム shall 関連するレシート画像のサムネイルを表示する
7. When ユーザーがサムネイルをクリックした時, the Ledger Muse システム shall レシート画像をフルサイズで表示する

### Requirement 5: レシート OCR 処理
**Objective:** As a ユーザー, I want レシート画像から情報を自動抽出したい, so that 手入力の手間を省ける

#### Acceptance Criteria
1. When レシート画像がアップロードされた時, the Ledger Muse システム shall Google Cloud Vision API を使用して OCR 処理を実行する
2. When OCR 処理が完了した時, the Ledger Muse システム shall 抽出された金額、日付、店舗名を取引フォームに自動入力する
3. If OCR 処理が失敗した場合, then the Ledger Muse システム shall エラーログを記録し、手動入力モードに切り替える
4. While OCR 処理中の間, the Ledger Muse システム shall 処理中インジケーターを表示する
5. When OCR 結果が取引フォームに反映された時, the Ledger Muse システム shall ユーザーが内容を確認・修正できる状態で表示する
6. The Ledger Muse システム shall OCR 抽出結果の信頼度スコアを記録する
7. If 金額が複数検出された場合, then the Ledger Muse システム shall 最も可能性の高い合計金額を選択する

### Requirement 6: ナレッジ管理（メモ機能）
**Objective:** As a ユーザー, I want 取引に関するメモを自由に追加・編集したい, so that 後で詳細を思い出せる

#### Acceptance Criteria
1. When ユーザーが取引にメモを追加した時, the Ledger Muse システム shall メモ内容を取引レコードに関連付けて保存する
2. When ユーザーが取引一覧を表示した時, the Ledger Muse システム shall メモが存在する取引にアイコンを表示する
3. When ユーザーがメモアイコンをクリックした時, the Ledger Muse システム shall メモ内容をポップアップで表示する
4. The Ledger Muse システム shall メモ内容にマークダウン記法をサポートする
5. When ユーザーがメモを編集した時, the Ledger Muse システム shall 編集履歴のタイムスタンプを記録する
6. The Ledger Muse システム shall メモ内容の最大文字数を 5000 文字に制限する

### Requirement 7: 検索機能
**Objective:** As a ユーザー, I want 取引やメモを検索したい, so that 過去の記録を素早く見つけられる

#### Acceptance Criteria
1. When ユーザーが検索キーワードを入力して検索ボタンをクリックした時, the Ledger Muse システム shall 取引の金額、カテゴリ、メモから該当する結果を検索する
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

### Requirement 9: データベース設計・管理
**Objective:** As a システム管理者, I want データを安全かつ効率的に保存・管理したい, so that アプリケーションの信頼性とパフォーマンスを確保できる

#### Acceptance Criteria
1. The Ledger Muse システム shall Google Cloud SQL (PostgreSQL) をデータベースとして使用する
2. The Ledger Muse システム shall ユーザーデータ、取引レコード、カテゴリ、メモを正規化されたテーブル構造で管理する
3. When データベース接続エラーが発生した時, the Ledger Muse システム shall 自動再接続を試行し、エラーログを記録する
4. The Ledger Muse システム shall データベース接続にコネクションプーリングを使用する
5. The Ledger Muse システム shall トランザクション処理により、データの整合性を保証する
6. The Ledger Muse システム shall 定期的な自動バックアップを実行する
7. If データベース容量が 80% を超えた場合, then the Ledger Muse システム shall アラート通知を送信する

### Requirement 10: API 設計
**Objective:** As a 開発者, I want RESTful API を設計・実装したい, so that フロントエンドとバックエンドを疎結合に保てる

#### Acceptance Criteria
1. The Ledger Muse システム shall RESTful API 設計原則に従った エンドポイントを提供する
2. The Ledger Muse システム shall JSON 形式でリクエスト・レスポンスをやり取りする
3. When API リクエストが成功した時, the Ledger Muse システム shall 適切な HTTP ステータスコード（200, 201, 204）を返す
4. If API リクエストがエラーの場合, then the Ledger Muse システム shall エラー詳細を含むレスポンス（400, 401, 404, 500）を返す
5. The Ledger Muse システム shall 全ての API エンドポイントに認証トークンの検証を実装する
6. The Ledger Muse システム shall API バージョニング（/api/v1/）をサポートする
7. When API リクエストが受信された時, the Ledger Muse システム shall リクエストログを記録する

### Requirement 11: セキュリティ・認可
**Objective:** As a システム管理者, I want セキュアなアクセス制御を実装したい, so that ユーザーデータを不正アクセスから保護できる

#### Acceptance Criteria
1. The Ledger Muse システム shall JWT (JSON Web Token) ベースの認証を実装する
2. When ユーザーが他のユーザーのデータにアクセスしようとした時, the Ledger Muse システム shall アクセスを拒否し、403 エラーを返す
3. The Ledger Muse システム shall HTTPS 通信を強制する
4. The Ledger Muse システム shall CORS (Cross-Origin Resource Sharing) ポリシーを適切に設定する
5. If 連続してログイン失敗が 5 回発生した場合, then the Ledger Muse システム shall アカウントを一時的にロックする
6. The Ledger Muse システム shall 機密情報（パスワード、トークン）をログに記録しない
7. When セキュリティ関連のイベントが発生した時, the Ledger Muse システム shall セキュリティログに記録する

### Requirement 12: インフラストラクチャ（Google Cloud）
**Objective:** As a システム管理者, I want Google Cloud 上で拡張可能なインフラを構築したい, so that 将来的な商用運用に対応できる

#### Acceptance Criteria
1. The Ledger Muse システム shall Google Cloud Run でバックエンド API をホスティングする
2. The Ledger Muse システム shall Google Cloud Storage でレシート画像を保存する
3. The Ledger Muse システム shall Google Cloud SQL でデータベースを管理する
4. The Ledger Muse システム shall Google Cloud Vision API で OCR 処理を実行する
5. When アプリケーションのトラフィックが増加した時, the Ledger Muse システム shall 自動スケーリングを実行する
6. The Ledger Muse システム shall Cloud Monitoring でアプリケーションのメトリクスを収集する
7. If システムエラーが発生した場合, then the Ledger Muse システム shall Cloud Logging にエラー詳細を記録する
8. The Ledger Muse システム shall 開発環境と本番環境を分離する

### Requirement 13: フロントエンド UI/UX
**Objective:** As a ユーザー, I want 使いやすく直感的な Web インターフェースを利用したい, so that ストレスなく家計簿を管理できる

#### Acceptance Criteria
1. The Ledger Muse システム shall レスポンシブデザインでモバイル・タブレット・デスクトップに対応する
2. When ユーザーが画面を操作した時, the Ledger Muse システム shall 300ms 以内にフィードバックを表示する
3. The Ledger Muse システム shall 日本語 UI を提供する
4. When データ読み込み中の時, the Ledger Muse システム shall ローディングインジケーターを表示する
5. If ユーザーが破壊的操作（削除など）を実行しようとした場合, then the Ledger Muse システム shall 確認ダイアログを表示する
6. The Ledger Muse システム shall アクセシビリティ標準（WCAG 2.1 AA）に準拠する
7. When ユーザーがフォームに無効なデータを入力した時, the Ledger Muse システム shall リアルタイムでバリデーションエラーを表示する

### Requirement 14: 拡張性・将来対応
**Objective:** As a プロダクトオーナー, I want 将来的な機能拡張に対応できる設計にしたい, so that 商用運用時にスムーズに移行できる

#### Acceptance Criteria
1. The Ledger Muse システム shall マルチテナント対応可能なデータ構造を採用する
2. The Ledger Muse システム shall 機能ごとにモジュール化された コードベースを維持する
3. Where 有料プラン機能が追加される場合, the Ledger Muse システム shall プラン別の機能制限を管理できる
4. The Ledger Muse システム shall API レート制限を実装可能な構造を持つ
5. The Ledger Muse システム shall 多言語対応（i18n）のための構造を用意する
6. The Ledger Muse システム shall サードパーティ連携（銀行 API など）のための拡張ポイントを持つ

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
