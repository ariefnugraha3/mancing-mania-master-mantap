# Release Checklist v1.0 — status di 1.0.0-rc.1

Salinan GDD Section 195. `[x]` = diverifikasi untuk build `1.0.0-rc.1` pada 14 November 2026 (verifier: pengembang/AI, otomatis bila disebut test). `[ ]` = belum; alasannya ditulis. **[CRITICAL]** memblokir Gold Master.

## 195.1 Source & repository

- [x] **[CRITICAL]** working tree clean (setelah commit Milestone 10).
- [x] **[CRITICAL]** branch rilis yang benar: `milestone/10-release-candidate`.
- [ ] **[CRITICAL]** semua commit di-push/di-backup — commit lokal; push dan merge ke `main` menunggu pemilik.
- [x] tidak ada file penting yang untracked.
- [x] tidak ada konflik merge.
- [x] tidak ada TODO/FIXME penting (`grep` pada scripts, data, scenes, tests, tools).
- [x] boot normal tidak butuh hack debug.
- [x] `.gitignore` sesuai Section 191 (+ `build/itch/`, `build/store/`, `release/publisher_metadata.json`); dikunci oleh `release.test_repository_ignores_build_output_and_secrets`.
- [x] `CHANGELOG.md` diperbarui.
- [x] `LICENSES.md` diperbarui.
- [x] `docs/implementation_decisions.md` terkini.
- [x] `docs/known_issues.md` terkini.

## 195.2 Secrets & security

- [x] **[CRITICAL]** scan secret bersih.
- [x] **[CRITICAL]** tidak ada `.keystore`/`.jks` di repository.
- [x] **[CRITICAL]** tidak ada password/token/service-account key.
- [ ] material signing produksi di lokasi aman pemilik — keystore rilis belum dibuat (tugas pemilik).
- [x] dependency pihak ketiga nol (selain Godot).

## 195.3 Generated assets

- [x] **[CRITICAL]** `generate_all` selesai dari project bersih (74 aset, 0 error).
- [x] **[CRITICAL]** manifest generator lengkap dan deterministik.
- [x] tidak ada aset dari internet (`assets` suite).
- [x] semua karakter (Darto, Bu Yati, Rini, Nisa), keenam ikan, motor, set Danau/Market/Rumah/duel, ikon UI.
- [x] audio sepenuhnya prosedural.
- [x] lembar referensi dirender ulang dari aset final.
- [ ] reference visual lock — diperiksa pengembang lewat screenshot; perlu persetujuan visual pemilik.
- [x] tidak ada kubus placeholder atau material debug di aset hero.

## 195.4 Content completeness

- [x] **[CRITICAL]** 4 tokoh manusia, 6 ikan, 3 sampah, 4 duel, 5×3 langkah upgrade.
- [x] semua event naratif Section 183 (`story` suite, NAR-001/002).
- [x] semua dialog ikan, Fish Book, tutorial, menu/settings/help dalam bahasa Inggris (`data` suite).
- [x] ending dan post-game.
- [x] tidak ada placeholder berbahasa Indonesia di layar.

## 195.5 Gameplay & economy

- [x] **[CRITICAL]** fishing, tinju, panco, joget, Suwit lulus (suite masing-masing + `boot`).
- [x] Wheel 25/25/25/25 (100.000 putaran, `docs/balance_report.md`).
- [x] harga jual, Arowana Rp300.000, harga dan efek upgrade, hutang awal Rp1.800.000, hutang tidak pernah negatif (`market` suite).
- [x] hutang bisa lunas tanpa Arowana (`story` dan `market` suite, simulasi).
- [x] tidak ada gameplay uang judi; tidak ada kode IAP/iklan.

## 195.6 Save & story

- [x] **[CRITICAL]** save baru, autosave, tutup/buka/Continue, pemulihan save rusak, migrasi (`save`, `boot`).
- [ ] simpan saat background/suspend di Android — butuh perangkat.
- [x] peringatan storage browser ada di Settings (Web).
- [x] satu event per kunjungan Market, skip mempertahankan state, rantai milestone, unlock ending, transisi post-game (`market`, `story`).

## 195.7 Accessibility

- [x] text scale, UI scale, High Contrast, Hold Assist, kalibrasi ritme, mode kidal, remap keyboard, durasi skip (`a11y` suite).
- [x] Reduced Flash, Reduced Motion, HUD Shake ON/REDUCED/OFF, beat pulse (setting sejak Milestone 4–6; `boot` menguji guncangan HUD).
- [x] informasi penting tidak hanya bergantung warna (bentuk lajur, panah, label, titik isi/kosong).

## 195.8 Performance

- [ ] **[CRITICAL]** FPS minimum Web di perangkat referensi — baseline desktop 250–640 FPS (`docs/performance_report.md`); perangkat referensi Web Medium belum diukur.
- [ ] **[CRITICAL]** FPS minimum Android di perangkat fisik — belum ada build Android.
- [ ] tidak ada thermal collapse dalam sesi panjang — butuh perangkat.
- [x] RAM dalam anggaran (memori statis ~86–104 MB).
- [x] draw call dan segitiga ditinjau (semua scene jauh di bawah anggaran).
- [ ] CPU audio prosedural per perangkat — belum diukur di perangkat lemah.
- [ ] anggaran boot/load/transisi — transisi pertama Market 1,8 dtk (KI-005).
- [x] anggaran paket Web (ZIP 11,2 MB).
- [ ] anggaran paket Android — belum ada build.
- [x] cek kebocoran memori (20× Danau ↔ Market, tidak bertambah).

## 195.9 Human playtest

- [ ] **[CRITICAL]** semua butir — belum dilakukan. Status: HUMAN PLAYTEST PENDING (`docs/playtest_report.md`).

## 195.10 Bug triage

- [x] **[CRITICAL]** nol BLOCKER, nol P0 yang diketahui.
- [ ] **[CRITICAL]** nol P1 core — KI-001 (ekonomi) dan KI-002 (tinju) menunggu keputusan pemilik.
- [x] P2/P3 terdokumentasi di `docs/known_issues.md`.
- [x] regression suite lulus (lihat laporan Milestone 10).

## 195.11 Web / itch.io

- [x] **[CRITICAL]** export Web berhasil dari project.
- [x] `index.html` di root ZIP; batas ZIP dan ekstrak aman.
- [x] smoke test Chromium (headless).
- [ ] Firefox, Safari — belum.
- [ ] tombol keyboard tidak memicu aksi browser, fokus hilang/kembali, layout portrait, tombol fullscreen — diuji otomatis di desktop; belum di browser oleh manusia.
- [ ] judul, deskripsi, cover, screenshot, tag itch.io — teks siap di `docs/store_compliance_report.md`; halaman belum dibuat.

## 195.12 Android / Google Play

- [ ] **[CRITICAL]** export Android, AAB ditandatangani kunci produksi pemilik, versionCode — preset siap; build butuh SDK, template, keystore (`README_BUILD.md`).
- [x] versionName dan versionCode konsisten dengan versi project (`release` suite).
- [x] target API dicek ulang (API 36, 14 November 2026).
- [x] min SDK 24, arm64-v8a, portrait, tanpa permission (`release` suite).
- [ ] gesture back, install bersih, update, ikon adaptive di perangkat — belum.

## 195.13 Store metadata

- [x] judul dan application ID final.
- [x] deskripsi pendek dan panjang (Section 186.7).
- [x] ikon 512, feature graphic, 5 screenshot dari game asli (`store_art_generator.gd`).
- [ ] screenshot final 1080×1920 native — saat ini diperbesar dari 590×1049 (KI-008).
- [ ] email dukungan nyata dan URL kebijakan privasi — tugas pemilik.

## 195.14 Privacy / Data Safety

- [x] **[CRITICAL]** perilaku runtime sesuai kontrak tanpa pengumpulan data (`release` suite).
- [ ] **[CRITICAL]** jawaban Data Safety di Play Console — draf di `docs/store_compliance_report.md`.
- [ ] **[CRITICAL]** kebijakan privasi tanpa placeholder — email dukungan belum diisi.
- [x] layar Privacy di game; tanpa SDK analitik/iklan, tanpa advertising ID, tanpa akun.

## 195.15–195.19

- [ ] rating konten (kuesioner IARC) — jawaban siap di `docs/store_compliance_report.md`.
- [x] dokumentasi: README, README_BUILD, README_TESTING, laporan milestone.
- [x] provenance: `release/build_manifest.json` dengan SHA-256 artefak.
- [ ] Gold Master, backup, dan pemeriksaan setelah publish — setelah semua di atas.
