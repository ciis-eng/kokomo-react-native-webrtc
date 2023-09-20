# Building Jitsi version of WebRTC for Kokomo

## Notes:
- The react-native-webrtc build-webrtc.py app for some reason uses Google Source WebRTC, whereas the provided WebRTC libraries were generated using jitsi WebRTC. 
	- patches were created to build using the jitsi WebRTC repo instead
- tools/patches contain git patches
	- patches/src contains patches to webrtc src folder
- package.json had 2 new attributes added
	- repoTag - added to specify which tag to use for jitsi/webrtc repo
	- tagName - contains tag used for automated build
	- NOTE: version attribute is from the WebRTC repo, and does not need to be set for the this build
- 2 new commands were added to build-webrtc.py
	- setup_depot_tools: default depot_tools pulled from GoogleSource webRTC repo, changed to pull jitsi webRTC repo 
	- setup_src: will use package.json "repoTag" attribute to get jitsi git tag to checkout; will also apply patches/src patches
- For standalone build:
	- for release-webrtc.sh, use "ios" or "android" params
	- IOS needs to be built on Mac & Android needs to be built on Linux

## Steps for Automated Build
1.	cd ~/kokomo-react-native-webrtc
2.	python3 tools/build-add-tagname.py *tagName*
3.	git commit & push updated package.json 
4.	git tag repo with "tagName" to start the CircleCI build

## Steps for Standalone Build
1.	cd ~/kokomo-react-native-webrtc
2.	./tools/release-webrtc.sh ios | android
