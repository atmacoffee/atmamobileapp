# Android Build Audit

Tanggal audit: 2026-06-17

## Status Build Android

| Item | Status |
|---|---|
| Build tool local | `flutter` tidak tersedia di PATH sesi audit |
| `flutter analyze` | Tidak dapat dijalankan |
| `flutter test` | Tidak dapat dijalankan |
| `flutter build apk --debug` | Tidak dapat dijalankan |
| Gradle Android plugin | `8.9.1` |
| Kotlin plugin | `2.1.0` |
| compileSdkVersion | `flutter.compileSdkVersion` |
| minSdkVersion | `flutter.minSdkVersion` |
| targetSdkVersion | `flutter.targetSdkVersion` |
| applicationId | `com.example.atma_app` |
| Internet permission | Ada |
| Cleartext traffic | `android:usesCleartextTraffic="true"` |
| Release signing | Debug signing config |

## Masalah Konfigurasi

| Issue | Risiko | Rekomendasi |
|---|---|---|
| `flutter`/`dart` tidak ada di PATH Linux audit | Build belum terverifikasi | Jalankan di mesin dengan Flutter SDK valid |
| `android/local.properties` berisi path Windows | Build Linux kemungkinan gagal | Regenerate `local.properties` lokal atau jangan commit file mesin |
| Application ID default example | Tidak production-ready | Ganti ke domain resmi |
| Release signing pakai debug key | Tidak layak release | Buat keystore release dan env secret |
| Cleartext traffic true | Tidak aman production | Gunakan network security config per environment |

## Risiko Saat Demo

- APK tidak bisa dibuat dari environment ini tanpa Flutter SDK.
- Jika AWS memakai HTTPS, app harus dijalankan/build dengan `ATMA_API_BASE_URL` yang benar.
- Jika backend masih HTTP public, traffic token dapat disadap di jaringan tidak aman.

## Rekomendasi

1. Jalankan:

```bash
flutter analyze
flutter test
flutter build apk --debug --dart-define=ATMA_API_BASE_URL=http://<gateway-host>:8085
```

2. Untuk production:

```bash
flutter build apk --release --dart-define=ATMA_API_BASE_URL=https://<gateway-domain>
```

3. Siapkan release signing config dan matikan cleartext untuk release.
