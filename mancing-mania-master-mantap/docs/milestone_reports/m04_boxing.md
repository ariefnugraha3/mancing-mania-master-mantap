# Laporan Milestone 4 — Boxing Complete

Format mengikuti GDD Section 191.15.

## Ringkasan

| | |
|---|---|
| Milestone | 4 — Boxing Complete |
| Branch | `milestone/04-boxing`, dibuat dari `milestone/03-market-progression` (commit lokal, belum di-merge ke `main`) |
| Tag | belum dibuat; `v0.4.0-m4` dibuat setelah merge disetujui |
| Engine | Godot 4.7.2 stable, renderer Compatibility |
| Versi project | `0.4.0` |
| Save schema berubah | tidak |
| Penyimpangan GDD | tidak ada. Hal yang tidak diatur GDD dicatat sebagai D-053 sampai D-065 |

Milestone 2 dan 3 juga belum di-merge. Branch ini berisi ketiganya.

## Exit gate

| Syarat (GDD Section 181) | Hasil | Bukti |
|---|---|---|
| Catfish through Arowana can complete Boxing | lulus | `boxing.test_every_fish_can_be_beaten_and_can_win`: tiap ikan dikalahkan dengan dodge biasa dan dengan Perfect Dodge, dan tiap ikan mengalahkan pemain yang diam. `boot.test_first_catch_is_boxed_and_a_win_fills_the_bucket` menjalankannya di scene asli dari danau sampai ember |
| BOX P0 tests pass | lulus | BOX-001 sampai BOX-012 otomatis; tabel di bawah |
| No unreadable attack | lulus secara otomatis, belum dinilai manusia | `boxing.test_every_attack_is_telegraphed_for_its_full_time` (keenam ikan: setiap impact didahului telegraph sepanjang `boxing_telegraph_sec` dengan arah yang sama); clip ancang-ancang tidak pernah dipotong; arah ditunjukkan bentuk, posisi, dan tulisan. Keterbacaan bagi mata manusia (BOX-004 bagian manual, BOX-014) belum diuji |

## Yang dikerjakan

**Aturan** (`scripts/gameplay/boxing/`, `scripts/gameplay/duel/`)

- `BoxingController` dengan API Section 169.13 (`start_duel`, `request_dodge`, `request_attack`, `get_snapshot`), berjalan dalam tick tetap 1/120 detik dan sepenuhnya ditentukan seed duel.
- Siklus ikan: jeda acak (1,2–2,1 detik; Don Arowana 0,95–1,65) → telegraph sepanjang nilai ikan itu → impact → jendela counter atau pemulihan.
- Dodge benar membuka counter 0,62 detik dengan damage 2,0×; dodge di 180 ms terakhir adalah Perfect Dodge: freeze 70 ms, counter 0,85 detik, damage 2,4×. Arah salah atau tanpa dodge berarti terkena.
- Jab 11 (0,11 + 0,25 detik) dan cross 18 (0,20 + 0,44 detik). Di luar jendela counter pukulan di-block dan hanya masuk 40%.
- HP pemain 100 + 25 per level Herbal Tonic. HP, serangan, dan telegraph ikan dari `FishData`.
- 60 detik; saat habis yang persentase HP-nya lebih tinggi menang; seri persis masuk sudden death.
- Hasil berbentuk kontrak Section 169.14. `DuelOutcome.commit()` adalah satu-satunya tempat hasil duel mengubah game.
- `BoxingBot` memainkan duel untuk test dan QA tanpa kemampuan yang tidak dimiliki pemain.

**Scene dan UI**

- `boxing.tscn` sesuai blueprint Section 168.7.
- `BoxingWorld`: Darto dan ikan di marker set, clip serangan dimainkan tepat selama telegraph, miring Darto ditahan sampai pukulan lewat, freeze Perfect Dodge, percikan di titik pukulan, KO dan kemenangan.
- `BoxingHud`: bar HP, jam ronde, `TelegraphWidget`, banner, petunjuk pelajaran pertama, nama tombol keyboard, dan empat tombol sentuh.
- `DuelResultOverlay`: YOU WIN / THE FISH GOT AWAY dengan CONTINUE dan auto-continue 5 detik.
- Pause menghentikan jam ronde; kehilangan fokus otomatis mem-pause.
- Ikan yang mendarat di danau sekarang dibawa ke ring. Duel pertama adalah pelajaran: kalah hanya mengulang.

**Aset hasil generator**

- Tiap ikan: sarung tinju dan sepuluh clip tinju (`box_idle`, tiga serangan beserta cerminnya, `box_block`, `box_hit`, `box_ko`) dengan penanda `telegraph_start`, `impact`, `recovery_end`.
- Darto: sarung tinju dan sembilan clip Section 172.2, dengan `hit_frame` tepat di akhir startup jab dan cross.
- Prop: bangku pojok, tiang dan tali ring, matras.
- `env_boxing_set.tscn`: ring di tepi danau dengan lampu gantung, danau, dan tepi seberang.
- Lembar referensi `ref_set_boxing.png` dan `ref_set_boxing_portrait.png`.

**Audio**

- Tujuh SFX Section 175.8; `box_ko` memakai resep baru `tom_sequence`.

## File

360 file di folder project: 103 script `.gd`, 64 resource `.tres`, 35 scene `.tscn`, 3 shader, 15 PNG.

**Ditambahkan**

| Folder | File |
|---|---|
| `scripts/gameplay/boxing/` | `boxing_controller.gd`, `boxing_bot.gd`, `boxing_scene.gd` |
| `scripts/gameplay/duel/` | `duel_outcome.gd` |
| `scripts/actors/` | `boxing_world.gd` |
| `scripts/ui/` | `boxing_hud.gd`, `telegraph_widget.gd`, `duel_result_overlay.gd` |
| `scenes/boxing/` | `boxing.tscn` |
| `data/audio/` | 7 file `box_*.tres` |
| `generated/` | `env_boxing_set.tscn`, 3 prop tinju, 2 lembar referensi |
| `tests/suites/` | `test_boxing.gd` |
| `docs/milestone_reports/` | `m04_boxing.md` |

**Diubah**

`project.godot` (versi), `autoload/audio_manager.gd`, `autoload/debug_service.gd`, `scripts/audio/sfx_renderer.gd`, `scripts/gameplay/content_ids.gd`, `scripts/ui/boot_controller.gd`, `data/dialogue/ui_text.tres`, `tools/generators/fish_builder.gd`, `character_builder.gd`, `prop_builder.gd`, `environment_builder.gd`, `reference_sheet_generator.gd`, `tests/run_all.gd`, `tests/suites/test_assets.gd`, `test_audio.gd`, `test_boot_flow.gd`, `README.md`, `README_TESTING.md`, `CHANGELOG.md`, `docs/implementation_decisions.md`.

Daftar lengkap: `git diff --stat milestone/03-market-progression...milestone/04-boxing`.

## Aset hasil generator

52 entri di manifest: 38 dari generator headless (naik dari 34) dan 14 dari perender referensi.

- Baru: `env_boxing_set`, `prop_boxing_corner_stool`, `prop_boxing_ropes`, `prop_boxing_mat`, dua lembar referensi tinju.
- Berubah: keenam scene ikan (sarung tinju dan clip tinju), `chr_darto` (sarung tinju dan clip tinju), keenam potret Fish Book (tanpa sarung tinju), lembar referensi danau dan Market (dirender ulang).
- Generator headless dijalankan dua kali berturut-turut dan menghasilkan manifest yang identik.

## Test

Perintah: `godot --headless --path . --script res://tests/run_all.gd` — exit code 0, 132 detik.

| Suite | Lulus | Gagal |
|---|---:|---:|
| data | 14 | 0 |
| state | 13 | 0 |
| save | 21 | 0 |
| rng | 6 | 0 |
| audio | 14 | 0 |
| services | 14 | 0 |
| fishing | 25 | 0 |
| market | 24 | 0 |
| boxing | 20 | 0 |
| assets | 11 | 0 |
| boot | 18 | 0 |
| **Total** | **180** | **0** |

ID matriks QA Section 180.5:

| ID | Test |
|---|---|
| BOX-001, BOX-002 | `boxing.test_player_hp_follows_herbal_tonic` |
| BOX-003 | `boxing.test_jab_and_cross_values_and_timing` |
| BOX-004 (bagian otomatis) | `boxing.test_every_attack_is_telegraphed_for_its_full_time`; `boot.test_boxing_inputs_pause_and_both_screen_shapes` (clip ancang-ancang tidak terpotong) |
| BOX-005, BOX-009 | `boxing.test_correct_dodge_opens_a_counter_window` |
| BOX-006 | `boxing.test_wrong_or_missing_dodge_takes_the_hit`, `test_first_dodge_is_the_answer` |
| BOX-007, BOX-008 | `boxing.test_perfect_dodge_is_the_last_180_ms` |
| BOX-010 | `boxing.test_attack_without_an_opening_is_blocked` |
| BOX-011 | `boxing.test_timeout_compares_hp_share` |
| BOX-012 | `boxing.test_exact_tie_goes_to_sudden_death` |
| BOX-013 (bagian otomatis) | `boot.test_boxing_inputs_pause_and_both_screen_shapes`: empat kontrol tidak tumpang-tindih, di dalam safe area, di bawah area pertarungan |

Di luar matriks: determinisme seed dan rentang jeda serangan, kontrak hasil, controller tidak menyentuh ekonomi, override debug, commit menang/kalah/Arowana, kontrak animasi (`assets`), tujuh SFX (`audio`), blueprint scene, alur danau → ring → ember, dan pelajaran pertama (`boot`).

BOX-014 dan bagian manual BOX-004 serta BOX-013 belum dinilai manusia.

## Pemeriksaan manual

Build debug berjendela di Windows (NVIDIA RTX 3050 Laptop), diperiksa lewat screenshot:

- Ring di 1280×720: kuda-kuda, telegraph dengan chevron dan bar, Darto miring, ikan menerjang, layar YOU WIN.
- Ring di jendela portrait: empat tombol di bawah, HP dan penunjuk arah di atas, PERFECT DODGE.
- Lembar referensi set tinju landscape dan portrait.

Dari screenshot, tiga hal diperbaiki: tali ring di sisi kamera melintang di depan pertarungan (dihapus), matras terlalu terang, dan kamera terlalu jauh dari ikan.

**Belum diperiksa:**

- **Belum dimainkan manusia.** Semua pertarungan dijalankan bot atau test. Apakah telegraph 0,51 detik Don Arowana bisa dibaca dan dijawab tangan manusia belum diketahui; bot bereaksi dalam satu tick.
- **Animasi belum ditonton bergerak.** Yang dilihat hanya pose di beberapa frame. Apakah tiga variasi serangan terlihat berbeda dan arahnya terbaca dari gerakannya saja belum dinilai.
- **Suara belum didengarkan**, hanya diperiksa lewat angka.
- Kontrol sentuh belum dicoba di perangkat sentuh.
- Tata letak portrait dilihat pada jendela 720×1055 dan diuji headless di 720×1280.
- Build Web dan Android belum ada.

## Masalah yang diketahui

Tidak ada P0 yang diketahui.

- **P1 (balance): menekan JAB terus-menerus tanpa menghindar mengalahkan empat ikan pertama 20 dari 20 kali**, dalam waktu yang hampir sama dengan bermain benar. Hanya Snakehead Sergeant (13/20) dan Don Arowana (0/20) yang menghukumnya. Ini mengikuti angka GDD (block 40%, tanpa hukuman lain) tetapi bertentangan dengan niat Section 41. Tidak diubah; rinciannya di D-058 dan perlu keputusan pemilik project.
- P2: pertarungan singkat (6–14 detik dengan bermain benar) dibanding ronde 60 detik. Jam hampir tidak pernah berperan.
- P2: ikan kecil di layar dibanding Darto, terutama lele.
- P2: gerak khas spesies baru berupa tempo kuda-kuda; aksesori khas lima ikan selain lele belum ada (Milestone 7).
- P2: belum ada reaksi kemenangan khusus untuk ikan; saat menang ia kembali ke kuda-kuda.
- P2: telegraph tidak punya isyarat suara.
- P2: opsi menukar kelompok tombol untuk kidal (Section 189.12) belum ada.
- P2: dialog Catfish di duel pertama dan Wheel belum ada (Milestone 8 dan 7).
- P2: belum ada musik tinju (Milestone 6).
- Dari milestone sebelumnya dan masih berlaku: motor Darto dan Bu Yati, banter Market, tab How To Play di portrait, lembar referensi berubah tiap render.
- Test: peringatan `ObjectDB instances were leaked at exit` kadang muncul di akhir suite `boot`.

## Performa

Ring di 1280×720, vsync mati, mesin pengembang: sekitar 425 FPS, 76 draw call (target Section 190: ≤160), 790 objek, memori statis 83 MB. Generator headless selesai dalam 5 detik. Suite test selesai dalam 132 detik; watchdog dinaikkan dari 180 ke 300 detik.

## Penyimpangan GDD

Tidak ada. Keputusan untuk hal yang tidak diatur GDD ada di `docs/implementation_decisions.md` (D-053 sampai D-065). Yang paling perlu diketahui pemilik project:

- **D-058**: temuan balance di atas.
- **D-054**: dodge pertama selama telegraph adalah jawaban dan tidak bisa diperbaiki.
- **D-055**: jendela counter bisa memuat lebih dari satu pukulan; di luar jendela ikan selalu mem-block.
- **D-059**: ikan berdiri di atas bangku dan kamera berada di belakang-kanan Darto.
- **D-061**: Wheel dan Result scene belum ada, jadi ikan langsung ditinju dan hasilnya tampil sebagai overlay.

## Prasyarat Milestone 5 — Arm Wrestling Complete

- Keputusan merge untuk `milestone/02` sampai `milestone/04`, dan keputusan atas D-058.
- `arm_wrestle.tscn` sesuai Section 168.8 dan `ArmWrestleController` sesuai Section 169.13.
- Selama Wheel belum ada, perlu cara memilih duel: `FishingController` sekarang mengambil duel pertama yang tersedia, yaitu tinju. Dengan dua duel, pilihannya harus dari RNG duel atau dipaksa lewat debug.
- `DuelOutcome`, `DuelResultOverlay`, dan pola pelajaran pertama bisa dipakai ulang apa adanya.
- Clip panco untuk Darto dan keenam ikan, meja panco, dan bantalan siku dari generator.
- Herbal Tonic sudah menaikkan stamina di `UpgradeEffects.tonic_stamina_multiplier()`.
