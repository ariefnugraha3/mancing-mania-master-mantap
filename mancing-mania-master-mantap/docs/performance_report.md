# Laporan Performa — Baseline Milestone 9

Format mengikuti GDD Section 190.17. Ini **baseline di mesin pengembang**, bukan pengukuran pada perangkat referensi Section 190.1 (Web Medium, Android Low/Mid). Pengukuran di perangkat referensi adalah bagian dari Milestone 10 dan membutuhkan perangkat fisik.

## Cara mengukur

```text
godot --path . --resolution 1280x720 --script res://tools/perf/perf_probe.gd -- --out=<file.json>
```

Probe membuka setiap scene lewat SceneRouter, menunggu 2,5 detik, lalu mengambil sampel 4 detik. Draw call dan primitif adalah nilai maksimum per frame selama sampel; memori dari monitor Godot (`MEMORY_STATIC`, `RENDER_VIDEO_MEM_USED`). Waktu transisi diukur dari permintaan rute sampai `transition_finished`, termasuk fade 0,42 detik.

## Lingkungan

| | |
|---|---|
| Engine | 4.7.2-stable (official) |
| Renderer | gl_compatibility (Compatibility) |
| GPU | NVIDIA GeForce RTX 3050 Laptop GPU |
| Jendela | 1280×720, preset MEDIUM kecuali disebut lain |
| Build | debug, dijalankan dari project (bukan export) |

## Hasil per scene

| Scene | FPS rata-rata | Frame terburuk (ms) | Draw call maks / anggaran 190.6 | Primitif maks | Memori statis (MB) | Memori video (MB) | Transisi (dtk) |
|---|---|---|---|---|---|---|---|
| Danau (LOW) | 413 | 4.1 | 33 / 220 | 23.4k | 86 | 35 | 2.24 |
| Danau (MEDIUM) | 409 | 4.4 | 42 / 220 | 33.4k | 86 | 40 | 0.83 |
| Danau (HIGH) | 398 | 4.7 | 42 / 220 | 33.4k | 86 | 54 | 0.85 |
| Main Menu | 428 | 4.4 | 42 / 220 | 34.4k | 88 | 41 | 1.11 |
| Market | 368 | 4.7 | 82 / 180 | 19.6k | 92 | 41 | 1.82 |
| Tinju | 384 | 63.1 | 59 / 160 | 14.4k | 93 | 45 | 1.57 |
| Panco | 358 | 58.3 | 56 / 150 | 11.2k | 95 | 45 | 1.31 |
| Joget | 254 | 6.4 | 80 / 180 | 11.7k | 102 | 44 | 1.21 |
| Suwit | 332 | 5.1 | 69 / 140 | 13.7k | 103 | 45 | 1.13 |
| Wheel | 364 | 51.6 | 91 / 300 | 14.3k | 104 | 46 | 0.79 |
| Result | 553 | 3.3 | 35 / 300 | 32.8k | 100 | 47 | 1.00 |
| Story: rumah | 599 | 2.9 | 29 / 160 | 7.4k | 100 | 46 | 0.95 |
| Story: keluarga di danau | 519 | 4.2 | 44 / 220 | 38.4k | 101 | 48 | 1.10 |
| Credits | 640 | 2.9 | 29 / 300 | 29.4k | 101 | 48 | 0.83 |

Semua scene berada jauh di bawah anggaran draw call Section 190.6 (paling tinggi Wheel, 91 dari 300) dan anggaran segitiga Section 190.5 (paling tinggi 38k primitif; danau dianjurkan 120k–220k). Memori statis ~86–104 MB, jauh di bawah anggaran Web 350 MB (Section 190.4). Transisi hangat berada di bawah target Section 190.3. Pembukaan pertama (cold) Market 1,82 dtk dan tinju 1,57 dtk sedikit melewati target 1,5 dtk karena scene dan aset dimuat pertama kali; kunjungan berikutnya ~0,9 dtk (uji kebocoran di bawah).

## Uji kebocoran (Section 190.4)

20 kali bolak-balik Danau ↔ Market setelah scene stabil:

| | Sebelum | Sesudah |
|---|---|---|
| Memori statis | 105.47 MB | 105.47 MB |
| Jumlah object | 2756 | 2757 |

Transisi Danau ↔ Market rata-rata 0.86 dtk, paling lama 1.02 dtk (target ≤ 1,5 dtk). Tidak ada kebocoran yang terukur.

## Temuan

- P2: satu frame lambat setelah masuk tinju (63 ms), panco (58 ms), dan Wheel (52 ms), terjadi sekali setelah scene dibuka (kompilasi shader/material pertama kali dan sintesis suara pertama). Di bawah batas hitch berulang 100 ms Section 190.2, tetapi melanggar semangat Section 190.15 pada perangkat lambat. Kandidat perbaikan: memanaskan material duel saat Wheel berputar.
- Preset LOW menurunkan primitif danau dari 33.4k ke 23.4k dan draw call dari 42 ke 33. HIGH menambah memori video (MSAA) dari 40 ke 54 MB.
- Saat probe dijalankan tanpa Boot, scene joget menemukan audio belum disiapkan; sekarang scene itu menyiapkannya sendiri.

## Belum diukur

- Perangkat referensi Web Medium dan Android Low/Mid (Section 190.1), sesi 20 menit (Section 190.16), suhu perangkat, ukuran paket (Section 190.12–190.13; lihat laporan build Milestone 10), CPU audio prosedural per perangkat (Section 190.10).
