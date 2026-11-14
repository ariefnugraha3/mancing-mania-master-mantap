# Laporan Milestone 8 — Narrative, Cutscenes, Event Arbitration, Ending

Format mengikuti GDD Section 191.15.

## Ringkasan

| | |
|---|---|
| Milestone | 8 — Narrative, Cutscenes, Event Arbitration, Ending |
| Branch | `milestone/08-narrative`, dari `milestone/07-suwit-wheel-personality` (commit lokal, belum di-merge) |
| Tag | belum; `v0.8.0-m8` setelah merge |
| Versi project | `0.8.0` |
| Save schema berubah | tidak (field `family_savings`, `ending_completed`, `postgame_unlocked` sudah ada sejak v5) |
| Penyimpangan GDD | tidak ada. Keputusan D-088 sampai D-094 |

## Exit gate

| Syarat (GDD Section 181, Milestone 8) | Hasil | Bukti |
|---|---|---|
| Start-to-ending story can be completed | lulus | `story.test_new_game_opens_with_the_prologue` (New Game → prolog → danau) dan `story.test_paying_the_debt_runs_the_ending_into_the_postgame` (bayar sisa hutang di Market asli → `story_debt_paid` → final keluarga → credits → unlock postgame → danau → Main Menu dengan dekorasi ending), semuanya di scene asli |
| STORY/NAR P0 pass | lulus | STORY-001..006, 011 di suite `market`; STORY-007 `story.test_skipping_applies_everything_watching_would`; STORY-008 rantai ending di atas; STORY-012 `story.test_postgame_turns_the_ledger_into_family_savings`; NAR-001 `story.test_every_story_line_exists_in_the_text_table` dan `test_every_story_event_has_a_playable_timeline`; NAR-002 `story.test_no_placeholder_in_the_story` |
| Zero placeholder narrative key | lulus | NAR-002 dan `data.test_text_table_is_complete_and_clean` |
| Debt can complete without Arowana | lulus | rantai ending di atas memeriksa Don Arowana tidak pernah ditemui; `market.test_paying_everything_reaches_the_finale_without_arowana` |

## Yang dikerjakan

- Scene Story sesuai blueprint Section 168.3: `StoryController`, `StageRoot` (`ActiveSetAnchor`, `Actors`, `Props`, `StoryCamera`), `StoryCanvas/StoryUI` (`DialoguePanel`, `SpeakerLabel`, `DialogueLabel`, `ContinuePrompt`, `NotificationPanel`, `SkipHoldIndicator`), `FadeLayer`.
- 13 timeline dengan teks final Section 183 (198 baris cerita, credits, CePatCash, obrolan Bu Yati).
- Skip tahan 0,8 detik yang menerapkan semua perubahan state.
- Rute: New Game/Continue → prolog; event Market → Story → danau; hutang lunas → final keluarga → credits → postgame → danau.
- Event di tempat: ikan pertama di danau, Market pertama di warung, kemenangan pertama Arowana di Result (D-090).
- Credits (juga dari Main Menu), Free Fishing, Family Savings, variasi Main Menu setelah ending.
- Notifikasi CePatCash dan obrolan Bu Yati.
- Aset: Rini, Nisa, clip keluarga dan clip cerita Darto, set rumah, lima prop baru, lembar referensi `ref_set_home.png`.

## File

Ditambahkan: `scripts/gameplay/story/` (`story_controller.gd`, `story_scene.gd`, `story_timelines.gd`, `credits_scene.gd`, `cepatcash.gd`), `scripts/ui/story_ui.gd`, `scenes/story/story.tscn`, `scenes/credits/credits.tscn`, `data/story/story_timelines.json`, `tests/suites/test_story.gd`, aset `chr_rini`, `chr_nisa`, `env_home_set`, `prop_motorcycle_darto`, `prop_helmet`, `prop_drink_glass`, `prop_picnic_mat`, `prop_rice_cooker`, `ref_set_home.png`.

Diubah: `scene_router.gd` (credits), `debug_service.gd`, `main_menu_controller.gd`, `fishing_scene.gd`, `market_scene.gd`, `market_controller.gd`, `market_hud.gd`, `debt_panel.gd`, `result_scene.gd`, `fish_arowana_don_first_win.tres`, `ui_text.tres`, generator karakter/prop/environment/referensi, `chr_darto.tscn`, suite `boot_flow`, `tests/run_all.gd`, dokumen, `project.godot`.

## Aset hasil generator

73 entri di manifest (naik dari 64). Generator dijalankan dua kali; manifest identik byte demi byte.

## Test

`godot --headless --path . --script res://tests/run_all.gd` — exit code 0, 396 detik, **245 lulus, 0 gagal**, tanpa script error. Suite baru `story` (13 test); suite `boot`, `market`, dan `suwit_wheel` disesuaikan dengan prolog dan event yang kini diputar scene Story.

Belum otomatis: STORY-009, STORY-010, NAR-003 (manual).

## Pemeriksaan manual

Screenshot 1280×720: prolog (ponsel dengan saldo dan notifikasi CePatCash, Rini di pintu), panggilan Nisa 600k, pesan Rini 300k, final keluarga di danau. Diperbaiki dari screenshot: teks ponsel gelap di atas latar gelap, isi ponsel melebar keluar layar, kotak dialog terpotong di bawah, ponsel tetap terbuka setelah cut, kamera 600k melihat punggung Darto.

Belum diperiksa: belum dimainkan manusia dari awal sampai ending; jeda komedi (STORY-010) belum dinilai manusia; suara belum didengarkan.

## Masalah yang diketahui

- P2: pose "melihat ponsel" Darto mengangkat lengan ke samping dan tidak ada model ponsel di tangan; diperbaiki di Milestone 9.
- P2: motor Darto dari samping lebih mirip mobil kecil; diperbaiki di Milestone 9.
- P2: poni Rini menutupi mata dari beberapa sudut.
- P2: ukuran Nisa di set danau belum tampak jelas lebih kecil dari Rini.
- Temuan balance P1 dari Milestone 4 dan 5 tetap terbuka.

## Performa

Tidak diukur ulang. Set rumah lebih kecil dari set danau.

## Penyimpangan GDD

Tidak ada.

## Prasyarat Milestone 9 — Final Art, UI/UX, Animation, Audio, Accessibility, Performance

- Masalah P2 di atas.
- Setting visual dan aksesibilitas (Section 167, 175): high contrast, reduced flash, UI scale, handedness, mode input panco.
- Titik skor Suwit, polesan Wheel, gerak khas spesies.
