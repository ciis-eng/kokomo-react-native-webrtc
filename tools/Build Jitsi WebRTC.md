# Building Jitsi version of WebRTC.xcframework

## Notes:
- for build-jitsi-webrtc.sh, use "ios" or "android" params, and the optional tagName param to specify a new release tag
- IOS needs to be built on Mac & Android needs to be built on Linux
- tools/patches contain git patches
	- patches/src contains patches to webrtc src folder
- 2 new commands were added to build-webrtc.py
	- setup_depot_tools: default depot_tools pulled from GoogleSource webRTC repo, changed to pull jitsi webRTC repo 
	- setup_src: will use package.json "tagRepo" attribute to get jitsi git tag to checkout; will also apply patches/src patches

## Steps:
1.	cd ~/kokomo-react-native-webrtc/tools/
2.	./build-jitsi-webrtc.sh ios | android [tagName]