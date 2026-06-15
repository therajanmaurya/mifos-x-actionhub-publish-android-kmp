# play-store-internal

**Stage 1 — internal**. Build AAB + upload to Google Play Internal testing track.

≤100 testers, fast review (~1hr). Use for internal QA, smoke testing release builds.

## Example

```yaml
- uses: openMF/mifos-x-actionhub-publish-android-kmp/play-store-internal@v2.0.0
  with:
    android_package_name:    cmp-android
    keystore_file:           ${{ secrets.RELEASE_KEYSTORE }}
    keystore_password:       ${{ secrets.KEYSTORE_PASSWORD }}
    keystore_alias:          ${{ secrets.KEYSTORE_ALIAS }}
    keystore_alias_password: ${{ secrets.KEYSTORE_ALIAS_PASSWORD }}
    google_services:         ${{ secrets.GOOGLE_SERVICES }}
    playstore_creds:         ${{ secrets.PLAYSTORE_CREDS }}
```

## Next rung

After this, promote to Open Beta with [`../promote-to-beta`](../promote-to-beta).

## Migration from legacy

Split from `openMF/mifos-x-actionhub-publish-android-on-playstore-beta@v1.0.14` (which took a `release_type` input). The new split:

| Old call | New call |
|----------|----------|
| `openMF/mifos-x-actionhub-publish-android-on-playstore-beta@v1.0.14` with `release_type: internal` | `openMF/mifos-x-actionhub-publish-android-kmp/play-store-internal@v2.0.0` |
| `openMF/mifos-x-actionhub-publish-android-on-playstore-beta@v1.0.14` with `release_type: beta` | `openMF/mifos-x-actionhub-publish-android-kmp/promote-to-beta@v2.0.0` |
