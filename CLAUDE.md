# CLAUDE.md — mifos-x-actionhub-publish-android-kmp (Tier 3 — Android)

> **You are in a TIER-3 PUBLISH repo.** Before editing anything, check whether
> the change actually belongs in the **orchestrator** (`openMF/mifos-x-actionhub`).
> Full decision guide: [`mifos-x-actionhub/CONTRIBUTING.md`](https://github.com/openMF/mifos-x-actionhub/blob/main/CONTRIBUTING.md)

## The 3-tier chain

```
Consumer (kmp-project-template + forks)        Tier 1 — thin wrapper
    └─ uses @v1.0.X →
openMF/mifos-x-actionhub                       Tier 2 — orchestrator
    └─ uses @v2.0.X →
publish-android-kmp (THIS REPO)                Tier 3 — Android ladder
publish-apple-kmp                              Tier 3 — iOS + macOS
publish-desktop-kmp                            Tier 3 — Windows + Linux
publish-web-kmp                                Tier 3 — Web hosts
```

## What lives here (Android-specific)

| Concern | File | Owns |
|---|---|---|
| Ladder workflow | `.github/workflows/release.yaml` | rungs: firebase → internal → beta → production |
| Composite actions | `*/action.yaml` | per-rung build/sign/upload steps (gradle assembleRelease, fastlane lanes) |
| Validate-secrets preflight | `release.yaml#validate-secrets` | fail-fast on missing google_services / upload_keystore / playstore_creds / firebase_creds |

## "Should this change go HERE or in the orchestrator?"

### ✅ Edit HERE when…
- Adding/removing a rung (e.g. `staging` rung between internal and beta)
- Changing Android signing flow (V1/V2/V3 signature scheme)
- Adding a new Android-only secret (e.g. Play Integrity API key)
- Changing GitHub Environment names (`android-firebase` → `android-fad`)
- Updating Fastlane Android lane logic
- Changing Gradle assemble/bundle steps
- Adjusting `validate-secrets` env list for Android secrets
- Bumping Android runner image, Java version, Gradle version

### ❌ DON'T edit here — go to orchestrator when…
- Changing the `workflow_dispatch` form the consumer sees (those inputs live in `release-multi-platform-v2.yaml`)
- Adding cross-platform validation (e.g. iOS + Android must use same `version_tag`)
- Changing how `version_tag` is auto-computed
- Changing the default rung shown to consumers
- Renaming a secret that other platforms also use → update `V2_GUIDE.md` in orchestrator instead, then sync env lists across all publish-* repos

## Versioning

| Bump | When |
|---|---|
| Patch (`v2.0.4` → `v2.0.5`) | any change inside the ladder (rung tweak, signing change, new secret check) |
| Minor (`v2.0.X` → `v2.1.0`) | new rung added |
| Major (`v2.X.X` → `v3.0.0`) | breaking — rung removed, secret renamed, environment renamed |

After merging a change:
1. Tag `v2.0.{X+1}` on `main`
2. Bump the orchestrator's `release-multi-platform-v2.yaml` ref:
   `publish-android-kmp/.github/workflows/release.yaml@v2.0.{X} → @v2.0.{X+1}`
3. Tag a new orchestrator patch (`v1.0.{Y+1}`)
4. Bump consumer wrappers to `@v1.0.{Y+1}`

## Android secret schema (canonical names — match orchestrator's V2_GUIDE.md)

| Name | Used at | Content |
|---|---|---|
| `google_services` | always | Base64 of `google-services.json` |
| `upload_keystore` | always | Base64 of upload keystore (.jks/.keystore) |
| `keystore_password` | always | Password for the keystore file |
| `keystore_alias` | always | Alias inside the keystore |
| `keystore_alias_password` | always | Password for the alias |
| `firebase_creds` | firebase rung | Base64 of Firebase App Distribution service-account JSON |
| `playstore_creds` | internal/beta/production rungs | Base64 of Play Store service-account JSON |

## Don't

- ❌ Don't reference floating tags (`@v2`, `@main`) — orchestrator pins to immutable patch tags
- ❌ Don't change secret NAMES without coordinating with `V2_GUIDE.md` and all 4 publish-* repos
- ❌ Don't remove the `validate-secrets` job — it's the fail-fast contract

## Always

- ✅ Tag immediately after merge (this repo's value IS its tag)
- ✅ Bump orchestrator's ref pin in the same coordinated release
- ✅ Update `validate-secrets` env list whenever a new rung needs a new secret
- ✅ Match canonical lowercase snake_case secret names from `V2_GUIDE.md`
