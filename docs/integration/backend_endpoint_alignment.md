# Backend Endpoint Alignment

Tanggal audit: 2026-06-24

Dokumen ini mencatat kontrak aktual antara Flutter dan backend melalui API Gateway.

| Feature | Flutter Endpoint | Backend Endpoint | Method | Status | Catatan |
|---|---|---|---|---|---|
| Base URL | `ATMA_API_BASE_URL` | `https://api.atma.biz.id` | - | Match | Default app memakai `https://api.atma.biz.id`; `--dart-define=ATMA_API_BASE_URL=...` tetap bisa dipakai untuk override environment. |
| Login | `/auth/login` | `/auth/login` | POST | Match | Response `{token}`. Flutter lanjut memanggil `/auth/me`. |
| Register | `/auth/register` | `/auth/register` | POST | Match | Body `{nama,email,password}`. |
| Logout | `/auth/logout` | `/auth/logout` | POST | Match | Backend menghapus token aktif. |
| Forgot password | `/auth/forgot-password` | `/auth/forgot-password` | POST | Match | Response accepted. |
| Verify reset code | `/auth/verify-reset-code` | `/auth/verify-reset-code` | POST | Match | Response reset session token. |
| Reset password | `/auth/reset-password` | `/auth/reset-password` | POST | Match | Revoke semua token user setelah reset. |
| Get current user | `/auth/me` | `/auth/me` | GET | Match | Wajib Authorization header. |
| Update current user | `/auth/me` | `/auth/me` | PUT | Match | Wajib Authorization header. |
| Notifications | `/notifications` | `/notifications` | GET | Match | Spring Page response. |
| Unread count | `/notifications/unread-count` | `/notifications/unread-count` | GET | Match | Response `{unreadCount}`. |
| Mark read | `/notifications/{id}/read` | `/notifications/{id}/read` | PATCH | Match | Hanya notifikasi milik user. |
| Mark all read | `/notifications/read-all` | `/notifications/read-all` | PATCH | Match | Response `{updatedCount}`. |
| Latest sensor | `/sensor/latest` | `/sensor/latest` | GET | Match | Response normalized by Flutter to `suhu`, `kelembaban`, actuator flags, mode. |
| Sensor history | `/sensor?page=0&size=50&sort=createdAt,desc` | `/sensor` | GET | Match | Spring Page response. |
| First sensor | `/sensor?page=0&size=1&sort=createdAt,asc` | `/sensor` | GET | Match | Dipakai untuk durasi proses. |
| Device status | `/sensor/device/status` | `/sensor/device/status` | GET | Match | Online dihitung dari telemetry terakhir. |
| Actuator status | `/sensor/actuator/status` | `/sensor/actuator/status` | GET | Match | Source of truth sementara dari DB, dikoreksi telemetry berikutnya. |
| Control heater | `/sensor/actuator/heater` | `/sensor/actuator/heater` | POST | Match | Body `{enabled}`. |
| Control fan | `/sensor/actuator/kipas` | `/sensor/actuator/kipas` | POST | Match | Body `{enabled}`. |
| Control exhaust | `/sensor/actuator/exhaust` | `/sensor/actuator/exhaust` | POST | Match | Body `{enabled}`. |
| Manual/auto mode | `/sensor/device/mode` | `/sensor/device/mode` | POST | Match | Body `{mode:"MANUAL"}` atau `{mode:"AUTO"}`. |
| Error response | JSON | JSON | - | Match | Gateway dan service mengembalikan `ErrorResponse` JSON untuk error terkontrol. |

## MQTT Contract

ESP32 memakai public MQTT TLS:

- Host: `mqtt.atma.biz.id`
- Port: `8883`
- Username device: `atma_device`
- Telemetry topic: `atma/device/atma-dryer-001/telemetry`
- Command subscription: `atma/device/atma-dryer-001/command/#`

Backend `sensor_service` memakai private Docker MQTT listener:

- Host: `mosquitto`
- Port: `1883`
- TLS: `false`
- Username service: `sensor_service`

Telemetry payload:

```json
{
  "suhu": 52,
  "kelembaban": 50,
  "heater": 1,
  "kipas": 1,
  "exhaust": false
}
```

Actuator command:

```json
{
  "type": "ACTUATOR_COMMAND",
  "actuator": "heater",
  "enabled": true,
  "timestamp": "2026-06-24T00:00:00"
}
```

Mode command:

```json
{
  "type": "MODE_COMMAND",
  "mode": "AUTO",
  "timestamp": "2026-06-24T00:00:00"
}
```
