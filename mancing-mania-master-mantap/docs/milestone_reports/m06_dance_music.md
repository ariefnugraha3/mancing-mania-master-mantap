# Laporan Milestone 6 — Dance + Procedural Music Engine

Format mengikuti GDD Section 191.15.

## Ringkasan

| | |
|---|---|
| Milestone | 6 — Dance + Procedural Music Engine |
| Branch | `milestone/06-dance-music`, dari `milestone/05-arm-wrestle` (commit lokal, belum di-merge) |
| Tag | belum; `v0.6.0-m6` setelah merge |
| Versi project | `0.6.0` |
| Save schema berubah | tidak (setting ritme sudah ada sejak Milestone 1) |
| Penyimpangan GDD | tidak ada. Keputusan D-073 sampai D-081 |

## Exit gate

| Syarat (GDD Section 181) | Hasil | Bukti |
|---|---|---|
| Same seed reproduces track schedule/chart | lulus | `dance.test_same_seed_same_track_and_chart`: chart, jadwal musik, dan sampel audio yang dirender identik untuk seed yang sama dan berbeda untuk seed, duel, atau ikan lain |
| DANCE/AUD critical tests pass | lulus | DANCE-001 sampai DANCE-011 dan AUD-011 otomatis; AUD-001 sampai AUD-004 sudah ada sejak Milestone 2 dan mencakup suara baru |
| 30/60 FPS timing remains correct | lulus | `dance.test_judgment_does_not_depend_on_frame_rate`: tekanan yang sama di 30, 60, dan 144 FPS menghasilkan penilaian dan skor yang sama; `boot.test_dance_scene_plays_on_the_audio_clock`: jam lagu di scene asli mengikuti audio yang diputar |

## Yang dikerjakan

- Audio: `MusicVoices` (12 instrumen), `MusicSequencer` (lagu koplo, tiga loop state, click track), `MusicRenderer` (render bertahap), `MusicEngine` (loop per state dengan fade, lagu dengan jam authoritative). Musik sekarang terdengar di menu, danau, tinju, dan panco.
- Aturan: `ChartGenerator`, `RhythmClock`, `DanceController` (API Section 169.13).
- Scene: `dance.tscn` sesuai Section 168.9, `DanceWorld`, `DanceHud`, `NoteField`.
- Settings: bagian Rhythm, `CalibrationOverlay`.
- Aset: panggung, lampu untai, set joget, clip joget Darto dan ikan, `ref_set_dance.png`.

## File

Ditambahkan: `scripts/audio/music_voices.gd`, `music_sequencer.gd`, `music_renderer.gd`, `music_engine.gd`; `scripts/gameplay/dance/` (`chart_generator.gd`, `rhythm_clock.gd`, `dance_controller.gd`, `dance_scene.gd`); `scripts/actors/dance_world.gd`; `scripts/ui/dance_hud.gd`, `note_field.gd`, `calibration_overlay.gd`; `scenes/dance/dance.tscn`; `tests/suites/test_dance.gd`; aset `env_dance_set`, `prop_dance_platform`, `prop_dance_string_light`, `ref_set_dance.png`.

Diubah: `autoload/audio_manager.gd`, `scripts/ui/settings_overlay.gd`, `data/dialogue/ui_text.tres`, generator karakter/ikan/prop/environment/referensi, suite `audio`, `assets`, `boot_flow`, `data`, `tests/run_all.gd`, dokumen, `project.godot`.

## Aset hasil generator

60 entri di manifest (naik dari 56). Generator headless dua kali berturut-turut menghasilkan manifest identik.

## Test

`godot --headless --path . --script res://tests/run_all.gd` — exit code 0, **217 lulus, 0 gagal** (data 15, state 13, save 21, rng 6, audio 17, services 14, fishing 25, market 24, boxing 20, arm_wrestle 15, dance 12, assets 13, boot 22).

Belum otomatis: DANCE-012 (lajur sentuh di Android), DANCE-013 (perangkat 30 FPS sungguhan), DANCE-014 (kehilangan fokus tab di Web); AUD-005 sampai AUD-010 dan AUD-012 (pemeriksaan dengar dan platform).

## Pemeriksaan manual

Screenshot 1280×720 dan portrait: panggung, lajur, nada jatuh, penilaian, combo, skor kedua pihak, beat pulse, Settings dengan bagian Rhythm. Diperbaiki dari screenshot: lajur menutupi penari di landscape; ikan terlihat dari sisi tipisnya; ikan terlalu kecil.

Belum diperiksa: **musik belum didengarkan** (hanya diperiksa lewat angka: tanpa NaN, tidak clipping, panjang loop, porsi hening di musik danau); joget belum dimainkan manusia; wizard kalibrasi belum dicoba dengan tangan; build Web dan Android belum ada.

## Masalah yang diketahui

- P1: musik belum pernah didengarkan; apakah terdengar seperti koplo, atau enak didengar, belum diketahui.
- P2: di 30 FPS tekanan rata-rata dinilai 16 ms terlambat (D-074); kalibrasi mengimbanginya.
- P2: label penilaian bisa menimpa nada di lajur tengah.
- P2: di portrait lajur menutupi kaki penari.
- Temuan balance P1 dari Milestone 4 dan 5 tetap terbuka (D-058, D-068).

## Performa

Joget di 1280×720 berjalan lancar di mesin pengembang. Render lagu 40 detik selesai dalam sekitar satu detik dengan anggaran 4 ms per frame. Suite test selesai dalam sekitar 200 detik.

## Penyimpangan GDD

Tidak ada. Yang paling perlu diketahui: D-073 (musik dirender lebih dulu, bukan `AudioStreamGenerator`), D-077 (rumus AI ikan), D-079 (pause memulai ulang joget).

## Prasyarat Milestone 7 — Suwit, Wheel, Full Fish Personality Content

- `suwit.tscn`, `wheel.tscn`, `result.tscn` sesuai Section 168.6, 168.10, 168.11.
- Alur encounter → Wheel → keempat duel → Result → danau. Pemilihan duel sementara (D-071) diganti Wheel.
- Konten kepribadian ikan: aksesori khas, gerak khas, dialog.
