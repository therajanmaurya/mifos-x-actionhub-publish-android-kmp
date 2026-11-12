# promote-to-closed

**Stage 1b — closed (alpha)**. Move the existing Play Internal AAB to the Closed testing (alpha) track. **No rebuild.**

An invite-only channel between internal testers and the public beta.

## Pre-requisites

The AAB must already be live on the Internal track (deployed via [`../play-store-internal`](../play-store-internal)).

## Example

```yaml
- uses: therajanmaurya/mifos-x-actionhub-publish-android-kmp/promote-to-closed@v2.0.31
  with:
    android_package_name: cmp-android
    playstore_creds:      ${{ secrets.PLAYSTORE_CREDS }}
```

## Next rung

After this, promote to Open Beta with [`../promote-to-beta`](../promote-to-beta).
