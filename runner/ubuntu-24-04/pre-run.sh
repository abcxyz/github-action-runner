#!/bin/bash
set -euo pipefail

# This script runs in the context of the runner and so has access to the
# default runner env vars.
GITHUB_ENV="${GITHUB_ENV:?}"
GITHUB_EVENT_PATH="${GITHUB_EVENT_PATH:?}"

# log to a file to that gets dumped to stdout in cloud build logs.
PRERUN_LOG_FILE="/workspace/pre-run.log"
touch "${PRERUN_LOG_FILE}"

LOCK_FILE="/tmp/runner.lock"
touch "${LOCK_FILE}"

{
  echo "pre-run.sh script"
  echo "Runner lock file created at ${LOCK_FILE}. Idle timeout is now disabled."

  cat "${GITHUB_ENV}"

  GOOGLE_TOKEN="this-is-a-test"
  echo "GOOGLE_TOKEN=${GOOGLE_TOKEN}" >> "${GITHUB_ENV}"
} >> "${PRERUN_LOG_FILE}"
