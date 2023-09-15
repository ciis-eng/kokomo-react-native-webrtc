import argparse
import errno
import os
import shutil
import subprocess
import sys
import json

# Constants

ANDROID_LIBRARY_PATH = "https://github.com/ciis-eng/kokomo-react-native-webrtc/releases/download/"
ANDROID_LIBRARY_NAME = "/android-webrtc.zip"
APPLE_LIBRARY_PATH = "https://github.com/ciis-eng/kokomo-react-native-webrtc/releases/download/"
APPLE_LIBRARY_NAME = "/WebRTC.xcframework.zip"

# Utilities

def sh(cmd, env=None, cwd=None):
    print('Running cmd: %s' % cmd)
    try:
        subprocess.check_call(cmd, env=env, cwd=cwd, shell=True, stdin=sys.stdin, stdout=sys.stdout, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)
    except KeyboardInterrupt:
        pass

def mkdirp(path):
    try:
        os.makedirs(path)
    except OSError as e:
        if e.errno != errno.EEXIST:
            raise

def rmr(path):
    try:
        shutil.rmtree(path)
    except OSError as e:
        if e.errno != errno.ENOENT:
            raise

# Update package.json "version" attribute with the tagname of the release

def update_tag_name(tagName):
    # get package.json as JSON object
    fIn = open("package.json", "r")

    pkgJSON = json.loads(fIn.read())

    fIn.close()

    # Set version, webrtc-builds\android, & webrtc-builds\ios json attributes to specified tagName
    pkgJSON["version"] = tagName

    pkgJSON["webrtc-builds"]["android"] = ANDROID_LIBRARY_PATH + tagName + ANDROID_LIBRARY_NAME
    pkgJSON["webrtc-builds"]["ios"] = APPLE_LIBRARY_PATH + tagName + APPLE_LIBRARY_NAME

    print('Android library file: %s' % pkgJSON["webrtc-builds"]["android"])
    print('IOS library file: %s' % pkgJSON["webrtc-builds"]["ios"])

    # Write updated package.json file
    jsonOut = json.dumps(pkgJSON, indent=2)
 
    # Writing to sample.json
    with open("package.json", "w") as fOut:
        fOut.write(jsonOut)

    fOut.close()

# Do the update

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('tagName', help='tagName from package.json')

    args = parser.parse_args()

    if not (args.tagName):
        print('tagName must be specified!')
        sys.exit(1)

    update_tag_name(args.tagName)
    print('package.json updated for %s tagName' % args.tagName)
    sys.exit(0)