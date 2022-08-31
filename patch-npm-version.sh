#!/bin/bash

# Environment variables
ENV_ORGANISATION_NAME="$ORGANISATION_NAME"
ENV_PROJECT_NAME="$PROJECT_NAME"
ENV_FEED_NAME="$FEED_NAME"
ENV_SYSTEM_ACCESS_TOKEN="$SYSTEM_ACCESS_TOKEN"

echo "Starting..."

# Get variables from package.json
LOCAL_PACKAGE_NAME=$(jq -r ".name" package.json)
LOCAL_PACKAGE_VERSION=$(jq -r ".version" package.json)

# Build URL for getting Azure Feed information
GET_PACKAGE_ID_URL="https://feeds.dev.azure.com/${ENV_ORGANISATION_NAME}/${ENV_PROJECT_NAME}/_apis/packaging/Feeds/${ENV_FEED_NAME}/packages?protocolType=Npm&packageNameQuery=${LOCAL_PACKAGE_NAME}"      # next, let's get all available versions for our package

# Get package versions
ALL_VERSIONS_URL=$(curl -s -X GET -H "Authorization: Bearer ${ENV_SYSTEM_ACCESS_TOKEN}" "${GET_PACKAGE_ID_URL}" | jq -r '.value[0]._links.versions.href')
ALL_VERSIONS=$(curl -s -X GET -H "Authorization: Bearer ${ENV_SYSTEM_ACCESS_TOKEN}" "${ALL_VERSIONS_URL}" | jq -r '.value[].version')

# Initializes local variables that might be overwritten
NEW_VERSION=${LOCAL_PACKAGE_VERSION}
PATCH_VERSION_UPDATED="0"

# If local version exits in the artifact repository
if [[ " ${ALL_VERSIONS[*]} " =~ ${LOCAL_PACKAGE_VERSION} ]]; then
  echo "Current package version found in existing packages. Iterating the patch number..."

  # get latest version currently published in the feed for our package
  LATEST_VERSION=$(curl -s -X GET -H "Authorization: Bearer ${ENV_SYSTEM_ACCESS_TOKEN}" "${GET_PACKAGE_ID_URL}"| jq -r '.value[].versions[].version')
  IFS=. read -r i1 i2 i3 <<< "$LATEST_VERSION"
  PATCH_VERSION_UPDATED=$((i3 + 1))
  NEW_VERSION=$i1.$i2.$PATCH_VERSION_UPDATED

  # Replacing version in package.json for the publish task
  sed -i 's/"version": "'"${LOCAL_PACKAGE_VERSION}"'"/"version": "'"${NEW_VERSION}"'"/' package.json
fi

echo "New package version: ${NEW_VERSION}"

# Change info for pipeline overview
echo "##vso[task.setvariable variable=patch;]${PATCH_VERSION_UPDATED}"
echo "##vso[build.updatebuildnumber]${NEW_VERSION}"

echo "package.json version to publish: $(jq -r ".version" package.json)"
