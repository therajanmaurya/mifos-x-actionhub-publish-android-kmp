#!/usr/bin/env bash
#
# setup-fastlane.sh — Install Fastlane + plugins for Android lanes
#
# Pinned plugin versions per sub-plan 01. Floating add_plugin forbidden.
# Called from sub-actions after ruby/setup-ruby + bundler-cache.
#
set -euo pipefail

# Install Fastlane plugins (pinned)
fastlane add_plugin firebase_app_distribution --version=1.0.0

echo "✅ Fastlane + plugins ready"
