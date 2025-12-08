#!/bin/bash
set -e

# Usage: ./auth.sh <WIF_PROVIDER_NAME> <SERVICE_ACCOUNT_EMAIL>

WIF_PROVIDER_NAME="$1"
SERVICE_ACCOUNT_EMAIL="$2"

if [[ -z "$WIF_PROVIDER_NAME" || -z "$SERVICE_ACCOUNT_EMAIL" ]]; then
  echo "Usage: $0 <WIF_PROVIDER_NAME> <SERVICE_ACCOUNT_EMAIL>"
  exit 1
fi

if [[ -z "$ACTIONS_ID_TOKEN_REQUEST_URL" || -z "$ACTIONS_ID_TOKEN_REQUEST_TOKEN" ]]; then
  echo "Error: GitHub Actions OIDC environment variables not found."
  echo "Ensure 'permissions: id-token: write' is set in your workflow."
  exit 1
fi

# ------------------------------------------------------------------------------
# 1. Get GitHub OIDC Token
# ------------------------------------------------------------------------------
# We use the WIF Provider Name as the audience
# We must URL encode the audience for the GET request
ENCODED_AUDIENCE=$(jq -rn --arg x "$WIF_PROVIDER_NAME" '$x|@uri')
GITHUB_OIDC_TOKEN=$(curl -s -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=${ENCODED_AUDIENCE}" | jq -r '.value')

if [[ "$GITHUB_OIDC_TOKEN" == "null" ]]; then
  echo "Failed to retrieve GitHub OIDC token"
  exit 1
fi

# ------------------------------------------------------------------------------
# 2. Exchange for Google STS Token (Security Token Service)
# ------------------------------------------------------------------------------
# The audience for STS must be prefixed with //iam.googleapis.com/
STS_TOKEN=$(curl -s -X POST "https://sts.googleapis.com/v1/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"audience\": \"//iam.googleapis.com/${WIF_PROVIDER_NAME}\",
    \"grantType\": \"urn:ietf:params:oauth:grant-type:token-exchange\",
    \"requestedTokenType\": \"urn:ietf:params:oauth:token-type:access_token\",
    \"scope\": \"https://www.googleapis.com/auth/cloud-platform\",
    \"subjectTokenType\": \"urn:ietf:params:oauth:token-type:jwt\",
    \"subjectToken\": \"${GITHUB_OIDC_TOKEN}\"
  }" | jq -r '.access_token')

if [[ "$STS_TOKEN" == "null" ]]; then
  echo "Failed to retrieve STS token"
  exit 1
fi

# ------------------------------------------------------------------------------
# 3. Impersonate Service Account (Generate final OAuth Token)
# ------------------------------------------------------------------------------
GCP_ACCESS_TOKEN=$(curl -s -X POST "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${SERVICE_ACCOUNT_EMAIL}:generateAccessToken" \
  -H "Authorization: Bearer ${STS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"scope\": [ \"https://www.googleapis.com/auth/cloud-platform\" ]
  }" | jq -r '.accessToken')

if [[ "$GCP_ACCESS_TOKEN" == "null" ]]; then
  echo "Failed to generate Service Account access token"
  exit 1
fi

# Output the token (or mask it/export it as needed)
echo "$GCP_ACCESS_TOKEN"
