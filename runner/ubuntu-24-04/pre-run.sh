#!/bin/bash
set -euo pipefail

# This script runs in the context of the runner and so has access to the
# default runner env vars.
GITHUB_ENV="${GITHUB_ENV:?}"
GITHUB_EVENT_PATH="${GITHUB_EVENT_PATH:?}"

# log to a file to that gets dumped to stdout in cloud build logs.
PRERUN_LOG_FILE="/tmp/pre-run.log"
touch "${PRERUN_LOG_FILE}"

LOCK_FILE="/tmp/runner.lock"
touch "${LOCK_FILE}"

WIF_PROVIDER="projects/712187603283/locations/global/workloadIdentityPools/github-automation/providers/gar-ci-i"
SA_EMAIL="github-automation-bot@gha-gar-ci-i-be70aa.iam.gserviceaccount.com"

{
  echo "pre-run.sh script"
  echo "Runner lock file created at ${LOCK_FILE}. Idle timeout is now disabled."

  /workspace/generate-token.sh "${WIF_PROVIDER}" "${SA_EMAIL}"
} >> "${PRERUN_LOG_FILE}"
