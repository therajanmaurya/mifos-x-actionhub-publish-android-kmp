# Changelog

All notable changes follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased] — Play App Signing alignment (breaking)

### Changed
- **BREAKING**: `workflow_call` secret renamed `release_keystore` → `upload_keystore` to align with Google's Play App Signing terminology. Consumers must update their workflow's `secrets:` block.
- Internal keystore filename `keystores/release_keystore.keystore` → `keystores/upload_keystore.keystore` (matches Play App Signing "upload key" semantics + matches downstream project conventions).
- Sub-action `keystore_file` input description updated to "Base64-encoded Play Console upload keystore (Play App Signing)".
- `_shared/scripts/{materialize-android-secrets,decode-keystore}.sh` decode `$KEYSTORE` env var to the new path; doc-comments reference Play App Signing model + Google KMS.

### Why
Per [Google's official Play App Signing docs](https://support.google.com/googleplay/android-developer/answer/9842756): 90%+ of new apps use Play App Signing by default. Google holds the app signing key in KMS; developers only hold the upload key. The pre-2021 legacy "release keystore" terminology conflates the two; this release adopts the correct terminology end-to-end.

### Migration (for consumers)
```diff
  secrets:
    google_services:          ${{ secrets.GOOGLE_SERVICES }}
    firebase_creds:           ${{ secrets.FIREBASE_CREDS }}
    playstore_creds:          ${{ secrets.PLAYSTORE_CREDS }}
-   release_keystore:         ${{ secrets.RELEASE_KEYSTORE }}
+   upload_keystore:          ${{ secrets.UPLOAD_KEYSTORE_FILE }}
    keystore_password:        ${{ secrets.KEYSTORE_PASSWORD }}
    keystore_alias:           ${{ secrets.KEYSTORE_ALIAS }}
    keystore_alias_password:  ${{ secrets.KEYSTORE_ALIAS_PASSWORD }}
```

Consumer-side GHA secrets should be renamed `RELEASE_KEYSTORE` → `UPLOAD_KEYSTORE_FILE` for parity with the upstream `kmp-project-template` v2 convention (Play App Signing single-keystore model).


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
