# Laporan Milestone 1 — Foundation, Data, Save, Input, Debug Shell

Format mengikuti GDD Section 191.15.

## Ringkasan

| | |
|---|---|
| Milestone | 1 — Foundation, Data, Save, Input, Debug Shell |
| Branch | `milestone/01-foundation`, di-merge ke `main` pada 2026-11-12 |
| Tag | `v0.1.0-m1` |
| Engine | Godot 4.7.2 stable, renderer Compatibility |
| Versi project | `0.1.0` |
| Save schema berubah | tidak (schema 5 dibuat pertama kali di milestone ini) |
| Penyimpangan GDD | satu, sudah disetujui dan dimasukkan ke GDD: D-003 (`duel_wins` di `fish_book`) |

## Exit gate

| Syarat (GDD Section 181) | Hasil | Bukti |
|---|---|---|
| Project boots | lulus | `boot.test_boot_reaches_main_menu_without_a_save`; dijalankan juga dengan jendela asli |
| New Game creates valid save | lulus | `boot.test_new_game_creates_a_valid_save`, `save.test_new_game_creates_schema_v5_file` |
| Continue reloads state | lulus | `boot.test_continue_reloads_the_saved_state`, `save.test_save_then_load_restores_exact_state` |
| Tests BOOT/SAVE foundation pass | lulus | 88 dari 88 test |
| No parser errors | lulus | tidak ada error parse atau script di log import, test, dan run |

## Yang dikerjakan

Semua butir target Milestone 1:

- **Baseline project**: nama `Mancing Mania Gelut Edition`, renderer `gl_compatibility`, 1280×720, stretch `canvas_items`/`expand`, orientasi Android portrait, mix rate 48 kHz.
- **Struktur folder** sesuai Section 119.1. Folder yang belum berisi diberi `.gitkeep`.
- **InputMap**: 20 action remappable Section 189.15 dengan default Section 91, ditambah `debug_toggle_overlay`.
- **Autoload**: sembilan service dengan API Section 169.
- **Kelas Resource**: `FishData`, `TrashData`, `UpgradeData`, `FishingBalance`, `BoxingConfig`, `ArmWrestleConfig`, `DanceConfig`, `SuwitConfig`, `StoryEvent`, `DialogueEntry`, `DialogueSequence`, `AudioPreset`, `TextTable`.
- **Data authoritative**: 6 ikan, 3 sampah, 5 upgrade, 5 file balance. Nilainya dikunci test terhadap tabel GDD.
- **Save v5**: buat, muat, validasi dan perbaikan (Section 171.12), penulisan atomik, backup save rusak, import/export, autosave setting.
- **SceneRouter**: fade terpusat, pemuatan scene di thread, penolakan rute ganda.
- **AudioManager prosedural**: layout bus, volume per bus dari setting, `ui_click` / `ui_back` / `ui_disabled` disintesis dan di-cache saat Boot.
- **DebugService + overlay dasar**: tab STATE, RNG, PERFORMANCE, PLATFORM dalam satu panel; mutasi cash/hutang; `SAVE DEBUG STATE`; `COPY REPRO STATE`.
- **Validasi Boot**: data, InputMap, dan preset audio diperiksa di debug build; kegagalan ditampilkan sebagai daftar di layar Boot.
- **Main Menu**: Continue, New Game dengan konfirmasi dua langkah, How To Play (teks final Section 183.19), Settings (volume audio, RESET SAVE dua langkah), pemulihan save rusak.
- **Generator**: arsitektur `tools/generators/`, manifest dengan checksum, tema UI dan ikon aplikasi sebagai aset hasil generate pertama.
- **Kebijakan tanpa aset internet**: `tools/validation/asset_policy_scan.gd`.

## File

Total 176 file di folder project (58 script `.gd`, 25 resource `.tres`, 2 scene `.tscn`).

| Folder | Isi |
|---|---|
| `autoload/` | 9 service |
| `scripts/gameplay/` | `content_ids`, `game_data`, `data_validator`, `save_schema`, dan 11 kelas data |
| `scripts/audio/` | `audio_preset`, `synth_dsp`, `sfx_renderer` |
| `scripts/ui/` | `ui_tokens`, `game_button`, `safe_area_root`, `overlay_panel`, `modal_dialog`, `settings_overlay`, `how_to_overlay`, `boot_controller`, `main_menu_controller`, `debug_overlay` |
| `scripts/utilities/` | `game_log`, `money`, `text_table`, `text_db`, `input_actions` |
| `data/` | ikan, sampah, upgrade, balance, 3 preset audio, `dialogue/ui_text.tres` |
| `scenes/` | `boot/boot.tscn`, `menu/main_menu.tscn` |
| `tools/` | `generate_all_assets`, `generator_manifest`, `generator_io`, `generator_validation`, `ui_art_builder`, `asset_policy_scan` |
| `generated/` | `ui/ui_theme.tres`, `ui/app_icon.png`, `manifests/generator_manifest.json` |
| `tests/` | runner, kelas dasar, 8 suite |
| root project | `README.md`, `README_TESTING.md`, `CHANGELOG.md`, `default_bus_layout.tres` |

File yang diubah: `project.godot`, `.gitignore`. File yang dihapus: `icon.svg`, `icon.svg.import`.

Daftar lengkap: `git diff --stat main...milestone/01-foundation`.

## Aset hasil generator

| ID | Output | Generator |
|---|---|---|
| `ui_theme` | `res://generated/ui/ui_theme.tres` | `ui_art_builder` v1 |
| `ui_app_icon` | `res://generated/ui/app_icon.png` | `ui_art_builder` v1 |

Generator dijalankan berulang dan dengan dua cara peluncuran (`--script` dan `--editor --script`); checksum di manifest sama persis.

## Test

Perintah: `godot --headless --path . --script res://tests/run_all.gd` — exit code 0, sekitar 13 detik.

| Suite | Lulus | Gagal |
|---|---:|---:|
| data | 14 | 0 |
| state | 13 | 0 |
| save | 21 | 0 |
| rng | 6 | 0 |
| audio | 7 | 0 |
| services | 13 | 0 |
| assets | 8 | 0 |
| boot | 6 | 0 |
| **Total** | **88** | **0** |

ID matriks QA (GDD Section 180) yang tercakup otomatis: BOOT-001, BOOT-002, BOOT-003, BOOT-004, SAVE-001 sampai SAVE-009, SAVE-012.

## Pemeriksaan manual

Dilakukan dengan menjalankan build debug berjendela di Windows (NVIDIA RTX 3050 Laptop, OpenGL 3.3 Compatibility) dan memeriksa screenshot:

- Main Menu di 1280×720 dan 540×960 (portrait).
- Settings, How To Play, dialog "FOUNDATION BUILD" setelah New Game, dialog konfirmasi ganti save di portrait, Debug Overlay.
- Ikon aplikasi hasil generator.

**Belum diperiksa:**

- Suara belum didengarkan. SFX hanya diverifikasi lewat angka (tanpa NaN/Inf, peak di bawah skala penuh, durasi, awal dan akhir senyap).
- Hover, navigasi keyboard antar tombol, dan menggeser slider dengan mouse belum dicoba dengan tangan.
- Build Web dan Android belum ada (export preset masuk Milestone 10), jadi BOOT-005, BOOT-006, SAVE-010, SAVE-011 belum dijalankan.
- Safe area Android hanya diuji lewat kode; belum di perangkat ber-notch.

## Masalah yang diketahui

Tidak ada P0 atau P1 yang diketahui.

- P2: di Main Menu portrait, matahari berada di luar bingkai kamera. Komposisi final ikut `LakeSet` di Milestone 2.
- P2: matahari di langit menu tampak putih terang tanpa bentuk. Akan diganti saat pencahayaan danau dibuat.
- P2: tab How To Play di portrait bisa melebihi lebar panel; TabContainer menampilkan panah gulir. Dirapikan di Milestone 9.
- Test: peringatan `ObjectDB instances were leaked at exit` di akhir suite `boot`. Hanya terjadi di test (lihat `README_TESTING.md`).

## Performa

Main Menu di 1280×720, vsync mati, mesin pengembang: 540–650 FPS, 31–57 draw call, memori statis sekitar 72 MB. Boot sampai Main Menu sekitar 1,3 detik setelah engine siap. Rendering tiga SFX UI saat Boot tidak terasa. Ini bukan pengukuran pada perangkat target; profil resmi mengikuti Section 190 di Milestone 9.

## Penyimpangan GDD

**D-003 — `fish_book` menyimpan `duel_wins` per ikan.** Section 171.5 mendefinisikan `favourite_duel` sebagai mode dengan kemenangan terbanyak, tetapi skema tidak menyimpan kemenangan per mode, sehingga nilainya tidak bisa dihitung. Ditambahkan field `duel_wins` di tiap entri. Penambahan murni, schema tetap versi 5. Disetujui pemilik project pada 2026-11-12 dan GDD Section 171.5 sudah diperbarui; rinciannya di `docs/implementation_decisions.md`.

Hal lain yang diisi karena GDD tidak mengaturnya (bukan penyimpangan) tercatat sebagai D-001, D-002, D-004 sampai D-022.

## Prasyarat Milestone 2 — Fishing Vertical Slice

- Builder baru di `tools/generators/`: `mesh_builder`, `material_builder`, `character_builder` (Darto), `fish_builder` (Bruiser Catfish kualitas final), `prop_builder` (joran, pelampung, ember), `environment_builder` (LakeSet), lalu didaftarkan di `BUILDERS`.
- `scenes/fishing/fishing.tscn` sesuai blueprint Section 168.4. Begitu file itu ada, New Game dan Continue otomatis menuju danau; hapus teks `menu.foundation.*`.
- Tambahkan `LakeSet` dan `DartoMenuPose` ke `main_menu.tscn`.
- Timer gameplay (strike window, reel) memakai akumulasi `delta`, bukan `SceneTreeTimer` (D-022).
- Nyalakan `require_assets` untuk Bruiser Catfish setelah modelnya ada (D-018).
