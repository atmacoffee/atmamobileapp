# Actuator Control Audit

Tanggal audit: 2026-06-24

## Flow Kontrol Saat Ini

`KontrolScreen` sudah tersambung ke backend melalui `ApiService`.

Endpoint yang dipakai:

| Kebutuhan | Endpoint | Method | Status |
|---|---|---|---|
| Current actuator status | `/sensor/actuator/status` | GET | Tersedia |
| Heater ON/OFF | `/sensor/actuator/heater` | POST | Tersedia |
| Fan/Kipas ON/OFF | `/sensor/actuator/kipas` | POST | Tersedia |
| Exhaust ON/OFF | `/sensor/actuator/exhaust` | POST | Tersedia |
| Manual/automatic mode | `/sensor/device/mode` | POST | Tersedia |

## Request/Response

Command actuator:

```json
{
  "enabled": true
}
```

Mode device:

```json
{
  "mode": "AUTO"
}
```

Backend mengirim MQTT command ke:

- `atma/device/atma-dryer-001/command/actuator`
- `atma/device/atma-dryer-001/command/mode`

## State Handling

- Flutter menonaktifkan tombol saat request sedang dikirim.
- Setelah command sukses, Flutter refresh status aktuator dari backend.
- Jika command gagal, UI menampilkan feedback error.
- Saat mode `AUTO`, kontrol manual dinonaktifkan di UI.

## Catatan Production

Status backend dianggap `COMMAND_SENT` setelah MQTT publish berhasil, bukan setelah ESP32 mengirim ACK eksekusi. Untuk akurasi production yang lebih kuat, tambahkan ack topic dari device, misalnya:

```text
atma/device/atma-dryer-001/ack
```

Tanpa ACK, state akhir tetap akan dikoreksi oleh telemetry berikutnya dari ESP32.
