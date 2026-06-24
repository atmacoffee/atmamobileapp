# Flutter Fix Backlog

Tanggal audit: 2026-06-17

| Priority | Area | Issue | Risk | Recommended Fix | Estimated Complexity | Status |
|---|---|---|---|---|---|---|
| P0 | Actuator | Kontrol pemanas/kipas hanya lokal | Demo kontrol tidak valid | Tambahkan backend command endpoint + integrasi Flutter | High | Done |
| P0 | Auth | Lupa password tidak mengubah backend | User tertipu password sudah berubah | Buat reset password backend atau sembunyikan fitur | Medium | Done, disabled for demo |
| P1 | Security | Token di `SharedPreferences` | Token theft risk | Migrasi ke `flutter_secure_storage` | Medium | Done |
| P1 | Config | Production base URL belum final | App tidak konek saat demo AWS | Build dengan `--dart-define=ATMA_API_BASE_URL=...` | Low | Done |
| P1 | Android | Release signing debug key | APK tidak production-ready | Setup keystore release | Medium | Open |
| P1 | Android | Cleartext traffic true | Token bisa disadap bila HTTP | HTTPS + cleartext false untuk release | Medium | Open |
| P1 | Networking | Tidak ada global 401 handler | App stuck saat token expired | Clear token + redirect login saat 401 | Medium | Done |
| P1 | Sensor | Device status belum real | UI "Terhubung" bisa palsu | Tambahkan endpoint `/sensor/device/status` | Medium | Done |
| P1 | Performance | Polling paralel dashboard/sensor | Beban request ganda | Pause polling tab nonaktif/shared service | Medium | Open |
| P1 | UX | Sensor screen tidak tampilkan error detail | Sulit debug demo | Tambahkan error state + retry | Low | Open |
| P2 | Architecture | Model masih Map dynamic | Runtime error saat schema berubah | Tambahkan typed model `Sensor`, `User`, `PagedResponse` | Medium | Open |
| P2 | History | Belum ada pagination UI | Histori besar tidak nyaman | Infinite scroll atau filter tanggal | Medium | Open |
| P2 | Chart | Belum ada endpoint chart/range | Client harus olah data mentah | Tambahkan `/sensor/chart` | Medium | Backend missing |
| P2 | Profile | Edit profil hanya lokal | Data user tidak sinkron | Tambahkan endpoint update profile | Medium | Backend missing |
| P2 | Android | Application ID masih example | Identitas belum final | Ganti package resmi | Low | Open |
| P3 | Architecture | Belum ada repository/state layer | Sulit scale fitur | Tambah struktur feature/data/state bertahap | High | Open |
