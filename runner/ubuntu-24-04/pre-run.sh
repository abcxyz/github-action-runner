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
GAR_IMAGE="us-central1-docker.pkg.dev/github-action-runner-i-02/ci-images/smoke-test-container-test"
GAR_IMAGE_REGISTRY=$(echo "${GAR_IMAGE}" | cut -d '/' -f 1)

{
  echo "pre-run.sh script"
  echo "Runner lock file created at ${LOCK_FILE}. Idle timeout is now disabled."

  echo "ENV:"
  printenv

  echo "ENV file /workspace/.env:"
  cat /workspace/.env

  echo "Webhook event payload ${GITHUB_EVENT_PATH}:"
  cat "${GITHUB_EVENT_PATH}"

  GOOGLE_TOKEN="$(/workspace/generate-token.sh "${WIF_PROVIDER}" "${SA_EMAIL}")"
  echo "GOOGLE_TOKEN=${GOOGLE_TOKEN}" >> "${GITHUB_ENV}"
  echo "${GOOGLE_TOKEN}" | docker login -u oauth2accesstoken --password-stdin "https://${GAR_IMAGE_REGISTRY}"

  echo "GITHUB_ENV file ${GITHUB_ENV}:"
  cat "${GITHUB_ENV}"

  echo ""
  echo "cat /workspace/_work/_PipelineMapping/abcxyz/github-action-runner/PipelineFolder.json"
  cat /workspace/_work/_PipelineMapping/abcxyz/github-action-runner/PipelineFolder.json

  echo ""
  echo "ls -al /workspace/_work/github-action-runner/github-action-runner"
  ls -al /workspace/_work/github-action-runner/github-action-runner
} >> "${PRERUN_LOG_FILE}"
