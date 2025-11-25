# Steering Update (2025-11-25)

## Changes
- tech.md: Added CI/CD snapshot (paths-filtered frontend/backend checks; Node20/Go1.23; Artifact Registry → Cloud Run deploy with WIF + health check comment on PR previews), local dev workflow notes (docker compose backend + Firebase Emulator with air hot reload; frontend runs on host; .env templates), clarified TS type-check baseline as `npm run type-check` (tsc --noEmit); updated `updated_at` to 2025-11-25.

## Drift/Warnings
- tests/frontend.test.sh expects `"type-check": "next check"`, but package.json uses `tsc --noEmit`. Need policy: switch script or adjust test.

## No Change
- product.md and structure.md aligned with current codebase; no edits.