# Laporan Milestone 2 — Fishing Vertical Slice

Format mengikuti GDD Section 191.15.

## Ringkasan

| | |
|---|---|
| Milestone | 2 — Fishing Vertical Slice |
| Branch | `milestone/02-fishing-core` (commit lokal, belum di-merge ke `main`) |
| Tag | belum dibuat; `v0.2.0-m2` dibuat setelah merge disetujui |
| Engine | Godot 4.7.2 stable, renderer Compatibility |
| Versi project | `0.2.0` |
| Save schema berubah | tidak |
| Penyimpangan GDD | tidak ada. Hal yang tidak diatur GDD dicatat sebagai D-023 sampai D-040 |

## Exit gate

| Syarat (GDD Section 181) | Hasil | Bukti |
|---|---|---|
| Full cast → land/escape loop works | lulus | `boot.test_full_catch_in_the_real_scene` (scene asli, input action asli); `fishing.test_full_loop_with_a_simple_player`; dijalankan juga dengan jendela dan dipotret per fase |
| All FISH P0 tests pass | lulus | 25 test suite `fishing`; lihat tabel ID di bawah |
| Desktop + portrait HUD usable | lulus | screenshot 1280×720 dan 540×960 untuk idle, strike, reel, sesudah tangkapan; `boot.test_fishing_scene_follows_the_scene_blueprint` |

## Yang dikerjakan

**Aturan memancing** (`scripts/gameplay/fishing/`)

- `FishingController`: state machine `idle → casting → waiting → bite_warning → strike_window → reeling → landed | escaped`, dengan API Section 169.11. Waktu maju lewat `advance()` dengan langkah per frame dibatasi 0,1 detik.
- `EncounterRoller`: roll sampah/ikan, subtipe sampah, berat, BIG ONE, waktu tunggu, dan false nibble, semuanya dari satu seed encounter.
- `ReelSimulation`: marker, zona hijau yang meluncur (tidak pernah teleport), landing, line stress, band stress, feint Don Arowana.
- Ikan pertama selalu Bruiser Catfish. False strike hanya menunda gigitan 0,8 detik. Sampah langsung ke ember tanpa reel.
- Routing tangkapan: Wheel bila ada, lalu duel pertama yang tersedia, lalu ember. Di build ini belum ada scene duel, jadi ikan masuk ember dan HUD menjelaskannya.

**Dunia dan HUD**

- `fishing.tscn` sesuai blueprint Section 168.4.
- `FishingWorld`: Darto dengan joran yang mengikuti tangan, senar, pelampung (terbang, mengapung, tenggelam, ditarik), bayangan ikan, riak, cipratan, tanda `!`, dan reveal tangkapan (ikan mendarat, menggelepar, lalu berdiri dengan sarung tinju).
- `FishingHud` + `ReelHud`: cash, ember, satu prompt kontekstual, reaction bar saat strike, track tensi dengan zona dan marker, gauge stress, progres landing, tombol Market dan Pause. Di layout sentuh ada satu tombol besar CAST → STRIKE → HOLD REEL.
- Prompt tutorial memakai teks final Section 183.20 dan berhenti muncul setelah pemain melakukannya.
- `PauseOverlay`: Resume, Controls, Music/Sound on-off, Settings, Quit to Menu. Membuka pause menghentikan seluruh timer. Kehilangan fokus jendela dan app masuk background otomatis mem-pause.
- `BucketPeekOverlay`: isi ember dan perkiraan nilai jual.
- Ikon UI (`UiIcon`) digambar dari garis dan poligon.
- Main Menu sekarang memakai danau dan Darto sebagai latar; pemberitahuan "FOUNDATION BUILD" dihapus.

**Aset hasil generator**

- Builder baru: `mesh_builder`, `rig_builder`, `material_builder`, `prop_builder`, `fish_builder`, `character_builder`, `environment_builder`, `reference_sheet_generator`.
- Danau Cempaka: terrain, air ber-shader, dua pohon besar, rumput dan alang-alang (instancing), batu, tepi seberang dengan pohon, rumah dan bukit, tiang listrik, dan warung di kejauhan.
- Darto: rig 18 tulang, 11 clip memancing.
- Keenam ikan dengan profil badan masing-masing, rig 9 tulang, 6 clip fase memancing. Bruiser Catfish lengkap dengan empat pasang sungut, alis, dan sarung tinju.
- Prop: joran, pelampung, ember, sandal, kaleng, ban.
- Lembar referensi: `ref_fish_catfish.png`, `ref_chr_darto.png`, `ref_set_lake.png`.

**Audio**

- Sembilan SFX memancing Section 175.6, masing-masing dari resep sintesis sendiri.
- Ambience danau: loop air dan angin yang disintesis di latar selama beberapa frame, ditambah kicau burung acak. Ambience diredam saat gigitan asli.

## File

255 file di folder project: 80 script `.gd`, 41 resource `.tres`, 18 scene `.tscn`, 2 shader.

| Folder | Tambahan di milestone ini |
|---|---|
| `scripts/gameplay/fishing/` | `encounter_roller`, `reel_simulation`, `fishing_controller`, `fishing_scene` |
| `scripts/actors/` | `fishing_world`, `scatter_field`, `darto_menu_pose` |
| `scripts/ui/` | `fishing_hud`, `reel_hud`, `ui_icon`, `pause_overlay`, `bucket_peek_overlay` |
| `scripts/audio/` | `ambience_engine`; `sfx_renderer` ditulis ulang dengan 8 resep |
| `scenes/` | `fishing/fishing.tscn`, `ui/pause_overlay.tscn` |
| `shaders/` | `lake_water.gdshader`, `foliage_sway.gdshader` |
| `tools/generators/` | 8 file builder dan perender referensi |
| `data/audio/` | 9 preset SFX memancing |
| `generated/` | 7 material, 6 prop, 6 ikan, Darto, lake set, 3 lembar referensi |
| `tests/suites/` | `test_fishing.gd` |

File yang diubah: `project.godot` (versi), `scenes/menu/main_menu.tscn`, `scripts/ui/main_menu_controller.gd`, `autoload/audio_manager.gd`, `autoload/debug_service.gd`, `autoload/game_state.gd`, `scripts/gameplay/data/fishing_balance.gd`, `scripts/gameplay/game_data.gd`, `scripts/gameplay/data_validator.gd`, `scripts/ui/debug_overlay.gd`, `scripts/ui/ui_tokens.gd`, `scripts/ui/reel_hud.gd`, `scripts/ui/boot_controller.gd`, `tools/generators/generate_all_assets.gd`, `generator_io.gd`, `generator_manifest.gd`, `data/dialogue/ui_text.tres`, 6 file `data/fish/*.tres`, 3 file `data/trash/*.tres`, dan suite test yang ada.

Daftar lengkap: `git diff --stat main...milestone/02-fishing-core`.

## Aset hasil generator

26 entri di `generated/manifests/generator_manifest.json`: 23 dari generator headless dan 3 lembar referensi. Generator headless dijalankan dua kali berturut-turut dan menghasilkan manifest yang identik.

Lembar referensi dirender dengan GPU, jadi isinya bisa berbeda tipis antar mesin. Checksum di manifest mencatat file yang di-commit.

## Test

Perintah: `godot --headless --path . --script res://tests/run_all.gd` — exit code 0.

| Suite | Lulus | Gagal |
|---|---:|---:|
| data | 14 | 0 |
| state | 13 | 0 |
| save | 21 | 0 |
| rng | 6 | 0 |
| audio | 11 | 0 |
| services | 14 | 0 |
| fishing | 25 | 0 |
| assets | 8 | 0 |
| boot | 10 | 0 |
| **Total** | **122** | **0** |

ID matriks QA Section 180.3 yang tercakup otomatis:

| ID | Test |
|---|---|
| FISH-002 | `fishing.test_cast_timeline` (pelampung lepas di 0,48 detik) |
| FISH-004, FISH-005 | `fishing.test_wait_time_formula` |
| FISH-007 | `fishing.test_false_strike_costs_only_a_short_delay` |
| FISH-008 | `fishing.test_strike_windows_match_the_table` |
| FISH-009 | `fishing.test_late_strike_lets_the_fish_escape` |
| FISH-010 | `fishing.test_trash_goes_straight_to_the_bucket` |
| FISH-011 | `fishing.test_encounter_distribution_over_100k_rolls` dan `..trash_subtype..` dengan toleransi Section 179.2 |
| FISH-012 | `fishing.test_line_breaks_at_full_stress` |
| FISH-013 | `fishing.test_fish_lands_exactly_once` |
| FISH-014, FISH-015 | `boot.test_stress_shakes_the_hud_by_setting_and_never_the_camera` |
| FISH-016 | `fishing.test_carbon_rod_widens_the_zone_up_to_the_clamp` |

## Pemeriksaan manual

Build debug berjendela di Windows (NVIDIA RTX 3050 Laptop), diperiksa lewat screenshot:

- Danau di 1280×720 dan 540×960: idle, prompt cast, STRIKE! dengan reaction bar dan tanda `!`, HUD reel, banner tangkapan, ember bertambah.
- Tangkapan ikan penuh dan tangkapan sampah, dimainkan oleh bot reel debug.
- Main Menu dengan latar danau.
- Lembar referensi lele, Darto, dan danau.
- FISH-003: joran mengarah ke permukaan danau setelah cast, tidak tegak.

**Belum diperiksa:**

- **Suara belum didengarkan.** SFX dan ambience hanya diverifikasi lewat angka (tanpa NaN, tidak clipping, gigitan asli jauh lebih keras dan lebih rendah daripada nibble). Apakah enak didengar harus dinilai manusia.
- **Rasa bermain belum diuji manusia.** Semua putaran dimainkan bot atau test. Apakah reel terasa adil dengan tangan belum diketahui.
- Animasi belum ditonton bergerak; yang diperiksa hanya pose di screenshot. FISH-001 (urutan gerak cast) dan FISH-006 belum dinilai secara visual.
- Build Web dan Android belum ada.

## Masalah yang diketahui

Tidak ada P0 atau P1 yang diketahui.

- P2: motor Darto belum ada di danau. Section 185.13 memintanya sebagai elemen sekunder; ia dibuat oleh `vehicle_builder` di Milestone 9.
- P2: lima ikan selain lele baru punya bentuk badan dan warna. Aksesori khasnya (kacamata, headband, kalung, bekas luka) menyusul; ini diizinkan target Milestone 2.
- P2: joran kaku (tidak melengkung) dan senar hanya garis satu piksel.
- P2: pupil mata lele kecil dan kurang terbaca dari jauh.
- P2: belum ada musik di danau. Mesin musik prosedural adalah Milestone 6; diam adalah state musik yang sah menurut Section 175.11.
- P2: tab How To Play di portrait masih bisa melebihi lebar panel (dari Milestone 1).
- Test: peringatan `ObjectDB instances were leaked at exit` kadang muncul di akhir suite `boot`. Hanya terjadi di test.

## Performa

Danau di 1280×720, vsync mati, mesin pengembang: sekitar 330 FPS, 72 draw call, memori statis 85 MB. Generator headless selesai dalam 3 detik. Suite test selesai dalam sekitar 55 detik. Ini bukan pengukuran perangkat target; profil resmi mengikuti Section 190 di Milestone 9.

## Penyimpangan GDD

Tidak ada. Keputusan untuk hal yang tidak diatur GDD ada di `docs/implementation_decisions.md` (D-023 sampai D-040). Yang paling perlu diketahui pemilik project:

- **D-023**: `FishingBalance` mendapat field tambahan untuk angka yang ada di GDD tetapi tidak ada di skemanya (jendela strike sampah 0,90; interval retarget zona 0,65–1,40), plus dua angka rasa yang tidak ada di GDD (lama bayangan ikan sebelum gigitan 1,1 detik; peluang feint Arowana 35%).
- **D-025**: sampah tidak melewati minigame reel, karena GDD tidak memberi angka reel untuk sampah.
- **D-026**: selama belum ada scene duel, ikan yang mendarat langsung masuk ember.

## Prasyarat Milestone 3 — Market, Ekonomi, Upgrade, Book, Records

- Merge `milestone/02-fishing-core` ke `main` dan tag `v0.2.0-m2`.
- `scenes/market/market.tscn` sesuai Section 168.5. Tombol MARKET di HUD danau aktif otomatis begitu scene itu ada.
- `MarketController` dengan API Section 169.12 dan urutan transaksi validate → mutate → autosave → refresh → evaluate story.
- `MarketSet` dan Bu Yati dari generator (`environment_builder`, `character_builder`).
- Data `StoryEvent` untuk milestone hutang, dan antrean trigger di `StoryDirector` (tanpa cutscene final).
- Potret Fish Book dari perender referensi, lalu nyalakan `require_portraits` di validasi (D-018).
- `StoryDirector.begin_market_visit()` dipanggil saat transisi Fishing → Market selesai.
