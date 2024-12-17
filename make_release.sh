#!/bin/sh -e

xcodebuild -version

PROJECT_DIR="$(pwd)"
for arch in "arm64" "x86_64"; do
    xcodebuild -scheme XDevMan -project XDevMan.xcodeproj -configuration Release -derivedDataPath ./.build -arch $arch build | (xcbeautify || xcpretty || tee)
    cd ./.build/Build/Products/Release/
    zip -rq XDevMan.app.$arch.zip XDevMan.app
    cd "$PROJECT_DIR"
    mv ./.build/Build/Products/Release/XDevMan.app.$arch.zip ./.build/
done