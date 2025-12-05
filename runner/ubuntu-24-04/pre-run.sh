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
  printenv

  GOOGLE_TOKEN="this-is-a-test"
  echo "GOOGLE_TOKEN=${GOOGLE_TOKEN}" >> /actions-runner/.env
  export GOOGLE_TOKEN="${GOOGLE_TOKEN}"
} >> "${PRERUN_LOG_FILE}"
