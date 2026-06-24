# Performance and UX Audit

Tanggal audit: 2026-06-17

## Masalah Performa

| Issue | Dampak Demo | Rekomendasi | Prioritas |
|---|---|---|---|
| Dashboard dan sensor sama-sama polling 5 detik di `IndexedStack` | Request ganda ke backend | Pause polling tab nonaktif atau shared polling service | P1 |
| Chart history memuat 50 row setiap masuk dashboard | Masih aman untuk demo, kurang scalable | Endpoint chart/range server-side | P2 |
| Tidak ada debounce refresh manual | Request berulang saat tap cepat | Disable refresh selama request | P2 |
| API parsing langsung di widget | Risiko rebuild/error tersebar | Model typed + repository | P2 |

## Masalah UX

| Issue | Dampak Demo | Rekomendasi | Prioritas |
|---|---|---|---|
| Kontrol aktuator lokal, tidak real | Demo kontrol bisa menyesatkan | Tampilkan status "backend control belum tersedia" atau integrasikan setelah endpoint ada | P0 |
| Sensor screen catch error tanpa pesan | User tidak tahu penyebab gagal | Tambahkan error view + retry | P1 |
| Tidak ada indikator device online aktual | Status "Terhubung" bisa palsu | Integrasikan endpoint device status | P1 |
| Lupa password memberi pesan sukses tanpa backend update | UX menyesatkan | Sembunyikan/disable sampai backend siap | P0/P1 |
| Profil edit hanya lokal | Data tidak sinkron server | Tambahkan endpoint update profile jika diperlukan | P2 |
| Empty state sensor kurang eksplisit | Demo DB kosong terlihat error | Tampilkan "Belum ada data sensor" | P1 |

## Dampak ke Demo

Aplikasi bisa dipakai untuk demo monitoring jika backend gateway, auth, dan sensor history berjalan. Demo kontrol aktuator dan lupa password belum production-valid karena belum ada endpoint backend yang mendukung.

## Rekomendasi Prioritas

- P0: Pastikan narasi demo tidak menyebut kontrol aktuator real sebelum backend command ada.
- P1: Tambahkan secure token, HTTPS URL, error state sensor, device status, dan pause polling tab nonaktif.
- P2: Model typed, repository layer, chart endpoint, pagination histori.
