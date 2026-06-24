# Networking and API Audit

Tanggal audit: 2026-06-17

## Struktur API Client Saat Ini

API client berada di `lib/service/api_service.dart`.

Setelah perbaikan:

- Base URL memakai `String.fromEnvironment('ATMA_API_BASE_URL')`.
- Default emulator Android: `http://10.0.2.2:8085`.
- Semua auth/sensor call lewat API Gateway.
- Authorization header dibuat terpusat.
- Timeout 8 detik diterapkan.
- Response sensor Spring Page dinormalisasi.
- Error JSON dan plain text ditangani.

## Masalah

| Masalah | Risiko | Lokasi |
|---|---|---|
| Masih memakai package `http` tanpa interceptor otomatis | Medium | `ApiService` |
| Token disimpan di `SharedPreferences` | High | `ApiService`, `main.dart`, `splash_screen.dart` |
| Tidak ada global handling 401 | Medium | Semua API call |
| Tidak ada retry/backoff | Low | Semua API call |
| API model masih `Map<String,dynamic>` | Medium | Dashboard/sensor |
| Tidak ada environment file/flavor | Medium | Build config |
| `usesCleartextTraffic=true` | High untuk production | AndroidManifest |
| Lupa password memakai API EmailJS langsung dari widget | Medium | `forget_password_screen.dart` |

## Risiko

- Production demo bisa gagal bila base URL tidak di-set ke HTTPS AWS.
- Token lebih mudah diambil dari storage lokal dibanding secure storage.
- UI rawan runtime error bila shape JSON berubah karena tidak ada model typed.
- Polling paralel bisa membebani gateway saat user membuka banyak device.

## Rekomendasi Perbaikan

1. Tambahkan `flutter_secure_storage` untuk token.
2. Bungkus semua API call dengan response typed dan exception custom.
3. Tambahkan global 401 handler untuk clear token dan redirect login.
4. Tambahkan flavor atau dokumentasi run command:

```bash
flutter run --dart-define=ATMA_API_BASE_URL=https://api.atma.biz.id
```

5. Matikan cleartext traffic untuk release production.
6. Pindahkan reset password ke backend.

## Contoh Struktur API Client Disarankan

```text
lib/
├── core/
│   ├── config/api_config.dart
│   ├── network/api_client.dart
│   └── storage/token_storage.dart
├── features/
│   ├── auth/data/auth_api.dart
│   ├── sensor/data/sensor_api.dart
│   └── actuator/data/actuator_api.dart
└── models/
    ├── user.dart
    ├── sensor.dart
    └── paged_response.dart
```
