# Preview landing from extracted pikope-full-project.zip (or repo root).
param(
  [string]$Root = "E:\dulex\DuelX-source-2026-10-17\pikope-local-preview",
  [int]$Port = 8765
)
if (-not (Test-Path (Join-Path $Root "index.html"))) {
  $zip = Join-Path $env:USERPROFILE "Downloads\pikope-full-project.zip"
  if (-not (Test-Path $zip)) { throw "Extract pikope-full-project.zip or set -Root" }
  if (Test-Path $Root) { Remove-Item $Root -Recurse -Force }
  Expand-Archive $zip $Root -Force
}
Set-Location $Root
Write-Host "Landing: http://127.0.0.1:$Port/  (APK from admin API; Ctrl+C to stop)"
py -m http.server $Port
