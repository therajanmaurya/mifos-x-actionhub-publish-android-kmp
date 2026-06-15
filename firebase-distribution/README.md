# firebase-distribution

**Stage 0 — dev/QA**. Build APK + upload to Firebase App Distribution.

Out-of-band channel for QA testing. Parallel to the Play Store ladder (Firebase doesn't gate Stage 1+).

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `android_package_name` | Gradle module (e.g. `cmp-android`) | Yes |
| `release_type` | `prod` or `demo` (default: `prod`) | No |
| `keystore_file` | Base64 release keystore | Yes |
| `keystore_password` | Keystore password | Yes |
| `keystore_alias` | Keystore alias | Yes |
| `keystore_alias_password` | Keystore alias password | Yes |
| `google_services` | Base64 google-services.json | Yes |
| `firebase_creds` | Base64 Firebase SA JSON | Yes |
| `tester_groups` | Comma-separated tester group names | Yes |
| `java-version` | JDK (default: `17`) | No |

## Example

```yaml
- uses: openMF/mifos-x-actionhub-publish-android-kmp/firebase-distribution@v2.0.0
  with:
    android_package_name:    cmp-android
    release_type:            prod
    keystore_file:           ${{ secrets.RELEASE_KEYSTORE }}
    keystore_password:       ${{ secrets.KEYSTORE_PASSWORD }}
    keystore_alias:          ${{ secrets.KEYSTORE_ALIAS }}
    keystore_alias_password: ${{ secrets.KEYSTORE_ALIAS_PASSWORD }}
    google_services:         ${{ secrets.GOOGLE_SERVICES }}
    firebase_creds:          ${{ secrets.FIREBASE_CREDS }}
    tester_groups:           qa-team,beta-testers
```

## Migration from legacy

Replaces `openMF/mifos-x-actionhub-android-firebase-publish@v1.0.14`.

| Old | New |
|-----|-----|
| `openMF/mifos-x-actionhub-android-firebase-publish@v1.0.14` | `openMF/mifos-x-actionhub-publish-android-kmp/firebase-distribution@v2.0.0` |

Same inputs, same outputs, same behavior. Drop-in replacement.
