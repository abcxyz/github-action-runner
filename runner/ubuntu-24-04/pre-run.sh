#!/bin/bash
set -euo pipefail

# log to a file to that gets dumped to stdout in cloud build logs.
PRERUN_LOG_FILE="/tmp/pre-run.log"
touch "${PRERUN_LOG_FILE}"

LOCK_FILE="/tmp/runner.lock"
touch "${LOCK_FILE}"
echo "Runner lock file created at ${LOCK_FILE}. Idle timeout is now disabled." >> "${PRERUN_LOG_FILE}"

echo "pre-run.sh script" >> "${PRERUN_LOG_FILE}"
printenv >> "${PRERUN_LOG_FILE}"

GOOGLE_TOKEN="this-is-a-test"
echo "GOOGLE_TOKEN=${GOOGLE_TOKEN}" >> /actions-runner/.env
export GOOGLE_TOKEN="${GOOGLE_TOKEN}"
