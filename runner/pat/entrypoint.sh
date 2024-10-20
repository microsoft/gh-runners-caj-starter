#!/bin/sh -l

### parameters ###
# $GH_PAT
# $REGISTRATION_TOKEN_API_URL
# $REPO_URL

# Retrieve a short lived runner registration token using the PAT
REGISTRATION_TOKEN="$(curl -X POST -fsSL \
  -H 'Accept: application/vnd.github.v3+json' \
  -H "Authorization: Bearer $GH_PAT" \
  -H 'X-GitHub-Api-Version: 2022-11-28' \
  "$REGISTRATION_TOKEN_API_URL" \
  | jq -r '.token')"

./config.sh --url $REPO_URL --token $REGISTRATION_TOKEN --labels runner-pat --unattended --ephemeral && ./run.sh
