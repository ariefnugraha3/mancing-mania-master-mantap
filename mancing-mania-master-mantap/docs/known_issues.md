# Known Issues — 1.0.0-rc.1

Format Section 193.12. Severity Section 193.1: BLOCKER, P0, P1, P2, P3.

## Menunggu keputusan pemilik

| ID | Severity | Dampak ke pemain | Workaround | Status |
|---|---|---|---|---|
| KI-001 | P1 (core balance) | Ekonomi terlalu cepat: model Section 179 memperkirakan hutang lunas ~1,8 jam untuk pemain rata-rata, target GDD 5–8 jam. Cerita terasa singkat. | — | Usulan di `docs/balance_report.md` (harga lima ikan biasa ×0,22, Arowana tetap). Butuh revisi GDD dan data playtest. |
| KI-002 | P1 (core balance) | Tinju: empat ikan pertama bisa dikalahkan hanya dengan menekan JAB terus-menerus (D-058). Bertentangan dengan niat Section 41. | — | Tiga opsi di `docs/balance_report.md`. Butuh revisi GDD. |
| KI-003 | P2 | Panco: istirahat tidak pernah lebih menguntungkan daripada terus menekan (D-068); petunjuk "stop briefly to recover" tidak berguna secara angka. | Hold Assist tersedia. | Opsi di `docs/balance_report.md`. |

Section 193.13: P1 core-flow harus nol atau diberi waiver eksplisit oleh pemilik sebelum Gold Master.

## Diketahui, tidak memblokir

| ID | Severity | Dampak ke pemain | Workaround | Status |
|---|---|---|---|---|
| KI-004 | P2 | Satu frame 50–63 ms saat pertama masuk tinju, panco, dan Wheel (kompilasi material pertama). | — | Deferred; kandidat: memanaskan material duel saat Wheel berputar. |
| KI-005 | P2 | Transisi pertama ke Market 1,8 dtk (target 1,5); berikutnya 0,9 dtk. | — | Deferred. |
| KI-006 | P2 | Teks yang digambar langsung (lajur joget, Wheel) tidak ikut Text Scale. | Lajur dan Wheel tetap memakai bentuk dan posisi. | Deferred. |
| KI-007 | P2 | Rhythm offset: setting visual offset belum diuji manusia di perangkat dengan latensi tinggi. | Wizard kalibrasi. | Butuh playtest. |
| KI-008 | P3 | Screenshot toko portrait dirender 590×1049 lalu diperbesar ke 1080×1920. | Ambil ulang di perangkat 1080×1920. | Tugas rilis. |
| KI-009 | P3 | Gerak khas spesies ikan masih terbatas pada tempo, lompatan, dan goyangan. | — | Deferred. |

## Belum diverifikasi (bukan bug yang diketahui)

- Android: belum ada build (butuh SDK di Editor Settings, template build, keystore pemilik); belum diuji di perangkat fisik, termasuk tombol/gesture back dan suspend.
- Web: belum diuji di Firefox dan Safari; fokus/resume tab hanya diuji otomatis.
- Belum ada playtest manusia (Section 192).
