# Authentication Audit

Tanggal audit: 2026-06-17

## Flow Login

1. User membuka aplikasi.
2. `main.dart` mengecek token di `SharedPreferences`.
3. Jika tidak ada token, app ke splash lalu login.
4. `LoginScreen` memanggil `ApiService.login(email, password)`.
5. `ApiService` mengirim `POST /auth/login` ke API Gateway.
6. Jika sukses, token disimpan lokal.
7. Setelah perbaikan, app mencoba `GET /auth/me` untuk mengambil profil user.
8. App redirect ke `MainScreen`.

## Endpoint yang Digunakan

| Action | Method | Flutter Endpoint | Backend Contract | Status |
|---|---|---|---|---|
| Register | POST | `/auth/register` | `/auth/register` | Match setelah perbaikan |
| Login | POST | `/auth/login` | `/auth/login` | Match setelah perbaikan |
| Current user | GET | `/auth/me` | `/auth/me` | Ditambahkan setelah perbaikan |
| Logout | POST | `/auth/logout` | `/auth/logout` | Match setelah perbaikan |
| Refresh token | - | Tidak ada | Missing backend endpoint | Not available |

## Request dan Response

Login request:

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

Login success backend:

```json
{
  "token": "jwt"
}
```

Register request:

```json
{
  "nama": "Budi Kopi",
  "email": "budi@atma.com",
  "password": "password123"
}
```

## Token Handling

- Token masih disimpan di `SharedPreferences`.
- Authorization header dikirim sebagai `Bearer <token>` melalui helper `_authHeaders()`.
- Belum ada refresh token.
- Belum ada auto logout global saat menerima HTTP 401.
- Logout memanggil backend lalu `prefs.clear()`.

## Error Handling

- Error JSON `{ "error": "..." }` dan `{ "message": "..." }` dibaca oleh `ApiService`.
- Error plain text dari gateway 401 juga ditampilkan.
- Login/register menampilkan snackbar.

## Masalah yang Ditemukan

| Issue | Risiko | Lokasi |
|---|---|---|
| Token belum memakai secure storage | High | `lib/service/api_service.dart`, `lib/main.dart`, `lib/screens/splash_screen.dart` |
| Response login sebelumnya diasumsikan memiliki `user` | High | Sudah diperbaiki di `ApiService` dan `LoginScreen` |
| Tidak ada auto logout saat token expired | Medium | Global API flow |
| Lupa password tidak terhubung backend | High | `lib/screens/forget_password_screen.dart` |
| Public key EmailJS tertanam di app | Medium | `forget_password_screen.dart` |
| Validasi email belum memakai regex/form validator | Low | Login/register |

## Rekomendasi

- Migrasikan token ke `flutter_secure_storage`.
- Tambahkan wrapper error 401 untuk clear token dan redirect login.
- Buat endpoint backend reset password yang aman; jangan reset password hanya di UI.
- Gunakan `Form` + validator untuk login/register.
- Jangan log token atau response auth sensitif.
