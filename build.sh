#!/bin/bash

# Build and package script for System Data Cleaner

APP_NAME="SystemDataCleaner"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}.dmg"

echo "Building ${APP_NAME}..."
xcodebuild clean build -project ${APP_NAME}.xcodeproj -scheme ${APP_NAME} -configuration Release SYMROOT="${BUILD_DIR}"

APP_BUNDLE="${BUILD_DIR}/Release/${APP_NAME}.app"

if [ ! -d "${APP_BUNDLE}" ]; then
    echo "Build failed! App bundle not found."
    exit 1
fi

echo "Creating DMG..."
hdiutil create -volname "${APP_NAME}" -srcfolder "${APP_BUNDLE}" -ov -format UDZO "${DMG_NAME}"

echo "Done! Created ${DMG_NAME}"
