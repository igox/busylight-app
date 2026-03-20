$buildType = if ($args[0]) { $args[0] } else { "debug" }
$apkDir = "..\build\app\outputs\flutter-apk"
$baseName = "org.igox.apps.android.busylight-buddy"

flutter build apk --$buildType

# Rename APK
$oldApk = "$apkDir\app-$buildType.apk"
$newApk = "$apkDir\$baseName-$buildType.apk"
if (Test-Path $oldApk) {
    if (Test-Path $newApk) { Remove-Item $newApk -Force }
    Rename-Item -Path $oldApk -NewName "$baseName-$buildType.apk"
    Write-Host "APK renamed to: $baseName-$buildType.apk"
}

# Rename SHA1 (if exists)
$oldSha1 = "$apkDir\app-$buildType.apk.sha1"
$newSha1 = "$apkDir\$baseName-$buildType.apk.sha1"
if (Test-Path $oldSha1) {
    if (Test-Path $newSha1) { Remove-Item $newSha1 -Force }
    Rename-Item -Path $oldSha1 -NewName "$baseName-$buildType.apk.sha1"
    Write-Host "SHA1 renamed to: $baseName-$buildType.apk.sha1"
}