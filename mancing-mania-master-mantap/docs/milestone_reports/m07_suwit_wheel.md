# Laporan Milestone 7 — Suwit, Wheel, Full Fish Personality Content

Format mengikuti GDD Section 191.15.

## Ringkasan

| | |
|---|---|
| Milestone | 7 — Suwit, Wheel, Full Fish Personality Content |
| Branch | `milestone/07-suwit-wheel-personality`, dari `milestone/06-dance-music` (commit lokal, belum di-merge) |
| Tag | belum; `v0.7.0-m7` setelah merge |
| Versi project | `0.7.0` |
| Save schema berubah | tidak |
| Penyimpangan GDD | tidak ada. Keputusan D-082 sampai D-087 |

## Exit gate

| Syarat (GDD Section 181) | Hasil | Bukti |
|---|---|---|
| Every fish works in every duel | lulus | `boot.test_every_fish_in_every_duel_scene`: 24 pasangan ikan×duel dibuka di scene asli sampai Result; suite aturan masing-masing duel juga menguji keenam ikan |
| WHEEL/SUWIT P0 pass | lulus | SUWIT-001 sampai SUWIT-008, WHEEL-001, WHEEL-002, WHEEL-005 otomatis di suite `suwit_wheel` |
| No missing dialogue key | lulus | `suwit_wheel.test_every_fish_line_exists`: semua 101 kunci dialog ada, setiap ikan punya percakapan pertama; `data.test_text_table_is_complete_and_clean` |

## Yang dikerjakan

- `SuwitController`, `WheelController`, `ResultController` sesuai API Section 169.13.
- `suwit.tscn`, `wheel.tscn`, `result.tscn` sesuai blueprint Section 168.6, 168.10, 168.11.
- `FishDialogue` dan `DialogueBox`; seluruh dialog Section 166.
- `DuelExit`: satu jalan keluar untuk keempat duel (commit → Result).
- Danau: ikan berbicara sebelum Wheel; baris REEL_ESCAPE saat senar putus.
- Aset: aksesori khas lima ikan, clip Suwit Darto dan ikan, meja Suwit, set Suwit, lembar referensi `ref_set_suwit.png` dan `ref_fish_lineup.png`.

## File

Ditambahkan: `scripts/gameplay/suwit/` (`suwit_controller.gd`, `suwit_scene.gd`), `scripts/gameplay/wheel/` (`wheel_controller.gd`, `wheel_scene.gd`), `scripts/gameplay/result/` (`result_controller.gd`, `result_scene.gd`), `scripts/gameplay/duel/duel_exit.gd`, `scripts/gameplay/fish_dialogue.gd`, `scripts/actors/suwit_world.gd`, `scripts/ui/suwit_hud.gd`, `move_icon.gd`, `wheel_graphic.gd`, `dialogue_box.gd`, `scenes/suwit/suwit.tscn`, `scenes/wheel/wheel.tscn`, `scenes/result/result.tscn`, 7 file `data/dialogue/fish_*.tres`, `tests/suites/test_suwit_wheel.gd`, aset `env_suwit_set`, `prop_suwit_table`, dua lembar referensi.

Diubah: scene dan skrip tinju, panco, joget, danau; `fishing_controller.gd`; `debug_service.gd`; `music_engine.gd`; `ui_text.tres`; generator ikan/karakter/prop/environment/referensi; suite `boot_flow`; `tests/run_all.gd`; dokumen; `project.godot`.

## Aset hasil generator

64 entri di manifest (naik dari 60). Keenam ikan dan Darto berubah (aksesori dan clip Suwit).

## Test

`godot --headless --path . --script res://tests/run_all.gd` — exit code 0, 356 detik, **232 lulus, 0 gagal**. Suite `boot` sekarang sekitar 310 detik; watchdog per suite dinaikkan ke 600 detik.

Belum otomatis: WHEEL-003, WHEEL-004, SUWIT-009 (pemeriksaan manual; bagian yang bisa diukur sudah diuji: Wheel pertama tidak bisa dilewati, tombol Suwit besar dan berjarak).

## Pemeriksaan manual

Screenshot 1280×720: Suwit dengan tell dan tombol gerakan, Result menang dan kalah dengan dialog, deretan keenam ikan dengan aksesori. Diperbaiki dari screenshot: panel tell menutupi wajah ikan; Result memakai set ring tinju dan Darto membelakangi kamera; tombol CONTINUE menutupi Darto; kacamata gurami terlalu kecil.

Belum diperiksa: Wheel belum dilihat berputar oleh manusia; dialog di danau sebelum Wheel hanya diuji otomatis; belum dimainkan manusia; suara belum didengarkan.

## Masalah yang diketahui

- P2: langkah `--mm-action` di command line kadang tidak memicu lemparan di danau saat dijalankan berurutan setelah `--mm-goto`; alur yang sama lulus di test.
- P2: titik skor Suwit berupa kotak polos; perlu bentuk yang lebih jelas di Milestone 9.
- P2: gerak khas spesies masih terbatas.
- Temuan balance P1 dari Milestone 4 dan 5 tetap terbuka.

## Performa

Tidak diukur ulang; scene baru memakai set yang ukurannya sama dengan duel sebelumnya.

## Penyimpangan GDD

Tidak ada.

## Prasyarat Milestone 8 — Narrative, Cutscenes, Event Arbitration, Ending

- Story scene dan cutscene untuk 13 event; `MarketController.leave_market()` sudah memanggil `StoryDirector.play_event()` begitu scene itu ada (D-041).
- Prolog, ikan pertama (percakapan pertama lele sudah ada sebagai dialog), Market pertama, milestone hutang, kemenangan pertama Arowana, hutang lunas, final keluarga, postgame.
