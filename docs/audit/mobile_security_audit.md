# Mobile Security Audit

Tanggal audit: 2026-06-17

## Temuan Security

| Risk | Severity | Lokasi | Dampak | Solusi Teknis | Prioritas |
|---|---|---|---|---|---|
| JWT disimpan di `SharedPreferences` | High | `lib/service/api_service.dart`, `main.dart`, `splash_screen.dart` | Token dapat dicuri pada device rooted/backup tertentu | Gunakan `flutter_secure_storage` dengan Android encrypted storage | P1 |
| Cleartext HTTP diizinkan | High | `android/app/src/main/AndroidManifest.xml` | Traffic bisa disadap jika production tetap HTTP | Gunakan HTTPS dan set cleartext false untuk release | P1 |
| Base URL default HTTP emulator | Medium | `ApiService.baseUrl` | Aman untuk dev, tidak cukup untuk production | Override dengan `--dart-define` HTTPS saat demo AWS | P1 |
| Public key EmailJS hardcoded | Medium | `forget_password_screen.dart` | Penyalahgunaan template/email quota | Reset password lewat backend, batasi provider key | P1 |
| Reset password tidak mengubah backend | High | `forget_password_screen.dart` | User mendapat kesan password berubah padahal tidak | Buat endpoint reset password backend | P0 bila fitur ditampilkan saat demo |
| Tidak ada auto logout token expired | Medium | API flow | User stuck pada error 401 | Tambahkan global 401 handler | P1 |
| Release signing memakai debug key | High | `android/app/build.gradle.kts` | APK release tidak production-ready | Buat signingConfig release dari keystore aman | P1 |
| Application ID masih `com.example.atma_app` | Medium | `android/app/build.gradle.kts` | Identitas app belum production | Ganti ke package resmi | P2 |
| Logout backend tidak revoke gateway JWT | Medium | Backend behavior | Token masih valid sampai expiry | Backend blacklist/introspection bila perlu | Backend P1 |

## Status Token

Belum aman untuk production karena masih memakai `SharedPreferences`. Tidak ditemukan penyimpanan password login. Log response login yang sebelumnya ada sudah dihapus dari `ApiService`.

## Prioritas Perbaikan

- P0: Jangan demo fitur lupa password sebagai fitur backend sampai endpoint reset password tersedia.
- P1: Migrasi token ke secure storage, gunakan HTTPS, signing release benar, dan global 401 handler.
- P2: Ganti applicationId dan rapikan flavor/environment.
