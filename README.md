# PikoPe — full project (monorepo)

One repository: **Flutter app**, **PHP admin/API**, **pikope.com landing**, and **APK releases**.

| Part | Path | Live URL |
|------|------|----------|
| Backend + admin | `public/`, `src/`, `bin/` | https://adminnew.pikope.com |
| Landing | `site-pikope.com/` | https://pikope.com |
| Android app | `app/` | Play Store / direct APK |
| APK backup | `releases/apk/` | Git history only |

## Deploy

- **Admin/API:** Hostinger Git → `public_html/adminnew` (docroot `.../adminnew/public`)
- **Landing:** GitHub Actions FTP on push — see `deploy/LANDING-AUTO-SETUP.txt`
- **Full checklist:** `deploy/MONOREPO-HOSTINGER.txt`

After push: `php bin/migrate.php` on server when schema changes.

## APK

```powershell
cd app
flutter build apk --release --dart-define-from-file=.env
cd ..
.\scripts\publish-apk.ps1
git add releases/apk && git commit -m "APK 1.0.x" && git push
```

Signing: `app/android/key.properties` (never commit).

## Requirements

PHP 8.1+, MySQL 8+, Flutter 3.12+ for `app/`.
