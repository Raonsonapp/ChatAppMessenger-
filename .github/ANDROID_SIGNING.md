# Android APK updates without uninstalling

Android can install a new APK over an existing ChatApp installation only when all
of the following remain true:

- `applicationId` stays `com.example.chatapp`.
- The new APK has a higher Android `versionCode`.
- Every release APK is signed with the same private signing key.

The build workflow now increases `versionCode` automatically and requires a
stable release keystore. Do not change the application ID after users install
the app.

## Create a permanent release keystore (one time)

Run this on a trusted computer with Java's `keytool` installed:

```bash
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -alias chatapp-upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Choose strong passwords and store the keystore and passwords in a safe backup.
**Never commit the keystore or passwords to the repository.** If this key is
lost, future APKs signed with a different key cannot update installations signed
with this key.

Encode the keystore as one Base64 line:

- Linux: `base64 -w 0 upload-keystore.jks`
- macOS: `base64 < upload-keystore.jks | tr -d '\\n'`

Copy the full Base64 output, then open the GitHub repository's
**Settings → Secrets and variables → Actions** and add these repository secrets:

| Secret name | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | The full one-line Base64 output |
| `ANDROID_KEYSTORE_PASSWORD` | The keystore password |
| `ANDROID_KEY_ALIAS` | `chatapp-upload` (or the alias you selected) |
| `ANDROID_KEY_PASSWORD` | The key password |

After all four secrets exist, rerun the **Build** workflow. It will create an
APK signed with this permanent key and with an increasing Android version code.

## Important first-update note

If the currently installed ChatApp was signed with a different key (for example,
a temporary GitHub Actions debug key), Android will reject the first APK signed
with the permanent key. In that case, a one-time uninstall/reinstall is
unavoidable unless the original signing key is recovered. After the stable-key
version is installed, future releases signed with the same key and higher
version codes install over it without deleting the app or its local data.

The keystore is a signing identity, not a password reset mechanism. Keep a
secure offline backup and never upload it as a public artifact.
