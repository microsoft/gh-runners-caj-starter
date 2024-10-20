#!/bin/sh -l

### parameters ###
# GH_APP_ID
# GH_APP_PEM
# GH_APP_INSTALL_ID
# REPO_URL
# REGISTRATION_TOKEN_API_URL

NOW=$( date +%s )
IAT=$((${NOW}  - 60))
EXP=$((${NOW} + 540))
HEADER_RAW='{"alg":"RS256"}'
HEADER=$( echo -n "${HEADER_RAW}" | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n' )
PAYLOAD_RAW='{"iat":'"${IAT}"',"exp":'"${EXP}"',"iss":'"${GH_APP_ID}"'}'
PAYLOAD=$( echo -n "${PAYLOAD_RAW}" | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n' )
HEADER_PAYLOAD="${HEADER}"."${PAYLOAD}"

# Making a tmp directory here because /bin/sh doesn't support process redirection <()
tmp_dir="/tmp/github_app_tmp"
mkdir "${tmp_dir}"
echo -n "${GH_APP_PEM}" > "${tmp_dir}/github.pem"
echo -n "${HEADER_PAYLOAD}" > "${tmp_dir}/header"
SIGNATURE=$( openssl dgst -sha256 -sign "${tmp_dir}/github.pem" "${tmp_dir}/header" | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n' )
rm -rf "${tmp_dir}"

JWT="${HEADER_PAYLOAD}"."${SIGNATURE}"
INSTALL_TOKEN_PAYLOAD=$(curl --request POST --url "https://api.github.com/app/installations/${GH_APP_INSTALL_ID}/access_tokens" --header "Accept: application/vnd.github+json" --header "Authorization: Bearer ${JWT}" --header "X-GitHub-Api-Version: 2022-11-28")
INSTALL_TOKEN=$(echo ${INSTALL_TOKEN_PAYLOAD} | jq .token --raw-output)

# Retrieve a short lived runner registration token using the INSTALL_TOKEN
REGISTRATION_TOKEN="$(curl --request POST --url $REGISTRATION_TOKEN_API_URL --header "Accept: application/vnd.github+json" --header "Authorization: Bearer ${INSTALL_TOKEN}" --header "X-GitHub-Api-Version: 2022-11-28"| jq -r '.token')"

./config.sh --url $REPO_URL --token $REGISTRATION_TOKEN --labels runner-ghapp-pem --unattended --ephemeral && ./run.sh
