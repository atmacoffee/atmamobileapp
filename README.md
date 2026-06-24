# ATMA Coffee Dryer - Smart Monitoring & Control App

![Flutter](https://img.shields.io/badge/Flutter-%5E3.9.0-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-Language-0175C2?logo=dart)
![Version](https://img.shields.io/badge/Version-1.0.0%2B1-success)

ATMA Coffee Dryer adalah aplikasi *mobile* berbasis Flutter yang dirancang khusus untuk memantau dan mengontrol proses pengeringan biji kopi secara cerdas (*smart coffee drying*). Aplikasi ini memberikan kemudahan bagi pengguna untuk mengawasi suhu, kelembaban, serta mengendalikan aktuator (pemanas, kipas, dan exhaust) secara *real-time* maupun otomatis.

## 🚀 Fitur Utama

1. **Dashboard Real-Time**: Memantau suhu dan kelembaban ruang pengering secara langsung dengan visualisasi grafik interaktif.
2. **Kendali Jarak Jauh (Remote Control)**: 
   - **Mode Otomatis**: Sistem mengontrol aktuator secara mandiri berdasarkan algoritma cerdas backend.
   - **Mode Manual**: Pengguna memiliki kendali penuh untuk menyalakan atau mematikan *Heater* (Pemanas), *Kipas*, dan *Exhaust*.
3. **Manajemen Sesi & Autentikasi**: Sistem *login* dan registrasi yang aman dengan manajemen token *JWT*.
4. **Notifikasi Sistem**: Peringatan dan informasi penting terkait status pengeringan dan kondisi perangkat (seperti perangkat *offline* atau error).
5. **Estimasi Pengeringan Pintar**: Kalkulasi prediksi sisa waktu pengeringan berdasarkan standar ideal pengeringan kopi (72 jam).

## 🛠️ Analisis Arsitektur & Teknologi

Berdasarkan analisis mendalam terhadap *source code*, proyek ini dibangun dengan standar profesional menggunakan arsitektur yang *scalable* dan terstruktur dengan sangat baik:

### 1. Teknologi (Tech Stack)
- **Framework**: Flutter (Mendukung SDK ^3.9.0)
- **Networking**: Menggunakan paket `http` yang diabstraksi menjadi klien kustom untuk komunikasi RESTful API.
- **Visualisasi Data**: Paket `fl_chart` untuk me-render grafik pemantauan metrik lingkungan yang halus dan dinamis.
- **Penyimpanan Lokal (Storage)**: 
  - `flutter_secure_storage`: Digunakan khusus untuk mengamankan data sensitif seperti *Token Autentikasi*.
  - `shared_preferences`: Untuk menyimpan informasi profil pengguna (seperti nama, email, lokasi, dan jenis kopi).

### 2. Struktur Direktori (Clean Structure)
Aplikasi menerapkan pemisahan *concerns* yang efisien di dalam direktori `lib/`:
- `core/`: Berisi konfigurasi *core* aplikasi (`AppConfig`), penanganan *exception* khusus jaringan (`ApiException`), dan lapisan utilitas penyimpanan.
- `screens/`: Memuat komponen tampilan layar utama seperti `dashboard_screen`, `kontrol_screen`, `notifikasi_screen`, hingga alur autentikasi.
- `service/`: Diwakili oleh `api_service.dart` sebagai lapisan sentral. Tempat berkumpulnya seluruh *endpoint* REST API, injeksi token otomatis (*interceptor pattern*), dan normalisasi tipe data JSON yang masuk (mencegah *NullPointerException*).
- `theme/`: Menyimpan standarisasi desain (warna, jarak, font) agar UI/UX tetap konsisten.
- `widgets/`: Menyediakan *reusable UI components* seperti tombol, kartu, dialog konfirmasi (`AppConfirmationDialog`), hingga *state view* kustom ketika terjadi error atau *loading*.

### 3. Analisis Mekanisme Real-time
Alih-alih membebani server dengan koneksi *WebSocket* permanen, aplikasi ini secara pintar mengimplementasikan **HTTP Polling** melalui blok `Timer.periodic`.
- *Polling* diikat pada visibilitas layar (mengecek variabel `isActive` dan *state* `didUpdateWidget`).
- Ketika pengguna membuka menu "Dashboard" atau "Kontrol", aplikasi akan menarik data terbaru setiap jeda interval tertentu. Ketika layar tertutup, proses latar belakang ini akan langsung dibersihkan (`_timer?.cancel()`), membuat manajemen memori sangat efisien.

### 4. Penanganan Sesi Tingkat Lanjut (Advanced Session Handling)
Keamanan pengguna sangat dijaga melalui mekanisme penanganan *401 Unauthorized* tingkat tinggi:
- Aplikasi mendaftarkan *callback handler* global di `main.dart` melalui `ApiService.registerUnauthorizedHandler()`.
- Jika backend mendeteksi token tidak valid atau kedaluwarsa di *screen* mana pun, API Service akan mencegat (*intercept*) error tersebut, otomatis membersihkan sesi di peranti, memberikan *toast notification*, dan menendang (*redirect*) pengguna kembali ke halaman *Login* dengan mulus menggunakan global `appNavigatorKey`.

## 📦 Instalasi & Konfigurasi

1. Pastikan **Flutter SDK** terinstal dengan benar di komputer Anda (versi 3.9.0 ke atas).
2. *Clone* repositori ini ke lokal Anda.
3. Buka terminal dan unduh semua dependensi proyek:
   ```bash
   flutter pub get
   ```
4. Sesuaikan konfigurasi *Base URL* server Anda di dalam file:
   `lib/core/config/app_config.dart`
5. *Run* aplikasi di emulator (Android/iOS) atau perangkat fisik:
   ```bash
   flutter run
   ```

## 🔒 Praktik Keamanan Terbaik
- **Payload Normalization**: Data yang diterima dari JSON dikonversi dan disanitasi menggunakan metode seperti `_normalizeSensor()` sebelum dilempar ke UI, memastikan nilai metrik aman dari *type-casting errors* (misalnya dari Integer ke Double).
- **Secure Key Chain**: Memastikan enkripsi di tingkat sistem operasi (Keystore Android / Keychain iOS) via paket *secure storage*.

---
**ATMA Coffee Dryer - Elevating Coffee Quality with Smart Technology**
