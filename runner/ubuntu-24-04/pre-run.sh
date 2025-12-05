#!/bin/bash
set -euo pipefail

# log to a file to that gets dumped to stdout in cloud build logs.
PRERUN_LOG_FILE="/workspace/pre-run.log"
touch "${PRERUN_LOG_FILE}"

LOCK_FILE="/tmp/runner.lock"
touch "${LOCK_FILE}"

{
  echo "pre-run.sh script"
  echo "Runner lock file created at ${LOCK_FILE}. Idle timeout is now disabled."

  cat "${GITHUB_EVENT_PATH}"

  GOOGLE_TOKEN="this-is-a-test"
  echo "GOOGLE_TOKEN=${GOOGLE_TOKEN}" >> "${GITHUB_ENV}"
} >> "${PRERUN_LOG_FILE}"
