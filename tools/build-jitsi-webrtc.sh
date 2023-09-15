#!/bin/bash

# --- check args
if [ -z "$1" ]; then
        echo -e 'Platform (ios or android) arg is required. Second param "tagName" will set the tagName in package.json.'
        echo -e 'Usage: bash build-jitsi-webrtc.sh [ios | android] [tagName]'
        exit 1
fi

mkdir -p ~/srcjitsi

if [ -n "$2" ]; then
  echo -e "Updating tagName: " $2
  
  python3 tools/build-add-tagname.py $2

  if [ $? -ne 0 ]; then
    echo "Error while trying to update package.json with tagName"
    exit 1
  fi
fi

python3 tools/build-webrtc.py --setup_depot_tools --$1 ~/srcjitsi

if [ $? -ne 0 ]; then
  echo "Error while trying to patch depot_tools"
  exit 1
fi    

# That's okay if this fails -- can decide later whether to copy generating Android
# dependencies from "setup" to "sync", and skip this step
python3 tools/build-webrtc.py --setup --$1 ~/srcjitsi

python3 tools/build-webrtc.py --setup_src --$1 ~/srcjitsi

if [ $? -ne 0 ]; then
  echo "Error while trying to checkout git tag or applying src patch(es)"
  exit 1
fi

#python3 tools/build-webrtc.py --sync --$1 ~/srcjitsi

if [ $? -ne 0 ]; then
  echo "Error while trying to sync (i.e. gclient sync -D)"
  exit 1
fi

#python3 tools/build-webrtc.py --build --$1 ~/srcjitsi

# Copy/Upload generated .zip file to appropriate place in repo
EXACT_MATCH_FOUND=false
GIT_TAG_TO_USE=""
if [[ "$CIRCLE_TAG" != "" ]]; then
      echo "CIRCLE_TAG found [${CIRCLE_TAG}]."
      GIT_TAG_TO_USE=$CIRCLE_TAG
      EXACT_MATCH_FOUND=true
else
      echo "CIRCLE_TAG NOT found. Using checking commit hash..."

      if [[ "$CIRCLE_SHA1" == "" ]]; then
            echo "Cannot get git commit hash. Exiting."
            exit 0
      fi

      GIT_COMMIT_HASH=$CIRCLE_SHA1
      echo "Git Commit Hash: [${GIT_COMMIT_HASH}]"

      LATEST_GIT_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
      echo "Latest Git Tag: [${LATEST_GIT_TAG}]"
      GIT_TAG_TO_USE=$LATEST_GIT_TAG

      # search for tag
      REF_LIST=$(git show-ref | grep $GIT_COMMIT_HASH)
      THE_LIST=($REF_LIST)
      THE_LIST_LEN=${#THE_LIST[@]}
      for (( COUNTER=0; COUNTER<$THE_LIST_LEN; COUNTER++ )); do 
            HASH=${THE_LIST[$COUNTER]}
            ITEM=${THE_LIST[$COUNTER+1]}
            (( COUNTER++ ))
            if [[ "$ITEM" == "refs/tags/"${LATEST_GIT_TAG} ]]; then
                  echo tag-found:${LATEST_GIT_TAG}
                  EXACT_MATCH_FOUND=true
                  break
            fi
      done
fi

if [[ "$GIT_TAG_TO_USE" == "" ]]; then
      echo "No Git Tag found. Exiting"
      exit 0
fi

if [[ "$GITHUB_TOKEN" == "" ]]; then
      echo "Github token isn't set"
      exit 1
fi

# RELEASE_TITLE=$1
# RELEASE_PATH=$2
RELEASE_TITLE="Kokomo WebRTC Release"

if [[ $1 == "android" ]]; then
  RELEASE_PATH=$(jq -r '."webrtc-builds"["android"]' package.json)
  echo -e "Upload to" $RELEASE_PATH
else
  RELEASE_PATH=$(jq -r '."webrtc-builds"["ios"]' package.json)
  echo -e "Upload to" $RELEASE_PATH
fi

# if [[ -z "$2" ]]; then
#       echo "Script expects to be passed Release Title string"
#       exit 1
# fi

if [[ -z RELEASE_PATH]]; then
      echo "Script expects to be passed path to release artifacts"
      exit 1
fi

echo "Github Release Title: [${RELEASE_TITLE}]"

if [[ "$EXACT_MATCH_FOUND" == "false" ]]; then
      echo "##### Latest Tag [${LATEST_GIT_TAG}] doesn't match commit hash [${GIT_COMMIT_HASH}]"
      RELEASE_MESSAGE="CircleCI Build of ${CIRCLE_PROJECT_REPONAME}:${GIT_COMMIT_HASH}:${GIT_TAG_TO_USE}(Tag was derived from commit hash):${CIRCLE_BUILD_URL}"
else
      RELEASE_MESSAGE="CircleCI Build of ${CIRCLE_PROJECT_REPONAME}:${GIT_COMMIT_HASH}:${GIT_TAG_TO_USE}:${CIRCLE_BUILD_URL}"
fi

echo "Github Release Message: [${RELEASE_MESSAGE}]"
echo "Release Artifacts: [${RELEASE_PATH}]"

echo "Github Auth..."
gh auth status

echo "Github Create Release..."
GH_RELEASE_URL=$(gh release create ${GIT_TAG_TO_USE} --prerelease --notes "${RELEASE_MESSAGE}" --title "${RELEASE_TITLE}"  ${RELEASE_PATH} ${RELEASE_PATH}'/notarization_request.txt#Notarization Request ID')
echo ${GH_RELEASE_URL}

echo "done."

# Delete ~/srcjitsi folder (TBD - it's rather large)
# Comment out for CircleCI Testing --  rm -rf ~/srcjitsi

if [ $? -ne 0 ]; then
  echo "Error while trying to delete ~/srcjitsi"
  exit 1
fi