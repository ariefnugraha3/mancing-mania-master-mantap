# Laporan Milestone 10 — Balance, Full QA, Release Candidate

Format mengikuti GDD Section 191.15.

## Ringkasan

| | |
|---|---|
| Milestone | 10 — Balance, Full QA, Release Candidate & Gold Master |
| Branch | `milestone/10-release-candidate`, dari `milestone/09-final-polish` (commit lokal, belum di-merge) |
| Tag | belum; `v1.0.0-rc.1` setelah merge |
| Versi project | `1.0.0-rc.1` (Android versionCode 9901) |
| Status rilis | **V1.0 RELEASE CANDIDATE — HUMAN PLAYTEST PENDING** |
| Save schema berubah | tidak |
| Penyimpangan GDD | tidak ada. Keputusan D-103 sampai D-108 |

## Exit gate

| Syarat (GDD Section 181, Milestone 10) | Hasil | Bukti |
|---|---|---|
| All P0 pass | lulus untuk yang otomatis | 265 test otomatis lulus; P0 manual (Android, playtest) belum |
| Zero known P1 core-loop defect | **belum** | KI-001 ekonomi terlalu cepat, KI-002 tinju JAB terus-menerus; keduanya butuh revisi angka GDD oleh pemilik (`docs/known_issues.md`) |
| Export smoke pass | Web lulus, Android belum | Web: export, ZIP itch.io, Chromium smoke (menu → New Game → prolog, tanpa exception). Android: preset siap, build butuh SDK/template/keystore pemilik |
| Definition of Done Section 182 + Gate 191.17 | belum | human playtest (Section 192), Android, data publisher |

Section 192.1 melarang status melewati "HUMAN PLAYTEST PENDING" tanpa playtest manusia sungguhan, jadi Gold Master (Section 194) belum bisa dimulai.

## Yang dikerjakan

- **Simulasi Section 179** (`tools/sim/`): distribusi encounter, sampah, dan Wheel lulus semua toleransi; model ekonomi menunjukkan hutang lunas ~1,8 jam untuk pemain rata-rata (target 5–8 jam). Usulan tuning beserta hasil modelnya di `docs/balance_report.md`; angka tidak diubah (D-104).
- **Export**: preset Web dan Android, build Web 1.0.0-rc.1, ZIP itch.io, smoke test browser headless.
- **Privasi dan lisensi**: layar PRIVACY AND LICENSES di game, `PRIVACY_POLICY.md`, `release/privacy_policy.html`, `LICENSES.md`, peringatan storage di Web, test bahwa kode runtime tidak membuka jaringan.
- **Store**: store art dari scene asli, teks listing, laporan kepatuhan (target API 36 dicek ulang 14 November 2026), draf Data Safety dan jawaban rating konten.
- **Rilis**: validator rilis (gagal sampai data publisher diisi), manifest SHA-256, checklist Section 195 dengan status per butir, known issues, protokol dan formulir playtest.

## File

Ditambahkan: `export_presets.cfg`, `tools/sim/balance_sim.gd`, `tools/sim/balance_model.gd`, `tools/generators/store_art_generator.gd`, `tools/release/release_tool.gd`, `scripts/ui/privacy_overlay.gd`, `tests/suites/test_release.gd`, `README_BUILD.md`, `PRIVACY_POLICY.md`, `LICENSES.md`, `release/privacy_policy.html`, `release/publisher_metadata.example.json`, `release/build_manifest.json`, `docs/balance_report.md`, `docs/store_compliance_report.md`, `docs/known_issues.md`, `docs/playtest_report.md`, `docs/release_checklist_v1.0.md`.

Diubah: `settings_overlay.gd`, `ui_text.tres`, `.gitignore`, `tests/run_all.gd`, `project.godot`, dokumen.

## Artefak (tidak di-commit, ada di `build/`)

| Artefak | Ukuran |
|---|---|
| `build/web/` (index.html, .js, .wasm, .pck, ikon) | 43,6 MB |
| `build/itch/mancing-mania-gelut-edition-web-1.0.0-rc.1.zip` | 11,2 MB |
| `build/store/google_play/` (ikon, ikon adaptive, feature graphic, 5 screenshot) | — |

Checksum semuanya di `release/build_manifest.json`.

## Test

`godot --headless --path . --script res://tests/run_all.gd` — exit code 0, 403 detik, **265 lulus, 0 gagal**, tanpa script error. Suite baru `release` (5 test).

Simulasi: `tools/sim/balance_sim.gd --runs=10000` selesai dalam 193 detik; usulan ×0,22 dan ×0,25 dengan 2.000 run.

Validator: `tools/release/release_tool.gd --validate` gagal (sesuai rancangan) dengan lima alasan milik pemilik: `release/publisher_metadata.json` belum ada, placeholder email di tiga tempat, AAB Android belum ada.

## Pemeriksaan manual

- Build Web di Chrome headless (WebGL 2 lewat SwiftShader): Main Menu, NEW GAME, prolog dengan ponsel di tangan Darto. Console hanya berisi tiga baris info Godot.
- Store art diperiksa satu per satu: danau, tinju di tengah ronde, Market dengan Bu Yati, joget dengan combo 16, Fish Book; feature graphic judul di atas danau.

Belum: Firefox, Safari, perangkat Android, playtest manusia.

## Masalah yang diketahui

Lihat `docs/known_issues.md`: dua P1 balance menunggu pemilik, satu P2 balance, beberapa P2/P3 performa dan presentasi.

## Tugas pemilik sebelum rilis publik

1. Putuskan balance: KI-001 (harga ikan), KI-002 (tinju), KI-003 (panco); catat di GDD.
2. Isi `release/publisher_metadata.json` dan email dukungan di kebijakan privasi (tiga tempat); host kebijakan privasi di URL HTTPS.
3. Siapkan Android SDK, JDK 17+, template build, dan keystore rilis; export AAB.
4. Jalankan playtest Section 192 (12 peserta) dengan formulir di `docs/playtest_report.md`.
5. Uji di Firefox, Safari, dan perangkat Android fisik; ambil ulang screenshot toko di perangkat 1080×1920.
6. Merge branch milestone ke `main` dan buat tag.

## Penyimpangan GDD

Tidak ada.
