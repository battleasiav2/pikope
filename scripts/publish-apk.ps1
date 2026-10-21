# Copy Flutter release APK into releases/apk/ with versioned name.
param(
  [string]$ApkPath = "",
)
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent
$pubspec = Join-Path $RepoRoot "app\pubspec.yaml"
if (-not (Test-Path $pubspec)) { throw "app/pubspec.yaml not found under $RepoRoot" }
$line = Get-Content $pubspec | Where-Object { $_ -match '^version:\s*' } | Select-Object -First 1
if ($line -match 'version:\s*([\d.]+)\+(\d+)') {
  $ver = $Matches[1]
  $build = $Matches[2]
} else { throw "Could not parse version from pubspec.yaml" }
$name = "pikope-$ver-build$build.apk"
$destDir = Join-Path $RepoRoot "releases\apk"
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
$dest = Join-Path $destDir $name
if (-not $ApkPath) {
  $ApkPath = Join-Path $RepoRoot "app\build\app\outputs\flutter-apk\app-release.apk"
}
if (-not (Test-Path $ApkPath)) {
  throw "APK not found: $ApkPath`nBuild: cd app && flutter build apk --release --dart-define-from-file=.env"
}
Copy-Item -Force $ApkPath $dest
Write-Host "Published $dest"
Write-Host "Next: git add releases/apk && git commit && git push"
