# build

Compose Android build sub-action. Produces APK + AAB.

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `android_package_name` | Gradle module (e.g. `cmp-android`) | Yes |
| `build_type` | `Debug` or `Release` (default: `Release`) | No |
| `java-version` | JDK version (default: `17`) | No |
| `keystore_file` | Base64 release keystore (Release only) | When `build_type=Release` |
| `keystore_password` | Keystore password | When `build_type=Release` |
| `keystore_alias` | Keystore alias | When `build_type=Release` |
| `keystore_alias_password` | Keystore alias password | When `build_type=Release` |
| `google_services` | Base64 google-services.json | When `build_type=Release` |

## Outputs

| Output | Description |
|--------|-------------|
| `apk_path` | Path to generated APK |
| `aab_path` | Path to generated AAB (Release only) |

## Used by

- PR checks (debug builds)
- `play-store-internal/` (Release builds upstream)
- `firebase-distribution/` (Release builds upstream)

## Example

```yaml
- uses: openMF/mifos-x-actionhub-publish-android-kmp/build@v2.0.0
  with:
    android_package_name: cmp-android
    build_type:           Release
    keystore_file:        ${{ secrets.RELEASE_KEYSTORE }}
    keystore_password:    ${{ secrets.KEYSTORE_PASSWORD }}
    keystore_alias:       ${{ secrets.KEYSTORE_ALIAS }}
    keystore_alias_password: ${{ secrets.KEYSTORE_ALIAS_PASSWORD }}
    google_services:      ${{ secrets.GOOGLE_SERVICES }}
```
