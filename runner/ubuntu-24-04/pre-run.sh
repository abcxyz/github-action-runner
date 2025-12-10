#!/bin/bash
set -euo pipefail

# This script runs in the context of the runner and so has access to the
# default runner env vars.
GITHUB_ENV="${GITHUB_ENV:?}"
GITHUB_EVENT_PATH="${GITHUB_EVENT_PATH:?}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:?}"
GITHUB_REF="${GITHUB_REF:?}"
ACTIONS_ID_TOKEN_REQUEST_TOKEN="${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}"

# log to a file to that gets dumped to stdout in cloud build logs.
PRERUN_LOG_FILE="/tmp/pre-run.log"
touch "${PRERUN_LOG_FILE}"

LOCK_FILE="/tmp/runner.lock"
touch "${LOCK_FILE}"

{
  echo "pre-run.sh script"
  echo "Runner lock file created at ${LOCK_FILE}. Idle timeout is now disabled."

  echo "ENV:"
  printenv

  echo "Webhook event payload ${GITHUB_EVENT_PATH}:"
  cat "${GITHUB_EVENT_PATH}"

  if [[ "${ACTIONS_ID_TOKEN_REQUEST_TOKEN}" == "" ]]; then
    echo "Permission 'id-token: write' not set on job. Skipping generating google token."
  fi

  gh repo clone "${GITHUB_REPOSITORY}" "/tmp/${GITHUB_REPOSITORY}" -- --branch "${GITHUB_REF}" --single-branch

  WORKLOAD_IDENTITY_PROVIDER="$(grep -E "WORKLOAD_IDENTITY_PROVIDER=" "/tmp/${GITHUB_REPOSITORY}"/.github/google.env | cut -d'=' -f2- || true)"
  WIF_SERVICE_ACCOUNT="$(grep -E "WORKLOAD_IDENTITY_PROVIDER=" "/tmp/${GITHUB_REPOSITORY}"/.github/google.env | cut -d'=' -f2- || true)"
  GOOGLE_ARTIFACT_REGISTRIES="$(grep -E "WORKLOAD_IDENTITY_PROVIDER=" "/tmp/${GITHUB_REPOSITORY}"/.github/google.env | cut -d'=' -f2- || true)"

  if [[ "${WORKLOAD_IDENTITY_PROVIDER}" != "" && "${WIF_SERVICE_ACCOUNT}" != "" ]]; then
    GOOGLE_TOKEN="$(/workspace/generate-token.sh "${WORKLOAD_IDENTITY_PROVIDER}" "${WIF_SERVICE_ACCOUNT}")"
    echo "GOOGLE_TOKEN=${GOOGLE_TOKEN}" >> "${GITHUB_ENV}"
  else
    echo "google.env file is missing WORKLOAD_IDENTITY_PROVIDER or WIF_SERVICE_ACCOUNT. Skipping generating token."
  fi

  if [[ "${GOOGLE_TOKEN}" != "" && "${GOOGLE_ARTIFACT_REGISTRIES}" != "" ]]; then
    gar_registries_array=("${GOOGLE_ARTIFACT_REGISTRIES//,/ }")
    for gar_registry in "${gar_registries_array[@]}"; do
      echo "Logging in to docker registry: ${gar_registry}"
      echo "${GOOGLE_TOKEN}" | docker login -u oauth2accesstoken --password-stdin "https://${gar_registry}"
    done
  else
    echo "Missing either GOOGLE_TOKEN or GOOGLE_ARTIFACT_REGISTRIES. Skipping login to docker registries."
  fi
} >> "${PRERUN_LOG_FILE}"
