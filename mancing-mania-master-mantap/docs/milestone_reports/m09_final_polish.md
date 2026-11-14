# Laporan Milestone 9 — Final Art, UI/UX, Animation, Audio, Accessibility, Performance

Format mengikuti GDD Section 191.15.

## Ringkasan

| | |
|---|---|
| Milestone | 9 — Final Art, UI/UX, Animation, Audio, Accessibility, Performance |
| Branch | `milestone/09-final-polish`, dari `milestone/08-narrative` (commit lokal, belum di-merge) |
| Tag | belum; `v0.9.0-m9` setelah merge |
| Versi project | `0.9.0` |
| Save schema berubah | tidak (semua setting Section 189 sudah ada di schema v5; nilai "relaxed" untuk kecepatan dialog kini dipakai UI) |
| Penyimpangan GDD | tidak ada. Keputusan D-095 sampai D-102 |

## Exit gate

| Syarat (GDD Section 181, Milestone 9) | Hasil | Bukti |
|---|---|---|
| No missing required generated asset | lulus | `assets` suite; manifest 74 entri (naik dari 73); generator dua kali berturut-turut menghasilkan manifest identik |
| GEN/VIS/UI/AUD/A11Y/PERF major tests pass | lulus untuk yang otomatis | suite `assets`, `audio`, `a11y` (15 test: A11Y-001, 002, 003, 007, 008, 009, 010, 012 dan setting wajib Section 189.1), `boot` (UI di landscape dan portrait); PERF lewat `docs/performance_report.md` |
| All reference sheets generated and visually locked | lulus | `generated/references/` dirender ulang setelah perubahan art; diperiksa lewat screenshot |
| Visual direction consistent | lulus (pemeriksaan pengembang) | screenshot prolog, final keluarga, Settings, Suwit |
| Zero unauthorized external production asset | lulus | `assets.test_no_internet_assets` dan validator kebijakan aset |
| No forbidden audio files | lulus | `assets` suite: tidak ada file audio di project; semua suara prosedural |

## Yang dikerjakan

- Settings lengkap Section 189.1: VISUAL, ACCESSIBILITY, CONTROLS. Semua setting tersimpan otomatis.
- UI scale, text scale, preset grafis LOW/MEDIUM/HIGH, High Contrast HUD, Hold Assist panco, mode kidal, remap keyboard dengan konflik dan reset.
- Art: ponsel di tangan Darto, pose membaca ponsel, motor bebek baru, rambut keluarga, skala Nisa, kursi plastik, titik skor Suwit.
- Probe performa dan baseline Section 190.

## File

Ditambahkan: `scripts/ui/display_settings.gd`, `scripts/ui/controls_overlay.gd`, `scripts/utilities/input_remap.gd`, `scripts/gameplay/arm_wrestle/hold_assist.gd`, `tools/perf/perf_probe.gd`, `tests/suites/test_accessibility.gd`, `docs/performance_report.md`, aset `prop_phone`.

Diubah: `scene_router.gd`, `settings_overlay.gd`, `ui_tokens.gd`, `hud_chip.gd`, `fishing_hud.gd`, `reel_hud.gd`, `note_field.gd`, `boxing_hud.gd`, `suwit_hud.gd`, `wheel_graphic.gd`, `dialogue_box.gd`, `arm_wrestle_scene.gd`, `arm_wrestle_hud.gd`, `dance_scene.gd`, `story_controller.gd`, `story_timelines.json`, `ui_text.tres`, generator karakter dan prop, `chr_darto`, `chr_rini`, `chr_nisa`, `prop_motorcycle_darto`, lembar referensi, suite `boot_flow`, `tests/run_all.gd`, dokumen, `project.godot`.

## Test

`godot --headless --path . --script res://tests/run_all.gd` — exit code 0, 412 detik, **260 lulus, 0 gagal**, tanpa script error.

Batas tunggu Result di suite `boot` dinaikkan dari 20 ke 60 detik: setelah suite `a11y` ditambahkan, urutan seed duel bergeser dan pertandingan Suwit dengan beberapa ronde seri melewati 20 detik.

Belum otomatis: A11Y-004 (sudah diuji di `boot.test_stress_shakes_the_hud_by_setting_and_never_the_camera`), A11Y-005 dan A11Y-006 (sebagian lewat setting yang sudah ada sejak Milestone 4–6), A11Y-011 (manual).

## Pemeriksaan manual

Screenshot 1280×720: prolog (Darto memegang ponsel), final keluarga (Nisa lebih kecil, kursi plastik, motor), Settings dengan bagian baru, HUD Suwit. Diperbaiki dari screenshot: kursi menghadap terbalik, Nisa tidak mengecil, keluarga duduk melayang.

Belum diperiksa: layar KEYBOARD CONTROLS hanya diuji otomatis; High Contrast dan mode kidal belum dilihat manusia di perangkat sentuh; suara belum didengarkan.

## Masalah yang diketahui

- P2: satu frame 50–63 ms saat pertama masuk tinju, panco, dan Wheel (lihat laporan performa).
- P2: transisi pertama ke Market 1,8 dtk (target 1,5 dtk), kunjungan berikutnya 0,9 dtk.
- P2: teks yang digambar langsung (lajur joget, Wheel) tidak ikut Text Scale.
- Temuan balance P1 dari Milestone 4 dan 5 tetap terbuka; dibahas di simulasi Milestone 10.

## Performa

Lihat `docs/performance_report.md`: semua scene jauh di bawah anggaran draw call dan segitiga; memori statis ~86–104 MB; tidak ada kebocoran pada 20 kali bolak-balik Danau ↔ Market.

## Penyimpangan GDD

Tidak ada.

## Prasyarat Milestone 10 — Balance, Full QA, Release Candidate

- Simulasi Section 179 dan keputusan balance (D-058, D-068).
- Export preset Web dan Android, `README_BUILD.md`, dokumen rilis Section 186–196.
