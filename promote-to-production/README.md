# promote-to-production

**Stage 3 — production**. Move Open Beta AAB to Play Production with staged rollout. **No rebuild.**

⚠️ **Production deployment** — should be gated behind GHA environment protection rule with reviewers + wait timer.

## Pre-requisites

The AAB must already be live on the Beta track (deployed via [`../promote-to-beta`](../promote-to-beta)).

## Example

```yaml
- uses: openMF/mifos-x-actionhub-publish-android-kmp/promote-to-production@v2.0.0
  with:
    android_package_name: cmp-android
    playstore_creds:      ${{ secrets.PLAYSTORE_CREDS }}
    rollout:              0.10    # 10% staged rollout
```

## Staged rollout

| Rollout | Effect |
|---------|--------|
| `0.01` | 1% — initial canary |
| `0.05` | 5% |
| `0.10` | 10% (default) — typical first day |
| `0.20` | 20% |
| `0.50` | 50% |
| `1.0` | 100% — full rollout |

Increase incrementally over days based on crash/ANR metrics.

## Migration from legacy

Replaces `openMF/mifos-x-actionhub-publish-android-on-playstore-production@v1.0.14`. Drop-in replacement with added `rollout` input (legacy had hardcoded 100%).
