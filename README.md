# mifos-x-actionhub-publish-android-kmp

> Composite GitHub Actions for KMP Android: **build + Firebase Distribution + Play Store ladder (Internal → Beta → Production)**. Part of the [`openMF/mifos-x-actionhub`](https://github.com/openMF/mifos-x-actionhub) constellation.

## What this provides

A single repo housing 5 composite sub-actions that compose the full Android promotion ladder:

| Sub-action | Stage | Purpose |
|---|---|---|
| [`build/`](./build/) | — | Compile Compose Android, produce APK + AAB. Used by PR checks AND by every Stage 1+ action. |
| [`firebase-distribution/`](./firebase-distribution/) | **Stage 0** — dev/QA | Upload APK to Firebase App Distribution (out-of-band, parallel to the ladder) |
| [`play-store-internal/`](./play-store-internal/) | **Stage 1** — internal | Build AAB + upload to Play Internal track (≤100 testers, fast review) |
| [`promote-to-beta/`](./promote-to-beta/) | **Stage 2** — beta | Play Internal → Open Beta (no rebuild — promotes the AAB already on Play) |
| [`promote-to-production/`](./promote-to-production/) | **Stage 3** — production | Open Beta → Production staged rollout (1% → 5% → 20% → 50% → 100%) |

## Why a consolidated repo

Replaces 4 per-target repos (`build-android-app`, `android-firebase-publish`, `publish-android-on-playstore-beta`, `publish-android-on-playstore-production`) with one. Benefits:

- **Atomic per-platform tag** — `v2.0.0` ships all 5 sub-actions together; no version drift across the Android pipeline
- **Real DRY** — `_shared/scripts/materialize-android-secrets.sh` written once, used by 4 sub-actions
- **One PR per cross-rung refactor** — change Fastlane lane signature across firebase + play-internal + promote-to-beta in one diff
- **GHA-native pattern** — same as [`actions/cache/save`](https://github.com/actions/cache/tree/main/save) and [`actions/cache/restore`](https://github.com/actions/cache/tree/main/restore)

See the [constellation-consolidation plan](https://github.com/openMF/mifos-x-actionhub/blob/main/docs/CONSOLIDATION.md) for the full rationale.

## Quick start

```yaml
name: Release Android
on:
  workflow_dispatch:
    inputs:
      target_stage:
        type: choice
        options: [firebase, internal, beta, production]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build + ship to Firebase (Stage 0)
        if: ${{ inputs.target_stage == 'firebase' }}
        uses: openMF/mifos-x-actionhub-publish-android-kmp/firebase-distribution@v2.0.0
        with:
          android_package_name: cmp-android
          google_services:        ${{ secrets.GOOGLE_SERVICES }}
          firebase_creds:         ${{ secrets.FIREBASE_CREDS }}
          keystore_file:          ${{ secrets.RELEASE_KEYSTORE }}
          keystore_password:      ${{ secrets.KEYSTORE_PASSWORD }}
          keystore_alias:         ${{ secrets.KEYSTORE_ALIAS }}
          keystore_alias_password:${{ secrets.KEYSTORE_ALIAS_PASSWORD }}
          tester_groups:          qa-team,beta-testers

      - name: Build + ship to Play Internal (Stage 1)
        if: ${{ inputs.target_stage == 'internal' }}
        uses: openMF/mifos-x-actionhub-publish-android-kmp/play-store-internal@v2.0.0
        with:
          android_package_name:   cmp-android
          google_services:        ${{ secrets.GOOGLE_SERVICES }}
          playstore_creds:        ${{ secrets.PLAYSTORE_CREDS }}
          keystore_file:          ${{ secrets.RELEASE_KEYSTORE }}
          keystore_password:      ${{ secrets.KEYSTORE_PASSWORD }}
          keystore_alias:         ${{ secrets.KEYSTORE_ALIAS }}
          keystore_alias_password:${{ secrets.KEYSTORE_ALIAS_PASSWORD }}

      - name: Promote Internal → Beta (Stage 2 — no rebuild)
        if: ${{ inputs.target_stage == 'beta' }}
        uses: openMF/mifos-x-actionhub-publish-android-kmp/promote-to-beta@v2.0.0
        with:
          android_package_name: cmp-android
          playstore_creds:      ${{ secrets.PLAYSTORE_CREDS }}

      - name: Promote Beta → Production (Stage 3 — no rebuild)
        if: ${{ inputs.target_stage == 'production' }}
        uses: openMF/mifos-x-actionhub-publish-android-kmp/promote-to-production@v2.0.0
        with:
          android_package_name: cmp-android
          playstore_creds:      ${{ secrets.PLAYSTORE_CREDS }}
          rollout:              0.1   # 10% staged rollout (optional; default 1.0)
```

For the **full ladder run with approval gates + supersede semantics**, use the [orchestrator reusable workflow](https://github.com/openMF/mifos-x-actionhub/blob/main/.github/workflows/release-android.yaml):

```yaml
jobs:
  release:
    uses: openMF/mifos-x-actionhub/.github/workflows/release-android.yaml@v1.0.17
    with:
      version_tag:   v2026.06.15
      starting_rung: firebase
    secrets: inherit
```

The orchestrator handles `needs:` chain + approval gates + concurrency. See [`examples/consumer-release-android.yml`](./examples/consumer-release-android.yml).

## Repository structure

```
.
├── README.md                                   ← this file
├── LICENSE
├── CHANGELOG.md
├── action.yaml                                 ← root composite (defaults; see below)
├── .github/workflows/
│   ├── pr-check.yaml                           ← matrix-tests all 5 sub-actions on PR
│   └── release.yaml                            ← auto-tags v2.0.X + rolling @v2 on merge
├── build/                                      ← sub-action: build APK/AAB
│   ├── action.yaml
│   └── README.md
├── firebase-distribution/                      ← sub-action: Stage 0
├── play-store-internal/                        ← sub-action: Stage 1
├── promote-to-beta/                            ← sub-action: Stage 2 (no rebuild)
├── promote-to-production/                      ← sub-action: Stage 3 (no rebuild)
├── _shared/                                    ← deduplicated helpers across sub-actions
│   └── scripts/
│       ├── setup-fastlane.sh
│       ├── materialize-android-secrets.sh
│       └── decode-keystore.sh
└── examples/
    └── consumer-release-android.yml            ← copy-paste workflow for consumers
```

## Versioning

| Tag | Meaning | Recommendation |
|---|---|---|
| `@v2.0.0` | Exact pinned version | Production: pin exact |
| `@v2` | Rolling major — auto-picks up v2.0.1, v2.1.0, ... | Stable orgs that want auto-bumps within v2 |
| `@main` | Bleeding edge | Discouraged for production |

Releases follow [Semantic Versioning](https://semver.org/). Breaking changes (input renames, output shape changes, etc.) trigger a major bump.

## Supersedes (legacy repos)

This repo supersedes the following per-target repos. They enter a 6-month deprecation window (target archive: 2027-Q1):

- `openMF/mifos-x-actionhub-build-android-app@v1.0.14` → `./build/@v2.0.0`
- `openMF/mifos-x-actionhub-android-firebase-publish@v1.0.14` → `./firebase-distribution/@v2.0.0`
- `openMF/mifos-x-actionhub-publish-android-on-playstore-beta@v1.0.14` → SPLIT into `./play-store-internal/@v2.0.0` + `./promote-to-beta/@v2.0.0`
- `openMF/mifos-x-actionhub-publish-android-on-playstore-production@v1.0.14` → `./promote-to-production/@v2.0.0`

Existing consumer code keeps working — old refs 301-redirect via GitHub during grace period. See [migration guide](https://github.com/openMF/mifos-x-actionhub/blob/main/docs/MIGRATION.md).

## Contributing

PRs welcome. CI matrix-tests every sub-action via `.github/workflows/pr-check.yaml`. Per-sub-action documentation lives in each subdir's README.

## License

[Apache 2.0](./LICENSE)
