# promote-to-beta

**Stage 2 — beta**. Move existing Play Internal AAB to Open Beta track. **No rebuild.**

Public opt-in channel — Play Store users can join the Beta program with one click.

## Pre-requisites

The AAB must already be live on the Internal track (deployed via [`../play-store-internal`](../play-store-internal)).

## Example

```yaml
- uses: openMF/mifos-x-actionhub-publish-android-kmp/promote-to-beta@v2.0.0
  with:
    android_package_name: cmp-android
    playstore_creds:      ${{ secrets.PLAYSTORE_CREDS }}
```

## Next rung

After this, promote to Production with [`../promote-to-production`](../promote-to-production).
