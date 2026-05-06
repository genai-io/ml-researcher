#!/usr/bin/env bash
# Single source for mechanical methodology checks shared by hooks and the
# /check slash command (via the checklist-verify skill). Each check is
# callable as `bash <CFG>/hooks/checks.sh <check-name>`.
#
# Convention:
#   exit 0 — pass, no output
#   exit 1 — fail, one-line reason on stderr
#   exit 2 — usage error
#
# Why this script exists: the same rules used to be inlined in preflight.sh,
# phase_gate.sh, checklist-verify.md, and phase-advance.md, and they had
# already drifted (the baseline rule allowed `status≠crash` in one place but
# required `status=keep` in two others). Encoding them once here means hooks
# and the agent run identical logic; the skills now point at this file as
# the authority.
set -uo pipefail

check_progress_present() {
  if [ ! -f research/progress.md ]; then
    echo "research/progress.md missing" >&2
    return 1
  fi
}

check_baseline_kept() {
  # A registered baseline is a row in experiments/ledger.tsv whose description
  # contains "baseline" (case-insensitive) AND whose status field is "keep".
  if [ ! -f experiments/ledger.tsv ]; then
    echo "experiments/ledger.tsv missing — no baseline registered yet" >&2
    return 1
  fi
  if ! awk -F'\t' 'BEGIN{IGNORECASE=1} /baseline/ { for (i=1;i<=NF;i++) if ($i=="keep") { found=1; exit } } END{ exit !found }' experiments/ledger.tsv; then
    echo "no row in experiments/ledger.tsv has description containing 'baseline' AND status=keep" >&2
    return 1
  fi
}

check_no_test_refs_in_current_exp() {
  # The current branch's experiment dir must not reference data/splits/test/.
  # Selection/Tuning phases are not allowed to read the locked test split.
  local branch exp_dir
  branch=$(git branch --show-current 2>/dev/null || echo "")
  case "$branch" in
    mlr/exp/*) exp_dir="experiments/${branch#mlr/exp/}" ;;
    *) return 0 ;;  # not on an experiment branch — nothing to check
  esac
  [ -d "$exp_dir" ] || return 0
  if grep -rq "data/splits/test" "$exp_dir" 2>/dev/null; then
    echo "$exp_dir references data/splits/test/ — Selection/Tuning must not read test data" >&2
    return 1
  fi
}

case "${1:-}" in
  progress-present)               check_progress_present ;;
  baseline-kept)                  check_baseline_kept ;;
  no-test-refs-in-current-exp)    check_no_test_refs_in_current_exp ;;
  "")
    echo "usage: $0 <check-name>" >&2
    echo "checks: progress-present | baseline-kept | no-test-refs-in-current-exp" >&2
    exit 2
    ;;
  *)
    echo "unknown check: $1" >&2
    exit 2
    ;;
esac
