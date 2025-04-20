#!/bin/bash
# build script for mac apps
# in this script we assume gnu cli utils

CODESIGNING=DEVELOPMENT_TEAM=AWMJ8H4G7B
ARCHIVE_DIR=archive/Applications
PNAME=darwin-apps

set -euo pipefail
set -x

cd "$(dirname "$0")"
mkdir -p "$ARCHIVE_DIR"

(
  cd ./Ice
  xcodebuild -scheme Ice -configuration Release \
    -derivedDataPath ./DerivedData \
    "$CODESIGNING"
  /bin/cp -acf ./DerivedData/Build/Products/Release/Ice.app ../"$ARCHIVE_DIR"
)

(
  cd ./AltTab
  xcodebuild -scheme Release -workspace alt-tab-macos.xcworkspace \
    -derivedDataPath ./DerivedData \
    CODE_SIGN_IDENTITY="Apple Development: bryanlai@foxmail.com (VY3W9R894Q)" \
    MACOSX_DEPLOYMENT_TARGET=10.13
  /bin/cp -acf ./DerivedData/Build/Products/Release/AltTab.app ../"$ARCHIVE_DIR"
)

store_path=$(nix store add --name "$PNAME" ./archive)

# only update the store path .txt by hand or when necessary
if [[ "$USER" == bryan ]]; then
  echo "$store_path"  > "$PNAME.txt"
elif ! git ls-files --error-unmatch "$PNAME.txt"; then
  echo "$store_path"  > "$PNAME.txt"
  git add "$PNAME.txt"
fi

cachix push chezbryan "$store_path"
echo "$store_path"
