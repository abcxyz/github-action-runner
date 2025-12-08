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

GCLOUD_CONFIG_FILE="/tmp/gcp_creds.json"

WIF_PROVIDER="projects/712187603283/locations/global/workloadIdentityPools/github-automation/providers/gar-ci-i"
SA_EMAIL="github-automation-bot@gha-gar-ci-i-be70aa.iam.gserviceaccount.com"

{
  echo "pre-run.sh script"
  echo "Runner lock file created at ${LOCK_FILE}. Idle timeout is now disabled."

  GOOGLE_TOKEN="$(/workspace/generate-token.sh "${WIF_PROVIDER}" "${SA_EMAIL}")"
  echo "GOOGLE_TOKEN=${GOOGLE_TOKEN}"
  echo "GOOGLE_TOKEN=${GOOGLE_TOKEN}" >> "${GITHUB_ENV}"
  export GOOGLE_TOKEN="${GOOGLE_TOKEN}"
} >> "${PRERUN_LOG_FILE}"
