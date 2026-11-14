# Laporan Milestone 5 — Arm Wrestling Complete

Format mengikuti GDD Section 191.15.

## Ringkasan

| | |
|---|---|
| Milestone | 5 — Arm Wrestling Complete |
| Branch | `milestone/05-arm-wrestle`, dibuat dari `milestone/04-boxing` (commit lokal, belum di-merge) |
| Tag | belum dibuat; `v0.5.0-m5` setelah merge |
| Versi project | `0.5.0` |
| Save schema berubah | tidak |
| Penyimpangan GDD | tidak ada. Keputusan D-066 sampai D-072 |

## Exit gate

| Syarat (GDD Section 181) | Hasil | Bukti |
|---|---|---|
| ARM P0 pass | lulus | ARM-001 sampai ARM-007 dan ARM-009 sampai ARM-011 otomatis di suite `arm_wrestle` |
| 32 sec round deterministic | lulus | `test_timeout_follows_the_position` (ronde 32,0 detik), `test_same_seed_same_match` (seed dan tekan yang sama menghasilkan pertandingan yang sama); simulasi tick tetap 1/120 detik |
| Comfortable mobile input verified | lulus secara otomatis, belum diuji tangan | 7 tekan/detik mengalahkan keenam ikan (`test_every_fish_falls_to_a_comfortable_rate`); menekan di atas batas tidak dihukum (`test_presses_above_ten_a_second_are_ignored`); tombol MASH selebar layar dan mengisi 30% bawah di portrait (`boot.test_arm_wrestle_portrait_layout`). Kenyamanan di perangkat sentuh nyata (ARM-012) belum diuji |

## Yang dikerjakan

- `ArmWrestleController` (API Section 169.13): impuls 4,8 × band tenaga, biaya stamina 7, batas 10 tekan/detik, regen 26/detik setelah 0,35 detik, stamina maksimum dari Herbal Tonic, dorongan tetap dan burst ikan dengan peringatan, ronde 32 detik, Sudden Grip, rematch Don Arowana.
- `ArmWrestleBot` untuk test dan QA.
- `arm_wrestle.tscn` sesuai Section 168.8; `ArmWrestleWorld` (lengan miring sesuai posisi, sirip yang selalu menggenggam), `ArmWrestleHud`, `PositionBar`.
- Aset: meja panco, bantalan siku, set panco di tepi danau; clip panco Darto (6) dan keenam ikan (4); lembar referensi `ref_set_arm.png`.
- Audio: enam SFX Section 175.9; resep baru `rising_pulse`, `fanfare`, `two_note_down`.
- Pemilihan duel: setelah duel pertama (tinju), duel diundi dari seed encounter.

## File

Ditambahkan: `scripts/gameplay/arm_wrestle/` (`arm_wrestle_controller.gd`, `arm_wrestle_bot.gd`, `arm_wrestle_scene.gd`), `scripts/actors/arm_wrestle_world.gd`, `scripts/ui/arm_wrestle_hud.gd`, `scripts/ui/position_bar.gd`, `scenes/arm_wrestle/arm_wrestle.tscn`, 6 preset `data/audio/arm_*.tres`, `tests/suites/test_arm_wrestle.gd`, aset `env_arm_set`, `prop_arm_table`, `prop_arm_elbow_pad`, `ref_set_arm.png`.

Diubah: `project.godot`, `autoload/audio_manager.gd`, `autoload/debug_service.gd`, `scripts/audio/sfx_renderer.gd`, `scripts/gameplay/data/arm_wrestle_config.gd`, `scripts/gameplay/fishing/fishing_controller.gd`, `scripts/ui/boot_controller.gd`, `data/dialogue/ui_text.tres`, generator karakter/ikan/prop/environment/referensi, `tests/run_all.gd`, suite `assets`, `audio`, `boot_flow`, dokumen.

## Aset hasil generator

56 entri di manifest (naik dari 52). Generator headless dua kali berturut-turut menghasilkan manifest identik. Keenam ikan dan Darto berubah (clip panco).

## Test

`godot --headless --path . --script res://tests/run_all.gd` — exit code 0, 188 detik, **199 lulus, 0 gagal** (data 14, state 13, save 21, rng 6, audio 15, services 14, fishing 25, market 24, boxing 20, arm_wrestle 15, assets 12, boot 20).

ARM-008 (peringatan burst terlihat sebelum burst) dan ARM-012 adalah pemeriksaan manual. Peringatan burst sudah diuji secara otomatis (selalu 0,7 detik sebelum burst) dan terlihat berdenyut di screenshot, tetapi belum dinilai manusia.

## Pemeriksaan manual

Screenshot di 1280×720 dan jendela portrait: meja, lengan tegak dan miring sesuai posisi, sirip yang menggenggam, bar posisi, stamina dengan takik band, tombol MASH. Diperbaiki dari screenshot: meja terlalu rendah, lengan bawah Darto mendatar, sirip ikan tidak mencapai genggaman, kepalan berada di bawah meja.

Belum diperiksa: belum dimainkan manusia, animasi belum ditonton bergerak, suara belum didengarkan, belum dicoba di perangkat sentuh.

## Masalah yang diketahui

- P1 (balance, D-068): istirahat tidak pernah lebih menguntungkan daripada terus menekan.
- P1 (dari Milestone 4, D-058): menekan JAB terus mengalahkan empat ikan pertama di tinju.
- P2: tabung sirip Don Arowana panjang dan janggal.
- P2: petunjuk tutorial di portrait menimpa meja.
- P2: bila jendela kehilangan fokus saat run otomatis, game pause; itu perilaku yang benar tetapi membuat screenshot otomatis tertutup menu pause.
- Lain-lain dari milestone sebelumnya tetap berlaku.

## Performa

Panco di 1280×720, vsync mati: sekitar 384 FPS, 94 draw call (target Section 190.6: ≤150), memori statis 83 MB.

## Penyimpangan GDD

Tidak ada. Yang paling perlu diketahui: D-066 (rumus dorongan ikan, tidak ada di GDD), D-067 (batas tekan berupa token bucket), D-068 (temuan balance).

## Prasyarat Milestone 6 — Dance + Procedural Music Engine

- Mesin musik prosedural dengan jam lagu yang authoritative (`AudioManager.get_authoritative_song_time_sec()` masih mengembalikan 0).
- `dance.tscn` sesuai Section 168.9, `DanceController` sesuai Section 169.13.
- Black Coffee hanya mengubah kecepatan visual (`UpgradeEffects.coffee_speed_multiplier()` sudah ada).
- Kalibrasi ritme sudah tersimpan di setting (`rhythm_input_offset_ms`).
