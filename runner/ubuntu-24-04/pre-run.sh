#!/bin/bash
set -euo pipefail

# log to a file to that gets dumped to stdout in cloud build logs.
PRERUN_LOG_FILE="/tmp/pre-run.log"
function log {
  if [ ! -f "${PRERUN_LOG_FILE}" ]; then
    touch "${PRERUN_LOG_FILE}"
  fi
  "$@" 2>&1 | tee -a "$PRERUN_LOG_FILE"
    
  local status="${PIPESTATUS[0]}"
  if [ "${status}" -ne 0 ]; then
    echo "Command \"$*\" failed with status ${status}. Check ${PRERUN_LOG_FILE} for details." | tee -a "${PRERUN_LOG_FILE}"
  fi
  return "${status}"
}

LOCK_FILE="/tmp/runner.lock"
touch "${LOCK_FILE}"
log echo "Runner lock file created at ${LOCK_FILE}. Idle timeout is now disabled."

log echo "pre-run.sh script"
log printenv

GOOGLE_TOKEN="this-is-a-test"
echo "GOOGLE_TOKEN=${GOOGLE_TOKEN}" >> /actions-runner/.env
export GOOGLE_TOKEN="${GOOGLE_TOKEN}"
