#!/bin/bash

# macSCP DMG Creator Script
# This script creates a distributable DMG installer for macSCP

set -e

APP_NAME="macSCP"
VERSION="0.2.3"
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR="build"
DMG_DIR="dmg-staging"
FINAL_DMG="${DMG_NAME}.dmg"

echo "🚀 Building macSCP..."

# Archive the app (Release build)
xcodebuild archive \
    -project macSCP.xcodeproj \
    -scheme macSCP \
    -configuration Release \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM="" \
    | xcpretty || xcodebuild archive \
    -project macSCP.xcodeproj \
    -scheme macSCP \
    -configuration Release \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM=""

echo "✅ Build complete!"

# Export the app
echo "📦 Exporting app..."
xcodebuild -exportArchive \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    -exportPath "${BUILD_DIR}" \
    -exportOptionsPlist exportOptions.plist

# Create DMG staging directory
echo "🎨 Creating DMG staging area..."
rm -rf "${DMG_DIR}"
mkdir -p "${DMG_DIR}"

# Copy app to staging
cp -R "${BUILD_DIR}/${APP_NAME}.app" "${DMG_DIR}/"

# Create Applications symlink
ln -s /Applications "${DMG_DIR}/Applications"

# Create DMG
echo "💿 Creating DMG..."
rm -f "${FINAL_DMG}"
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_DIR}" \
    -ov -format UDZO \
    "${FINAL_DMG}"

echo "✨ DMG created successfully: ${FINAL_DMG}"
echo ""
echo "📍 Location: $(pwd)/${FINAL_DMG}"
echo "📦 Size: $(du -h "${FINAL_DMG}" | cut -f1)"
echo ""
echo "To install: Double-click the DMG and drag ${APP_NAME} to Applications folder"
