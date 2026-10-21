# APK backups (Git)

Release APK files are stored here so every build is versioned with the repo.

Naming: `pikope-{version}-build{N}.apk` (matches `app/pubspec.yaml` version).

## Add a new APK after build

From repo root (PowerShell):

```powershell
.\scripts\publish-apk.ps1
```

Or copy manually:

```powershell
Copy-Item path\to\app-release.apk releases\apk\pikope-1.0.2-build4.apk
git add releases/apk/
git commit -m "Release APK 1.0.2+4"
git push origin main
```

Do not commit `android/key.properties` or signing keys.
