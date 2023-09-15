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

python3 tools/build-webrtc.py --sync --$1 ~/srcjitsi

if [ $? -ne 0 ]; then
  echo "Error while trying to sync (i.e. gclient sync -D)"
  exit 1
fi

python3 tools/build-webrtc.py --build --$1 ~/srcjitsi

# Copy/Upload generated .zip file to appropriate place in repo (TBD)

# Delete ~/srcjitsi folder (TBD - it's rather large)
# Comment out for CircleCI Testing --  rm -rf ~/srcjitsi

if [ $? -ne 0 ]; then
  echo "Error while trying to delete ~/srcjitsi"
  exit 1
fi