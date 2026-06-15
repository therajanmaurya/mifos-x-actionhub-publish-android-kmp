# Changelog

All notable changes follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## v2.0.0 — Constellation consolidation (planned)

### Added

- **Sub-action `build/`** — Compose Android build, produces APK + AAB. Lifted from `openMF/mifos-x-actionhub-build-android-app@v1.0.14` (consolidation).
- **Sub-action `firebase-distribution/`** — Stage 0 dev distribution. Lifted from `openMF/mifos-x-actionhub-android-firebase-publish@v1.0.14`.
- **Sub-action `play-store-internal/`** — Stage 1; build AAB + upload to Play Internal track. Split from existing `openMF/mifos-x-actionhub-publish-android-on-playstore-beta@v1.0.14` (internal mode).
- **Sub-action `promote-to-beta/`** — Stage 2; Play Internal → Open Beta (no rebuild). Split from same source as above (beta mode).
- **Sub-action `promote-to-production/`** — Stage 3; Open Beta → Production staged rollout. Lifted from `openMF/mifos-x-actionhub-publish-android-on-playstore-production@v1.0.14`.
- **`_shared/scripts/`** — `setup-fastlane.sh`, `materialize-android-secrets.sh`, `decode-keystore.sh` deduplicated across all 5 sub-actions.
- **`.github/workflows/pr-check.yaml`** — matrix-tests every sub-action on PR.
- **`.github/workflows/release.yaml`** — auto-tags `v2.0.X` + rolling `@v2` pointer on merge to main.

### Supersedes (6-month deprecation window from 2026-09-01)

- `openMF/mifos-x-actionhub-build-android-app`
- `openMF/mifos-x-actionhub-android-firebase-publish`
- `openMF/mifos-x-actionhub-publish-android-on-playstore-beta`
- `openMF/mifos-x-actionhub-publish-android-on-playstore-production`

Old refs continue working via 301 redirect during grace period.

### Refs

- Epic: `actionhub-constellation-consolidation` (framework plan-layer)
- Companion repos: `openMF/mifos-x-actionhub-publish-apple-kmp@v2.0.0`, `openMF/mifos-x-actionhub-publish-desktop-kmp@v2.0.0`, `openMF/mifos-x-actionhub-publish-web-kmp@v2.0.0`
- Orchestrator: `openMF/mifos-x-actionhub@v1.0.17` — adds `release-android.yaml` reusable workflow consuming these sub-actions
