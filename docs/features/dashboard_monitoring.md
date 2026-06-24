# Dashboard Monitoring Audit

Tanggal audit: 2026-06-17

## Flow Data Dashboard

Dashboard membaca data dari `ApiService.getSensor()`. Karena backend belum memiliki `/sensor/latest`, setelah perbaikan Flutter mengambil data terbaru melalui:

```http
GET /sensor?page=0&size=1&sort=createdAt,desc
Authorization: Bearer <jwt>
```

Chart awal membaca:

```http
GET /sensor?page=0&size=50&sort=createdAt,desc
```

## Model Data

Backend mengirim `Page<Sensor>`:

```json
{
  "content": [
    {
      "id": 1,
      "suhu": 63.0,
      "kelembaban": 77.0,
      "heater": 0,
      "kipas": 1,
      "createdAt": "2026-05-10T14:21:20"
    }
  ]
}
```

`ApiService` menormalisasi `createdAt` dan `created_at` agar UI lama tetap berjalan.

## Refresh Strategy

| Screen | Strategy | Interval |
|---|---|---|
| Dashboard | `Timer.periodic` | 5 detik |
| Sensor | `Timer.periodic` | 5 detik |

Tidak ada MQTT/WebSocket di Flutter. Karena `MainScreen` memakai `IndexedStack`, dashboard dan sensor bisa tetap hidup dan polling walau tab tidak aktif.

## Error Handling

- Dashboard memiliki loading state dan error text.
- Sensor screen belum menampilkan pesan error detail; catch hanya mematikan loading.
- Empty state sensor hanya muncul sebagai exception `Data sensor kosong`.

## Masalah yang Ditemukan

| Issue | Risiko | Status |
|---|---|---|
| Backend belum punya `/sensor/latest` | Medium | Diakali dengan page size 1 |
| Dua layar polling paralel | Medium | Perlu pause tab nonaktif |
| Tidak ada indikator status device aktual | Medium | Backend endpoint missing |
| Tidak ada debounce manual refresh | Low | Risiko request berulang |
| Dashboard memakai durasi dari timestamp data sensor, bukan batch pengeringan | Medium | Bisa menampilkan estimasi tidak akurat |

## Rekomendasi

- Tambahkan backend `GET /sensor/latest`.
- Tambahkan status koneksi device `GET /sensor/device/status`.
- Pause polling saat tab tidak aktif atau sentralisasi polling di state layer.
- Gunakan interval 5-10 detik untuk demo; WebSocket/MQTT bridge bisa dipertimbangkan untuk realtime production.
- Tambahkan empty state yang eksplisit bila belum ada data sensor.
