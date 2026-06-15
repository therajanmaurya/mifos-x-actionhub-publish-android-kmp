#!/usr/bin/env bash
#
# materialize-android-secrets.sh — Decode base64 secrets into canonical paths
#
# Used by all 4 ladder sub-actions (firebase-distribution, play-store-internal,
# promote-to-beta, promote-to-production). Decodes:
#   - $GOOGLE_SERVICES        → $ANDROID_PACKAGE_NAME/google-services.json
#   - $KEYSTORE               → keystores/release_keystore.keystore
#   - $FIREBASE_CREDS         → secrets/firebaseAppDistributionServiceCredentialsFile.json (when --firebase flag)
#   - $PLAYSTORE_CREDS        → secrets/playStorePublishServiceCredentialsFile.json (when --playstore flag)
#
# Required env (all sub-actions):
#   GOOGLE_SERVICES         — base64 google-services.json
#   KEYSTORE                — base64 release keystore
#   ANDROID_PACKAGE_NAME    — Gradle module name (e.g. "cmp-android")
#
# Optional env (per sub-action):
#   FIREBASE_CREDS          — base64 Firebase SA JSON (required by firebase-distribution)
#   PLAYSTORE_CREDS         — base64 Play Store SA JSON (required by play-store-internal)
#
# Flags:
#   --firebase     also decode FIREBASE_CREDS
#   --playstore    also decode PLAYSTORE_CREDS
#
set -euo pipefail

mkdir -p secrets keystores

# Google Services
if [[ -n "${GOOGLE_SERVICES:-}" ]]; then
  echo "$GOOGLE_SERVICES" | base64 --decode > "${ANDROID_PACKAGE_NAME}/google-services.json"
fi

# Keystore
if [[ -n "${KEYSTORE:-}" ]]; then
  echo "$KEYSTORE" | base64 --decode > keystores/release_keystore.keystore
fi

# Per-flag credentials
for arg in "$@"; do
  case "$arg" in
    --firebase)
      if [[ -n "${FIREBASE_CREDS:-}" ]]; then
        echo "$FIREBASE_CREDS" | base64 --decode > secrets/firebaseAppDistributionServiceCredentialsFile.json
      fi
      ;;
    --playstore)
      if [[ -n "${PLAYSTORE_CREDS:-}" ]]; then
        echo "$PLAYSTORE_CREDS" | base64 --decode > secrets/playStorePublishServiceCredentialsFile.json
      fi
      ;;
  esac
done

echo "✅ Android secrets materialized"
