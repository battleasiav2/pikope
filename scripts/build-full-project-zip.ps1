# Hostinger manual backup: landing (zip layout) + PHP backend + Flutter app source.
# APK is NOT in this zip — upload in https://adminnew.pikope.com/admin/landing
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent
$out = Join-Path $env:USERPROFILE "Downloads\pikope-full-project.zip"
$stage = Join-Path $env:TEMP "pikope-full-project-stage"

& (Join-Path $PSScriptRoot "sync-landing-to-webroot.ps1") | Out-Null

if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null

$copyDirs = @("public", "src", "bin", "sql", "deploy", "assets", "app", "scripts", "site-pikope.com", "releases")
foreach ($d in $copyDirs) {
  $from = Join-Path $RepoRoot $d
  if (Test-Path $from) {
    robocopy $from (Join-Path $stage $d) /MIR /XD build .dart_tool .gradle node_modules /XF .env .env.hostinger key.properties upload-keystore.jks *.apk /NFL /NDL /NJH /NJS | Out-Null
  }
}

$copyFiles = @("index.html", "README.md", ".htaccess", ".env.example", ".gitignore")
foreach ($f in $copyFiles) {
  $from = Join-Path $RepoRoot $f
  if (Test-Path $from) { Copy-Item $from (Join-Path $stage $f) -Force }
}

$readme = @"
PikoPe full project (Hostinger / Git backup)
============================================

LANDING (pikope.com) — same files as pikope-server-deploy.zip
  public_html: index.html + assets/  (styles.css, hero-bg.jpg, app_icon.jpg)
  Or use entire archive as public_html after Git deploy.

ADMIN + API (adminnew.pikope.com)
  Docroot: public_html/public
  Copy .env.example to .env (never commit .env)
  php bin/migrate.php

APK FOR LANDING DOWNLOAD
  NOT in this ZIP. Admin only:
  https://adminnew.pikope.com/admin/landing  → Upload APK → Save
  Landing loads URL from GET /landing/public

FLUTTER APP
  Folder: app/  — build locally, optional: scripts/publish-apk.ps1 → Git releases/apk/

GitHub: https://github.com/battleasiav2/pikope
"@
Set-Content -Path (Join-Path $stage "FULL-PROJECT-README.txt") -Value $readme -Encoding UTF8

if (Test-Path $out) { Remove-Item $out -Force }
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $out -CompressionLevel Optimal
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Created $out"
