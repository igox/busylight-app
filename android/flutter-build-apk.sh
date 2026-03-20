#!/bin/bash
BUILD_TYPE=${1:-debug}
APK_DIR="../build/app/outputs/flutter-apk"
BASE_NAME="org.igox.apps.android.busylight-buddy"

flutter build apk --$BUILD_TYPE

# Rename APK
OLD_APK="$APK_DIR/app-$BUILD_TYPE.apk"
NEW_APK="$APK_DIR/$BASE_NAME-$BUILD_TYPE.apk"
if [ -f "$OLD_APK" ]; then
    [ -f "$NEW_APK" ] && rm -f "$NEW_APK"
    mv "$OLD_APK" "$NEW_APK"
    echo "APK renamed to: $BASE_NAME-$BUILD_TYPE.apk"
fi

# Rename SHA1 (if exists)
OLD_SHA1="$APK_DIR/app-$BUILD_TYPE.apk.sha1"
NEW_SHA1="$APK_DIR/$BASE_NAME-$BUILD_TYPE.apk.sha1"
if [ -f "$OLD_SHA1" ]; then
    [ -f "$NEW_SHA1" ] && rm -f "$NEW_SHA1"
    mv "$OLD_SHA1" "$NEW_SHA1"
    echo "SHA1 renamed to: $BASE_NAME-$BUILD_TYPE.apk.sha1"
fi