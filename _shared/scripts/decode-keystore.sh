#!/usr/bin/env bash
#
# decode-keystore.sh — Decode just the release keystore (no Firebase/Play creds)
#
# Used by build/ sub-action when building Release artifacts without uploading.
#
# Required env:
#   KEYSTORE              — base64 release keystore
#   ANDROID_PACKAGE_NAME  — Gradle module name
# Optional env:
#   GOOGLE_SERVICES       — base64 google-services.json (for builds that need it)
#
set -euo pipefail

mkdir -p keystores

if [[ -n "${KEYSTORE:-}" ]]; then
  echo "$KEYSTORE" | base64 --decode > keystores/release_keystore.keystore
fi

if [[ -n "${GOOGLE_SERVICES:-}" ]]; then
  echo "$GOOGLE_SERVICES" | base64 --decode > "${ANDROID_PACKAGE_NAME}/google-services.json"
fi

echo "✅ Keystore decoded"
