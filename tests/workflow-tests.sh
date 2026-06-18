#!/bin/bash
# tests/workflow-tests.sh
#
# End-to-end workflow tests for mifos-x-actionhub-publish-android-kmp.
#
# Tier-3 repo (Android) in the 3-tier actionhub chain:
#     consumer → orchestrator(mifos-x-actionhub) → THIS REPO
#
# Stages: firebase-distribution → play-store-internal → promote-to-beta → promote-to-production
#
# Test tiers:
#   1. Static syntax    — YAML parse · actionlint · no dynamic uses · shellcheck
#   2. Workflow_call    — interface schema (inputs + secrets contract)
#   3. Job structure    — 5 jobs · sequential dependency chain
#   4. Per-stage uses   — each stage routes to correct composite action
#   5. Composite actions — every uses: subdir exists + has action.yaml
#   6. Action interfaces — caller's `with:` matches action's declared inputs
#   7. validate-secrets — per-rung secret coverage
#   8. Rung-conditional logic — if conditions cover the starting_rung enum

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PASS=0
FAIL=0
FAILED_TESTS=()

run_test() {
    local name="$1"
    local cmd="$2"
    printf "  %-72s ... " "$name"
    if eval "$cmd" > /tmp/test-out 2>&1; then
        echo "✅ PASS"
        PASS=$((PASS+1))
    else
        echo "❌ FAIL"
        sed 's/^/      /' /tmp/test-out
        FAIL=$((FAIL+1))
        FAILED_TESTS+=("$name")
    fi
}

py() { python3 -c "$1"; }

# ─────────────────────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────────────────────
ACTIONS=(firebase-distribution play-store-internal promote-to-beta promote-to-production)
EXPECTED_JOBS=(validate-secrets stage-0-firebase stage-1-play-internal stage-2-promote-to-beta stage-3-promote-to-production)

echo "════════════════════════════════════════════════════════════════════════════"
echo "  Workflow E2E tests for mifos-x-actionhub-publish-android-kmp"
echo "════════════════════════════════════════════════════════════════════════════"
echo

# ── Tier 1: Static syntax ────────────────────────────────────────────────────
echo "── Tier 1: Static syntax ──"
run_test "T01: release.yaml parses" \
    "py 'import yaml; yaml.safe_load(open(\".github/workflows/release.yaml\"))'"
run_test "T02: pr-check.yaml parses" \
    "py 'import yaml; yaml.safe_load(open(\".github/workflows/pr-check.yaml\"))'"
run_test "T03: tag.yaml parses" \
    "py 'import yaml; yaml.safe_load(open(\".github/workflows/tag.yaml\"))'"
run_test "T04: actionlint clean on release.yaml" \
    "actionlint .github/workflows/release.yaml"
run_test "T05: actionlint clean on pr-check.yaml" \
    "actionlint .github/workflows/pr-check.yaml"
run_test "T06: actionlint clean on tag.yaml" \
    "actionlint .github/workflows/tag.yaml"
run_test "T07: NO dynamic uses regression" \
    "! grep -nE '^[^#]*uses: .*\\\${{ (inputs|matrix)\\.' .github/workflows/release.yaml"
run_test "T08: shellcheck clean on _shared/scripts" \
    "find _shared/scripts -name '*.sh' -exec shellcheck -S warning {} +"
echo

# ── Tier 2: workflow_call interface contract ─────────────────────────────────
echo "── Tier 2: workflow_call interface contract ──"
run_test "T09: workflow_call inputs include (android_package_name, version_tag, starting_rung)" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
got = set(d[\"on\" if \"on\" in d else True][\"workflow_call\"][\"inputs\"].keys())
expected = set([\"android_package_name\",\"version_tag\",\"starting_rung\"])
assert expected.issubset(got), \"missing inputs: \" + str(expected - got)
'"
run_test "T10: android_package_name is required + type string" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
t = d[\"on\" if \"on\" in d else True][\"workflow_call\"][\"inputs\"][\"android_package_name\"]
assert t.get(\"required\") == True
assert t.get(\"type\") == \"string\"
'"
run_test "T11: workflow_call secrets include keystore + firebase + playstore set" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
got = set(d[\"on\" if \"on\" in d else True][\"workflow_call\"][\"secrets\"].keys())
expected = set([\"google_services\",\"firebase_creds\",\"playstore_creds\",\"upload_keystore\",\"keystore_password\",\"keystore_alias\",\"keystore_alias_password\"])
assert expected.issubset(got), \"missing secrets: \" + str(expected - got)
'"
run_test "T12: all workflow_call secrets are required:True (Android: strict upfront — different from desktop/web's optional pattern)" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
for name, spec in d[\"on\" if \"on\" in d else True][\"workflow_call\"][\"secrets\"].items():
    assert spec.get(\"required\") == True, name + \" should be required (Android requires all 7 keystore+firebase+playstore secrets upfront)\"
'"
echo

# ── Tier 3: Job structure ────────────────────────────────────────────────────
echo "── Tier 3: Job structure ──"
run_test "T13: All 5 expected jobs present" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
got = set(d[\"jobs\"].keys())
exp = set([\"validate-secrets\",\"stage-0-firebase\",\"stage-1-play-internal\",\"stage-2-promote-to-beta\",\"stage-3-promote-to-production\"])
assert got == exp, \"diff: \" + str(got.symmetric_difference(exp))
'"
run_test "T14: stage-0 depends on validate-secrets" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
assert d[\"jobs\"][\"stage-0-firebase\"][\"needs\"] == [\"validate-secrets\"]
'"
run_test "T15: stage-1 depends on stage-0 (sequential ladder)" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
assert d[\"jobs\"][\"stage-1-play-internal\"][\"needs\"] == [\"stage-0-firebase\"]
'"
run_test "T16: stage-2 depends on stage-1" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
assert d[\"jobs\"][\"stage-2-promote-to-beta\"][\"needs\"] == [\"stage-1-play-internal\"]
'"
run_test "T17: stage-3 depends on stage-2" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
assert d[\"jobs\"][\"stage-3-promote-to-production\"][\"needs\"] == [\"stage-2-promote-to-beta\"]
'"
echo

# ── Tier 4: Per-stage composite-action routing ────────────────────────────────
echo "── Tier 4: Per-stage composite-action routing ──"
run_test "T18: stage-0 uses firebase-distribution@v2.0.0" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
uses = [s[\"uses\"] for s in d[\"jobs\"][\"stage-0-firebase\"][\"steps\"] if isinstance(s,dict) and \"publish-android-kmp/\" in str(s.get(\"uses\",\"\"))]
assert uses == [\"therajanmaurya/mifos-x-actionhub-publish-android-kmp/firebase-distribution@v2.0.0\"], \"got: \" + str(uses)
'"
run_test "T19: stage-1 uses play-store-internal@v2.0.0" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
uses = [s[\"uses\"] for s in d[\"jobs\"][\"stage-1-play-internal\"][\"steps\"] if isinstance(s,dict) and \"publish-android-kmp/\" in str(s.get(\"uses\",\"\"))]
assert uses == [\"therajanmaurya/mifos-x-actionhub-publish-android-kmp/play-store-internal@v2.0.0\"], \"got: \" + str(uses)
'"
run_test "T20: stage-2 uses promote-to-beta@v2.0.0" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
uses = [s[\"uses\"] for s in d[\"jobs\"][\"stage-2-promote-to-beta\"][\"steps\"] if isinstance(s,dict) and \"publish-android-kmp/\" in str(s.get(\"uses\",\"\"))]
assert uses == [\"therajanmaurya/mifos-x-actionhub-publish-android-kmp/promote-to-beta@v2.0.0\"], \"got: \" + str(uses)
'"
run_test "T21: stage-3 uses promote-to-production@v2.0.0" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
uses = [s[\"uses\"] for s in d[\"jobs\"][\"stage-3-promote-to-production\"][\"steps\"] if isinstance(s,dict) and \"publish-android-kmp/\" in str(s.get(\"uses\",\"\"))]
assert uses == [\"therajanmaurya/mifos-x-actionhub-publish-android-kmp/promote-to-production@v2.0.0\"], \"got: \" + str(uses)
'"
echo

# ── Tier 5: Composite-action existence ───────────────────────────────────────
echo "── Tier 5: Composite-action existence ──"
for A in "${ACTIONS[@]}"; do
    run_test "T2x:  $A/action.yaml exists + parses" \
        "test -f '$A/action.yaml' && py 'import yaml; yaml.safe_load(open(\"$A/action.yaml\"))'"
done
for A in "${ACTIONS[@]}"; do
    run_test "T2y:  $A/action.yaml is composite + has steps" "py '
import yaml
d = yaml.safe_load(open(\"$A/action.yaml\"))
assert d[\"runs\"][\"using\"] == \"composite\"
assert d[\"runs\"].get(\"steps\"), \"$A has no steps\"
'"
done
for A in "${ACTIONS[@]}"; do
    run_test "T2z:  $A/README.md exists" "test -f '$A/README.md'"
done
echo

# ── Tier 6: Caller-callee interface contract ─────────────────────────────────
echo "── Tier 6: Caller-callee interface contract ──"
run_test "T31: firebase-distribution declares android_package_name + firebase_creds + tester_groups" "py '
import yaml
d = yaml.safe_load(open(\"firebase-distribution/action.yaml\"))
declared = set(d.get(\"inputs\", {}).keys())
required = set([\"android_package_name\",\"firebase_creds\",\"tester_groups\"])
assert required.issubset(declared), \"missing: \" + str(required - declared)
'"
run_test "T32: play-store-internal declares android_package_name + playstore_creds + keystore_*" "py '
import yaml
d = yaml.safe_load(open(\"play-store-internal/action.yaml\"))
declared = set(d.get(\"inputs\", {}).keys())
required = set([\"android_package_name\",\"playstore_creds\",\"keystore_file\",\"keystore_password\"])
assert required.issubset(declared), \"missing: \" + str(required - declared)
'"
run_test "T33: promote-to-beta declares android_package_name + playstore_creds" "py '
import yaml
d = yaml.safe_load(open(\"promote-to-beta/action.yaml\"))
declared = set(d.get(\"inputs\", {}).keys())
required = set([\"android_package_name\",\"playstore_creds\"])
assert required.issubset(declared), \"missing: \" + str(required - declared)
'"
run_test "T34: promote-to-production declares android_package_name + playstore_creds + rollout" "py '
import yaml
d = yaml.safe_load(open(\"promote-to-production/action.yaml\"))
declared = set(d.get(\"inputs\", {}).keys())
required = set([\"android_package_name\",\"playstore_creds\",\"rollout\"])
assert required.issubset(declared), \"missing: \" + str(required - declared)
'"
echo

# ── Tier 7: validate-secrets coverage ────────────────────────────────────────
echo "── Tier 7: validate-secrets coverage ──"
run_test "T35: validate-secrets checks google_services" \
    "grep -E 'google_services' .github/workflows/release.yaml | head -1"
run_test "T36: validate-secrets checks upload_keystore" \
    "grep -E 'upload_keystore' .github/workflows/release.yaml | head -1"
run_test "T37: validate-secrets checks firebase_creds (for firebase rungs)" \
    "grep -E 'firebase_creds' .github/workflows/release.yaml | head -1"
run_test "T38: validate-secrets checks playstore_creds (for play rungs)" \
    "grep -E 'playstore_creds' .github/workflows/release.yaml | head -1"
echo

# ── Tier 8: Rung-conditional logic ───────────────────────────────────────────
echo "── Tier 8: Rung-conditional logic ──"
run_test "T39: stage-0-firebase if covers {firebase, internal, beta, production}" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
cond = d[\"jobs\"][\"stage-0-firebase\"][\"if\"]
for r in [\"firebase\",\"internal\",\"beta\",\"production\"]:
    assert r in cond, r + \" not in stage-0 if-condition: \" + cond
'"
run_test "T40: stage-1-play-internal if covers {internal, beta, production}" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
cond = d[\"jobs\"][\"stage-1-play-internal\"][\"if\"]
for r in [\"internal\",\"beta\",\"production\"]:
    assert r in cond, r + \" not in stage-1 if-condition: \" + cond
'"
run_test "T41: stage-2-promote-to-beta if covers {beta, production}" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
cond = d[\"jobs\"][\"stage-2-promote-to-beta\"][\"if\"]
for r in [\"beta\",\"production\"]:
    assert r in cond, r + \" not in stage-2 if-condition: \" + cond
'"
run_test "T42: stage-3-promote-to-production if requires 'production' (terminal rung)" "py '
import yaml
d = yaml.safe_load(open(\".github/workflows/release.yaml\"))
cond = d[\"jobs\"][\"stage-3-promote-to-production\"][\"if\"]
assert \"production\" in cond
'"
echo

# ── Tier 9: Runtime bug-class regressions (since v2.0.6) ─────────────────────
#
# Locks down bug classes that broke real workflow runs. Each test asserts the
# absence of a known bad pattern across every action.yaml in this repo.
echo "── Tier 9: Runtime bug-class regressions ──"
run_test "T43: No bare gem-write commands (every gem install/bundle install/fastlane add_plugin must be sudo or bundle-exec-prefixed)" "python3 -c '
import re, glob
# Patterns that fail on GHA runner images post-2026-06 (system gem dir /var/lib/gems is root-owned)
BARE_PATTERNS = [
    re.compile(r\"^\\s+(?:run:\\s*)?(?:gem install|bundle install|fastlane add_plugin|gem update)(?:\\s|$)\"),
    re.compile(r\"^\\s+(?:run:\\s*\\|)?\\s*(gem install|bundle install|fastlane add_plugin|gem update)(?:\\s|$)\"),
]
SAFE_PREFIXES = (\"sudo \", \"bundle exec \", \"sudo bundle\", \"DEBIAN_FRONTEND=\")
violations = []
for action_yaml in glob.glob(\"**/action.yaml\", recursive=True):
    if \"/_shared/\" in action_yaml or \"/examples/\" in action_yaml:
        continue
    with open(action_yaml) as f:
        in_run_block = False
        for line_num, line in enumerate(f, 1):
            stripped = line.strip()
            if stripped.startswith(\"#\"):
                continue
            # Detect run: | block
            if re.match(r\"\\s+run:\\s*\\|?\\s*$\", line) or re.match(r\"\\s+run:\\s+(.+)$\", line):
                in_run_block = True
            # Look for gem-write commands
            for pat in BARE_PATTERNS:
                m = pat.match(line)
                if m:
                    cmd_text = (m.group(1) if m.lastindex else stripped.lstrip(\"run:\").strip())
                    # Check if preceded by safe prefix
                    if not any(p in line for p in SAFE_PREFIXES):
                        violations.append(f\"{action_yaml}:{line_num}  {stripped[:80]}\")
if violations:
    print(\"FAIL — bare gem-write commands found (need sudo or bundle exec):\")
    for v in violations: print(f\"  {v}\")
    exit(1)
print(\"OK — no bare gem-write commands\")
'"
run_test "T44: ruby/setup-ruby steps use bundler-cache:true (gem cache enabled)" "py '
import yaml, glob
for action_yaml in glob.glob(\"**/action.yaml\", recursive=True):
    if \"/_shared/\" in action_yaml or \"/examples/\" in action_yaml:
        continue
    d = yaml.safe_load(open(action_yaml))
    if not d or \"runs\" not in d or \"steps\" not in d[\"runs\"]:
        continue
    for step in d[\"runs\"][\"steps\"]:
        if isinstance(step, dict) and \"setup-ruby\" in str(step.get(\"uses\", \"\")):
            w = step.get(\"with\", {})
            assert w.get(\"bundler-cache\") in [True, \"true\"], action_yaml + \" — setup-ruby missing bundler-cache:true\"
'"
echo

# ─────────────────────────────────────────────────────────────────────────────
echo "════════════════════════════════════════════════════════════════════════════"
echo "  Results: $PASS passed · $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    echo "  Failed tests:"
    for t in "${FAILED_TESTS[@]}"; do echo "    - $t"; done
fi
echo "════════════════════════════════════════════════════════════════════════════"
exit $FAIL
