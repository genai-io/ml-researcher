#!/usr/bin/env bash
# Surface a banner when .mlr-sandbox-mode exists at project root.
#
# Why a hook (vs letting the agent read the marker file): sandbox mode flips
# every methodology rule (mocks/fakes allowed, promotion blocked) but the
# marker is a hidden file — the agent won't notice it on its own. Phase /
# current-best / next-step used to be injected too; they were dropped because
# they are derivable from research/progress.md, which the agent can read on
# demand. Single source of truth, no shadow state.
set -uo pipefail

cat > /dev/null

[ -f .mlr-sandbox-mode ] || exit 0

EXPECT_COUNT=0
if [ -f experiments/ledger.tsv ]; then
  EXPECT_COUNT=$(grep -c '\[EXPECT\]' experiments/ledger.tsv 2>/dev/null || echo 0)
fi

EXPECT_COUNT="$EXPECT_COUNT" python3 - <<'PY'
import json, os
n = os.environ.get("EXPECT_COUNT", "0")
ctx = (
    f'<sandbox-mode rows="{n}">ACTIVE — mock/subset/fake results allowed; '
    'promotion to results/ blocked. See skills/sandbox-mode/SKILL.md.'
    '</sandbox-mode>'
)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": ctx,
    }
}))
PY
