# Steering Update (2025-11-27)

## Changes
- tech.md: go.mod が 1.24 であることを反映し、CI ランナー (Go 1.23) との乖離を明示。PR クローズ時に Cloud Run プレビューと Artifact Registry イメージを削除する cleanup-preview.yml を CI/CD スナップショットへ追記。updated_at を 2025-11-27 に更新。
- structure.md: tests/frontend.test.sh が `type-check: "next check"` を要求する一方、frontend/package.json は `tsc --noEmit` であることを明記。Go 1.24 (go.mod) と CI ランナー 1.23 のバージョン差分を記録。updated_at を 2025-11-27 に更新。

## Drift/Warnings
- Go バージョン: backend/go.mod は 1.24 だが CI (ci.yml) と tests/ci.test.sh は 1.23 前提。統一方針が必要。
- Frontend type-check: tests/frontend.test.sh は `next check` を期待、package.json は `tsc --noEmit` 実行。どちらを正とするか決定が必要。

## Notes
- 追記はすべて加筆のみ。既存コンテンツは保持。