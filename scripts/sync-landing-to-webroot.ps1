# Copy site-pikope.com → repo web root (same layout as landing deploy zip).
$RepoRoot = Split-Path $PSScriptRoot -Parent
$src = Join-Path $RepoRoot "site-pikope.com"
$index = Join-Path $RepoRoot "index.html"
$assets = Join-Path $RepoRoot "assets"
if (-not (Test-Path (Join-Path $src "index.html"))) { throw "Missing site-pikope.com" }
Copy-Item (Join-Path $src "index.html") $index -Force
if (Test-Path $assets) { Remove-Item $assets -Recurse -Force }
Copy-Item (Join-Path $src "assets") $assets -Recurse -Force
Write-Host "Landing synced to index.html + assets/ (zip layout)"
