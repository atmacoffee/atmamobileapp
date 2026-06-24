# Sensor History and Chart Audit

Tanggal audit: 2026-06-17

## Flow Histori Data

Setelah perbaikan, histori sensor memakai endpoint kontrak:

```http
GET /sensor?page=0&size=50&sort=createdAt,desc
Authorization: Bearer <jwt>
```

Sebelumnya Flutter memakai `/sensor/riwayat`, tetapi endpoint tersebut tidak ada di backend contract.

## Format Data

Data backend adalah `Page<Sensor>` dengan field utama:

| Field | Type | Catatan |
|---|---|---|
| `id` | number | ID row sensor |
| `suhu` | number | Suhu |
| `kelembaban` | number | Kelembapan |
| `heater` | number | 0/1 |
| `kipas` | number | 0/1 |
| `createdAt` | string | LocalDateTime backend |

## Chart Rendering

- Dashboard memuat maksimal 50 titik suhu.
- Sensor screen menampilkan maksimal 10 titik suhu realtime.
- Tidak ada chart kelembapan terpisah.
- Tidak ada downsampling/agregasi server-side.

## Masalah Performa

| Issue | Risiko |
|---|---|
| Chart data memakai endpoint history umum, bukan endpoint chart/range | Medium |
| Tidak ada pagination UI untuk histori lengkap | Medium |
| Timezone tidak eksplisit karena backend mengirim `LocalDateTime` tanpa offset | Medium |
| Sorting dan reverse data dilakukan di client | Low |

## Endpoint Missing

Backend belum menyediakan:

- `GET /sensor/chart?from=&to=&interval=`
- `GET /sensor/latest`

## Rekomendasi

- Tambahkan endpoint chart dengan range waktu dan limit.
- Gunakan ISO timestamp dengan timezone/offset atau sepakati timezone server.
- Tambahkan layar histori dengan pagination/infinite scroll bila diperlukan.
- Untuk demo, batasi `size` 50 seperti sekarang agar chart ringan.
