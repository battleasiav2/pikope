# Same layout as manual Hostinger upload: index.html + assets/ at zip root.
$RepoRoot = Split-Path $PSScriptRoot -Parent
& (Join-Path $PSScriptRoot "sync-landing-to-webroot.ps1") | Out-Null
$out = Join-Path $env:USERPROFILE "Downloads\pikope-landing-deploy.zip"
if (Test-Path $out) { Remove-Item $out -Force }
$items = @(
  (Join-Path $RepoRoot "index.html"),
  (Join-Path $RepoRoot "assets")
)
Compress-Archive -Path $items -DestinationPath $out -CompressionLevel Optimal
Write-Host "Created $out — extract into public_html (same as Git deploy landing files)"
