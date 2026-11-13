# Laporan Milestone 3 — Market, Economy, Upgrades, Book, Records

Format mengikuti GDD Section 191.15.

## Ringkasan

| | |
|---|---|
| Milestone | 3 — Market, Economy, Upgrades, Book, Records |
| Branch | `milestone/03-market-progression`, dibuat dari `milestone/02-fishing-core` (commit lokal, belum di-merge ke `main`) |
| Tag | belum dibuat; `v0.3.0-m3` dibuat setelah merge disetujui |
| Engine | Godot 4.7.2 stable, renderer Compatibility |
| Versi project | `0.3.0` |
| Save schema berubah | tidak. Semua field yang dipakai sudah ada di schema v5 |
| Penyimpangan GDD | tidak ada. Hal yang tidak diatur GDD dicatat sebagai D-041 sampai D-052 |

Milestone 2 juga belum di-merge. Branch ini berisi keduanya; keputusan merge dan tag untuk `v0.2.0-m2` dan `v0.3.0-m3` menunggu pemilik project.

## Exit gate

| Syarat (GDD Section 181) | Hasil | Bukti |
|---|---|---|
| Fish can become cash only via sale | lulus | `market.test_a_catch_is_not_cash_until_it_is_sold`; `market.test_only_the_market_adds_cash` memindai seluruh script dan hanya menemukan `GameState.add_cash(` di `market_controller.gd`; `boot.test_market_visit_in_the_real_scene` |
| Upgrade/debt math exact | lulus | `market.test_sale_values_are_exact`, `test_all_upgrade_prices_and_the_level_cap`, `test_debt_payment_is_capped_by_cash`, `test_debt_cannot_be_overpaid`, `test_paying_everything_reaches_the_finale_without_arowana` |
| Market P0 tests pass | lulus | MKT-001 sampai MKT-011 otomatis; 24 test suite `market` dan 4 test scene asli di suite `boot`; tabel ID di bawah |
| Save/reload preserves everything | lulus | `market.test_market_session_round_trips_through_the_save`, `test_story_queue_survives_save_and_load`; isi file save diperiksa setelah kunjungan di scene asli |

## Yang dikerjakan

**Aturan Market** (`scripts/gameplay/market/`)

- `MarketController` dengan API Section 169.12: `get_sell_preview`, `sell_all`, `sell_category`, `purchase_upgrade`, `pay_debt`, `leave_market`. Urutan transaksi mengikuti Section 171.13 dan setiap transaksi langsung disimpan.
- Pratinjau penjualan dan pembayaran memakai perhitungan yang sama, jadi angka di layar selalu sama dengan uang yang diterima. Don Arowana menampilkan rumusnya: `Rp 240,000 x BOSS 1.25 = Rp 300,000`.
- Pembayaran hutang dibatasi cash dan sisa hutang. Kunci 250 ms setelah transaksi membuat tap ganda tidak berbahaya.
- `UpgradeEffects` menghitung efek tiap level dari config balance yang sama dengan yang dibaca gameplay, lalu menuliskannya untuk toko.

**Antrean cerita** (`autoload/story_director.gd`, `data/story/`)

- 13 `StoryEvent`: enam milestone hutang, hutang lunas, kemenangan pertama atas Arowana, dan lima event di luar Market.
- Trigger dievaluasi setelah setiap transaksi dan memakai lifetime debt paid, bukan saldo (Section 80).
- Saat LEAVE MARKET, paling banyak satu event dipilih menurut prioritas; sisanya menunggu kunjungan berikutnya. Antrean ikut tersimpan.
- Cutscene belum ada. Event langsung diselesaikan agar unlock-nya berlaku; `story_debt_600k` membuka Fish Book dan diumumkan lewat dialog singkat.

**Scene dan UI**

- `market.tscn` sesuai blueprint Section 168.5.
- `MarketHud`: header dengan cash yang menghitung naik-turun, lima tab dengan urutan Section 167.9, satu halaman terbuka, tombol LEAVE MARKET, dan petunjuk tutorial. Ledger di kanan pada landscape dan di bawah pada portrait.
- Halaman: `MarketSellPanel`, `MarketUpgradePanel`, `MarketDebtPanel`, `MarketFishBookPanel`, `MarketRecordsPanel`, semuanya turunan `MarketPanel` (judul, isi yang bisa digulir, deretan tombol tetap).
- `ReceiptOverlay` menampilkan rincian setelah penjualan.
- Tutorial kunjungan pertama dengan teks final Section 183.20 dan pembayaran Rp 10,000.
- `MarketWorld`: menaruh Bu Yati dan Darto di marker set, memilih kamera sesuai bentuk layar, memutar kipas, dan memainkan reaksi Bu Yati.
- Pause, auto-pause saat kehilangan fokus, dan penyimpanan saat app masuk background bekerja seperti di danau.

**Aset hasil generator**

- Bu Yati: rig 18 tulang, lima clip Section 172.8. Darto mendapat clip `market_idle`.
- Sembilan prop warung: meja, timbangan, freezer, termos, toples, kursi plastik, lampu gantung, papan harga, kipas.
- `env_market_set.tscn`: warung beratap seng, tanah padat, pohon, garis bukit di kejauhan, lampu warung, dan marker posisi serta kamera.
- Enam potret Fish Book 512×288 berlatar transparan.
- Lembar referensi baru: `ref_chr_bu_yati.png`, `ref_set_market.png`, `ref_set_market_portrait.png`.

**Audio**

- `ui_sell`, `ui_purchase`, `ui_debt_ding` dengan tiga resep sintesis baru.
- Ambience warung: radio, dengung freezer, angin. `AmbienceEngine` sekarang menyusun lapisan per tempat dan merender loop warung selagi pemain masih di danau.

## File

328 file di folder project: 94 script `.gd`, 57 resource `.tres`, 30 scene `.tscn`, 3 shader, 13 PNG.

**Ditambahkan**

| Folder | File |
|---|---|
| `scripts/gameplay/market/` | `market_controller.gd`, `market_scene.gd`, `upgrade_effects.gd` |
| `scripts/actors/` | `market_world.gd` |
| `scripts/ui/` | `market_hud.gd`, `receipt_overlay.gd`, `hud_chip.gd` |
| `scripts/ui/market/` | `market_panel.gd`, `sell_panel.gd`, `upgrade_panel.gd`, `debt_panel.gd`, `fish_book_panel.gd`, `records_panel.gd` |
| `scenes/market/` | `market.tscn` |
| `shaders/` | `ui_silhouette.gdshader` |
| `data/story/` | 13 file `story_*.tres` |
| `data/audio/` | `ui_sell.tres`, `ui_purchase.tres`, `ui_debt_ding.tres` |
| `generated/` | `chr_bu_yati.tscn`, `env_market_set.tscn`, 9 prop, 6 potret, 3 lembar referensi |
| `tests/suites/` | `test_market.gd` |
| `docs/milestone_reports/` | `m03_market.md` |

**Diubah**

`project.godot` (versi), `autoload/story_director.gd` (ditulis ulang), `autoload/audio_manager.gd`, `autoload/debug_service.gd`, `scripts/audio/ambience_engine.gd` (ditulis ulang), `scripts/audio/sfx_renderer.gd`, `scripts/gameplay/data_validator.gd`, `scripts/gameplay/game_data.gd`, `scripts/ui/boot_controller.gd`, `scripts/ui/fishing_hud.gd`, `data/dialogue/ui_text.tres`, 6 file `data/fish/*.tres`, `tools/generators/character_builder.gd`, `environment_builder.gd`, `prop_builder.gd`, `generator_io.gd`, `reference_sheet_generator.gd`, `tests/run_all.gd`, `tests/suites/test_assets.gd`, `test_audio.gd`, `test_boot_flow.gd`, `test_services.gd`, `README.md`, `README_TESTING.md`, `CHANGELOG.md`, `docs/implementation_decisions.md`.

Daftar lengkap: `git diff --stat milestone/02-fishing-core...milestone/03-market-progression`.

## Aset hasil generator

46 entri di `generated/manifests/generator_manifest.json`: 34 dari generator headless (naik dari 23) dan 12 dari perender referensi (6 lembar referensi, 6 potret).

- Baru: `chr_bu_yati`, `env_market_set`, 9 prop Market, 6 `tex_fishbook_*`, 3 lembar referensi.
- Berubah: `chr_darto` (clip `market_idle`), `ref_set_lake.png` (dirender ulang).
- Generator headless dijalankan dua kali berturut-turut dan menghasilkan manifest yang identik.

Potret dan lembar referensi dirender dengan GPU, jadi bisa berbeda tipis antar mesin. Checksum di manifest mencatat file yang di-commit.

## Test

Perintah: `godot --headless --path . --script res://tests/run_all.gd` — exit code 0, 81 detik.

| Suite | Lulus | Gagal |
|---|---:|---:|
| data | 14 | 0 |
| state | 13 | 0 |
| save | 21 | 0 |
| rng | 6 | 0 |
| audio | 13 | 0 |
| services | 14 | 0 |
| fishing | 25 | 0 |
| market | 24 | 0 |
| assets | 10 | 0 |
| boot | 14 | 0 |
| **Total** | **154** | **0** |

ID matriks QA Section 180 yang tercakup otomatis:

| ID | Test |
|---|---|
| MKT-001, MKT-002, MKT-003 | `market.test_sale_values_are_exact` (ikan, Arowana 240k × 1.25 = 300k, sampah) |
| MKT-004 | `market.test_sell_all` |
| MKT-005 | `market.test_category_sell_removes_only_that_category` |
| MKT-006 | `market.test_upgrade_needs_enough_cash` |
| MKT-007, MKT-008 | `market.test_all_upgrade_prices_and_the_level_cap` |
| MKT-009 | `market.test_debt_payment_is_capped_by_cash` |
| MKT-010 | `market.test_debt_cannot_be_overpaid` |
| MKT-011 | `market.test_double_tap_does_not_repeat_a_transaction`; juga di scene asli |
| STORY-001, STORY-002 | `market.test_milestone_trigger_queues_once` |
| STORY-003 | `market.test_one_event_per_market_visit` |
| STORY-004 | `market.test_higher_priority_goes_first_and_the_other_waits`; `boot.test_leaving_the_market_announces_the_fish_book` |
| STORY-005, STORY-006, STORY-011 | `market.test_paying_everything_reaches_the_finale_without_arowana` |
| STORY-007 | `market.test_fish_book_unlocks_with_the_600k_milestone` (unlock bertahan saat event di-skip) |
| BOOK-001 | `market.test_fish_book_unlocks_with_the_600k_milestone`; halaman terkunci diperiksa di scene asli |
| BOOK-002, BOOK-003, BOOK-005 | `market.test_fish_book_and_record_counters` |
| BOOK-004 | `market.test_big_one_is_rare_and_always_in_the_top_tenth` (40.000 roll) |

Di luar matriks: `market.test_failed_autosave_is_reported_and_state_is_kept` (Section 171.13), `test_only_the_market_adds_cash`, `test_shop_shows_real_effects` (Section 78), `test_story_queue_survives_save_and_load`, `test_story_data_is_valid`, `assets.test_fish_book_portraits_are_rendered`.

Belum tercakup dan bukan bagian milestone ini: STORY-008 dan STORY-012 (rantai ending dan postgame, Milestone 8). MKT-012 dan BOOK-006 adalah pemeriksaan manual; struk dan siluet sudah dilihat di screenshot, tetapi belum dinilai manusia.

Test scene asli yang baru di suite `boot`: blueprint Section 168.5; satu kunjungan penuh lewat tombol asli (jual → struk → tab Debt → bayar Rp 10,000 → beli umpan → LEAVE MARKET → isi save); pemberitahuan Fish Book saat keluar; pause dan tata letak 1280×720 serta 720×1280.

## Pemeriksaan manual

Build debug berjendela di Windows (NVIDIA RTX 3050 Laptop), diperiksa lewat screenshot:

- Kelima tab di 1280×720: SELL dengan baris boss, UPGRADES, DEBT dengan PAY CUSTOM terbuka, FISH BOOK dengan entri terbuka dan siluet, RECORDS.
- SELL, DEBT, dan FISH BOOK di jendela portrait (720 lebar).
- Struk penjualan dan pergantian petunjuk tutorial.
- Lembar referensi Bu Yati, set Market landscape dan portrait, dan keenam potret.

Dua hal ditemukan dan diperbaiki dari screenshot: halaman DEBT terlalu penuh di 720p saat PAY CUSTOM terbuka, dan petunjuk tutorial di portrait muncul di tengah ledger.

**Belum diperiksa:**

- **Suara belum didengarkan.** Tiga SFX dan ambience warung hanya diverifikasi lewat angka (tanpa NaN, tidak clipping, panjang loop, chime lebih pelan daripada gigitan). Apakah radio enak didengar atau mengganggu harus dinilai manusia.
- **Rasa bermain belum diuji manusia.** Semua kunjungan dijalankan test atau langkah command line.
- Animasi Bu Yati dan putaran kipas belum ditonton bergerak; yang diperiksa hanya pose di screenshot.
- Navigasi keyboard dan gamepad di ledger belum dicoba dengan tangan. Tombol bisa difokus dan fokus awal diatur, tetapi urutan fokus antar halaman belum dinilai.
- Tata letak portrait diperiksa pada jendela 720×1055 (layar pengembang tidak cukup tinggi untuk 720×1280) dan lewat test headless di 720×1280.
- Build Web dan Android belum ada.

## Masalah yang diketahui

Tidak ada P0 atau P1 yang diketahui.

- P2: Fish Book hanya bisa terisi lewat tool debug, karena duel baru ada mulai Milestone 4. Halamannya sendiri sudah berfungsi.
- P2: motor Bu Yati (Section 72) belum ada; menyusul bersama motor Darto di Milestone 9.
- P2: celemek Bu Yati adalah dua panel kaku yang sedikit terangkat dari badannya bila dilihat dari samping.
- P2: mata ikan di beberapa potret kecil dan sulit terbaca pada ukuran 144 px.
- P2: halaman UPGRADES dan RECORDS perlu digulir di 720p; tidak semua item terlihat sekaligus.
- P2: banter Market (Section 183.17) dan dialog tutorial Darto–Bu Yati (Section 183.5) menunggu sistem dialog.
- P2: `ref_set_lake.png` berubah setiap kali dirender ulang, karena shader air dan dedaunan bergantung waktu. Isinya tetap danau yang sama.
- P2: belum ada musik di Market; mesin musik prosedural adalah Milestone 6.
- Dari milestone sebelumnya dan masih berlaku: tab How To Play di portrait bisa melebihi lebar panel; joran kaku; aksesori khas lima ikan selain lele belum ada.
- Test: peringatan `ObjectDB instances were leaked at exit` kadang muncul di akhir suite `boot`. Hanya terjadi di test.

## Performa

Market di 1280×720, vsync mati, mesin pengembang: sekitar 330 FPS, 103 draw call, 846 objek, memori statis 84 MB. Generator headless selesai dalam 4 detik. Suite test selesai dalam 81 detik. Ini bukan pengukuran perangkat target; profil resmi mengikuti Section 190 di Milestone 9.

## Penyimpangan GDD

Tidak ada. Keputusan untuk hal yang tidak diatur GDD ada di `docs/implementation_decisions.md` (D-041 sampai D-052). Yang paling perlu diketahui pemilik project:

- **D-041**: selama Story scene belum ada, event cerita langsung diselesaikan saat keluar Market agar unlock-nya berlaku. Adegannya sendiri belum bisa ditonton.
- **D-044**: GDD memberi dua urutan transaksi (Section 169.12 dan 171.13). Yang dipakai 171.13: trigger cerita dievaluasi sebelum autosave.
- **D-045**: PAY CUSTOM memakai tombol langkah, bukan kolom ketik. PAY ALL AVAILABLE tidak meminta konfirmasi.
- **D-048**: `Lifetime Fish Sales` menghitung seluruh penjualan, termasuk sampah.
- **D-049**: papan harga dan spanduk warung tanpa tulisan.

## Prasyarat Milestone 4 — Boxing Complete

- Keputusan merge: `milestone/02-fishing-core` dan `milestone/03-market-progression` ke `main`, dengan tag `v0.2.0-m2` dan `v0.3.0-m3`.
- Scene tinju sesuai blueprint Section 168 dan kontrak duel Section 169.13. `FishingController` sudah merutekan ikan yang mendarat ke duel pertama yang tersedia begitu scenenya ada.
- `GameState.record_fish_win()` dan `record_fish_loss()` dipanggil dari hasil duel; Fish Book dan Records langsung menampilkannya.
- Herbal Tonic sudah bisa dibeli; `UpgradeEffects.tonic_max_hp()` memberi HP yang dijanjikan toko.
- Set tinju, sarung tinju, dan clip tinju Darto serta keenam ikan dari generator.
- SFX tinju Section 175.8 sebagai resep baru di `SfxRenderer`.
