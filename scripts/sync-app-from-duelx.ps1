# Sync Flutter tree from local duelx workspace into monorepo app/
param(
  [string]$DuelxRoot = "E:\dulex\DuelX-source-2026-10-17\duelx",
  [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent)
)
$dst = Join-Path $RepoRoot "app"
if (-not (Test-Path (Join-Path $DuelxRoot "pubspec.yaml"))) {
  throw "duelx not found at $DuelxRoot"
}
robocopy $DuelxRoot $dst /MIR /XD .git build .dart_tool android\.gradle backend site-pikope.com /XF .env android\key.properties /NFL /NDL /NJH /NJS
if ($LASTEXITCODE -ge 8) { exit $LASTEXITCODE }
Write-Host "Synced duelx -> app/"
exit 0
