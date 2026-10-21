#!/usr/bin/env bash
# Run on Hostinger via SSH when Git deploy is enabled (Business+), or after manual upload.
# Usage: cd ~/public_html/pikope && bash deploy/hostinger-pull.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -d .git ]]; then
  git fetch origin main
  git reset --hard origin/main
else
  echo "No .git here — use GitHub Actions FTP or upload ZIP instead."
  exit 1
fi

php bin/migrate.php
php bin/doctor.php || true

echo "Backend updated at $ROOT"
echo "Landing (pikope.com): sync site-pikope.com/ to main domain public_html (see HOSTINGER-GIT-DEPLOY.txt)."
