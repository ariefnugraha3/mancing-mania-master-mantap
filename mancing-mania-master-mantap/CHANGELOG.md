# Changelog

Format mengikuti Semantic Versioning (GDD Section 186.2). Tag milestone mengikuti GDD Section 191.3.

## Unreleased — Revisi Nama 6.8: Catch and Brawl

Status: **IMPLEMENTATION COMPLETE — QA NOT YET PASSED**; masuk ke `1.0.0-rc.2`. Detail authoritative: GDD header revisi 6.8.

### Diubah

- Game berganti nama dari **Mancing Mania: Gelut Edition** menjadi **Catch and Brawl**, sama di mode English dan Bahasa Indonesia.
- Logo menu dan layar boot kini satu baris "CATCH AND BRAWL". Ukuran font mengecil sendiri bila tidak muat lebar layar, dan pita subjudul hanya muncul bila judul punya subjudul.
- Kartu judul prolog, kredit, dan kebijakan privasi (dalam game, `PRIVACY_POLICY.md`, `release/privacy_policy.html`) memakai nama baru.
- Nama proyek Godot, nama aplikasi di export preset, application ID Android dan bundle ID iOS menjadi `com.catchandbrawl.game`.
- Nama file build menjadi `CatchAndBrawl.aab`, `CatchAndBrawl.ipa`, dan `catch-and-brawl-web-<versi>.zip`.
- Contoh keystore di `README_BUILD.md` disesuaikan dengan nama baru.
- Emblem di atas judul digambar ulang. Versi lama berupa piringan matahari dengan ikan poligon datar yang tampak seperti placeholder. Versi baru adalah lencana bergaya stiker yang sama dengan ikon tombol: cincin terakota berjahit krem, langit senja dengan sunburst, danau, dan ikan oranye yang melompat dengan alis galak, sarung tinju merah, kail di bibir, bintang hantaman, dan percikan air (`IconPainter.EMBLEM`). Di menu, emblem diperbesar dari 20% menjadi 28% lebar layar.

### Ditambahkan

- Save dari folder data lama ("Mancing Mania Gelut Edition") disalin sekali ke folder baru saat game pertama kali dibuka dengan nama baru. Folder lama tidak diubah (`SaveManager.import_legacy_save`).

### Diperbaiki

- Atap rumah terbalik (berbentuk "V"): rumah di seberang Danau Cempaka, gedung koperasi dan sekolah di Waduk Melati, dan rumah panggung di Muara Anggrek. Kedua sisi atap pelana kini menurun ke arah lisplangnya masing-masing.
- Atap gedung lelang TPI di Dermaga Mawar terbalik dengan cara yang sama.
- Sandaran kursi plastik condong ke depan, menutupi dudukan. Kini bersandar ke belakang (Market, rumah, panggung joget, arena Tarik Tambang dan Panjat Pinang).

## Unreleased — Revisi Lokasi 6.7: empat tempat memancing berjenjang

Status: **IMPLEMENTATION COMPLETE — QA NOT YET PASSED**; masuk ke `1.0.0-rc.2` bersama revisi di bawah. Danau Cempaka tidak berubah. Detail authoritative: GDD Section 198.

### Ditambahkan

- **4 tempat memancing baru** yang terbuka bertahap: Sungai Kenanga (utang lunas Rp 300.000), Waduk Melati (Rp 600.000), Muara Anggrek (Rp 1.000.000), dan Dermaga Mawar (Rp 1.400.000). Setiap tempat punya set diorama, ambience, dan sifat air sendiri: arus yang menurunkan marker reel, air dalam dengan ikan lebih berat, pasang surut yang mengubah peluang sampah, dan ombak yang menambah tegangan senar.
- **20 ikan baru** (5 per tempat, termasuk 4 legenda baru), masing-masing dengan model, aksesori khas, potret Fish Book, dialog pertemuan pertama, dan dialog duel dalam English dan Bahasa Indonesia.
- **4 duel baru**: Silat (ulangi urutan jurus), Tarik Tambang (tarik di zona hijau), Adu Gasing (bidik, tenaga, lalu adu tepat waktu), dan Panjat Pinang (kiri-kanan bergantian tanpa terburu-buru). Setiap duel punya arena, HUD portrait, tutorial, bot QA, tab How to Play, dan baris Records.
- **Wheel of Fate per tempat**: duel khas tempat itu 50%, dua duel lama masing-masing 25%.
- **Perlengkapan perjalanan** di Market → UPGRADES → TRAVEL GEAR (Kail Arus, Senar Panjang, Sepatu Lumpur, Joran Laut).
- **Peta WHERE TO?** dari chip peta di HUD memancing, chip pasang/surut di Muara Anggrek, dan kalimat kedatangan Darto di setiap tempat baru.
- **Event cerita pembuka tempat** yang menjelaskan mengapa semua ikan tetap dijual ke Bu Yati (kontrak van putih, timbangan jujur, koperasi dan lelang yang menolak, kenangan ayah Rini).
- Fish Book dikelompokkan per tempat dengan label LEGENDA. Records menambah 4 jenis kemenangan duel baru, Legends Defeated, dan Spots Visited.
- Ikon peta dan panah bawah, ambience sungai/waduk/muara/laut, serta state musik untuk duel baru.
- Argumen debug `--mm-location=<id>`; `reference_sheet_generator.gd` menerima `-- --only=<kata,...>`.

### Diubah

- Save schema naik ke **version 6** (file tetap `save_v5.json`) dengan migrasi otomatis dari version 5: blok `locations`, statistik dan tutorial baru, serta 20 ikan baru di Fish Book, Bucket, dan `duel_wins`.
- `ContentIds`: 26 ikan, 8 duel, 5 tempat. Set diorama menjadi 15.
- Adegan memancing dan hasil duel memakai set tempat yang sedang dikunjungi.
- Memuat save lama yang hanya dimigrasi kini membuat satu backup (`pre_migration`), bukan dua.

### Diperbaiki

- Layar hasil duel: baris "<IKAN> ADDED TO BUCKET" terpotong di sisi kanan layar HP bila nama ikannya panjang. Judul dan detail kini membungkus ke baris berikutnya dan detail selalu tepat di bawah judul.
- Prolog: pada adegan judul di jalan tepi danau, Rini ikut muncul dan bertumpuk dengan Darto di titik memancing. Set kedua sebuah event kini tidak memunculkan ulang pemeran set pertama; hanya Darto yang ada di danau.
- Prolog: di HP sempit, baris kedua judul "MANCING MANIA: GELUT EDITION" menimpa subjudul "SUNDAY — 3:17 PM". Subjudul kini selalu berada di bawah baris terakhir judul.

## Unreleased — Revisi Bahasa 6.6: English dan Bahasa Indonesia

Status: **IMPLEMENTATION COMPLETE — QA NOT YET PASSED**; masuk ke `1.0.0-rc.2` bersama revisi di bawah. Gameplay, balance, dan urutan cerita tidak berubah.

### Ditambahkan

- **Bahasa Indonesia** lengkap. Semua 715 teks UI, cerita, dialog ikan, credits, dan kebijakan privasi diterjemahkan, ditambah nama ikan, upgrade, sampah, dan dialog pertemuan pertama (`data/dialogue/ui_text_id.tres`).
- Settings → **LANGUAGE** (baris paling atas) dengan nilai OTOMATIS (ikut bahasa perangkat, default), ENGLISH, atau INDONESIA. Dari Main Menu, menu langsung dimuat ulang dalam bahasa baru.
- Setting save `language` (default `auto`). Save lama tanpa setting ini diisi default tanpa dianggap rusak.
- Format angka per bahasa: `Rp 1,800,000` / `Rp 1.800.000`, `2.92 kg` / `2,92 kg`, `3:17 PM` / `15.17`.
- `TextDb.set_language()`, `get_language()`, `text_or()`, `get_table()`; `DisplaySettings.apply_language()` / `resolve_language()`; `FishData.get_display_name()` / `get_species_label()`, `TrashData.get_display_name()`, `UpgradeData.get_display_name()`; `Money.decimal()`; `FishDialogue.line_key()`.
- Argumen debug `--mm-language=<auto|en|id>` (tidak pernah tersimpan).
- Test: tabel Indonesia lengkap dan placeholder cocok; tiap bahasa memakai namanya sendiri; setting bahasa mengikuti perangkat; save lama tanpa `language` tidak dianggap rusak; tombol penting utuh dalam kedua bahasa (total 279 test).

### Diubah

- **Mode English** kini memakai nama Inggris untuk tempat dan permainan:
  - "BU YATI'S WARUNG" → "MARKET";
  - "Danau Cempaka" → "Cempaka Lake";
  - "Suwit" → "Rock Paper Scissors";
  - "kendang" → "drums";
  - label spesies tanpa nama lokal ("CATFISH / LELE" → "CATFISH").
- **Mode Indonesia** memakai nama lokal: Warung Bu Yati, Danau Cempaka, Tinju Empang, Panco Maut, Joget Koplo, Suwit.

## Unreleased — Revisi Ponsel 6.5: ponsel cerita menjadi aplikasi chat

Status: **IMPLEMENTATION COMPLETE — QA NOT YET PASSED**; masuk ke `1.0.0-rc.2` bersama revisi di bawah. Naskah, urutan cerita, dan save tidak berubah.

### Diubah

- Ponsel di adegan cerita (intro, chat Rini, telepon Nisa dan Rini, pelunasan) kini berupa aplikasi chat dengan tata letak yang familiar (`ChatPhone`):
  - status bar dan punch-hole kamera;
  - header teal dengan avatar, nama, dan status;
  - wallpaper doodle;
  - bubble berekor dengan jam dan centang baca;
  - kolom ketik pesan dan tombol mikrofon.
- Intro: saldo dan total utang tampil sebagai kartu akun, dan pengingat bayar tampil sebagai pesan dari akun bisnis CepatCash bercentang emas.
- Telepon tampil sebagai layar panggilan suara dengan avatar berdenyut, durasi berjalan, dan tombol tutup merah.
- Nama kontak di ponsel ditulis dengan kapital di awal saja ("Rini", "Nisa"). Status panggilan berubah dari "CALLING..." menjadi "Voice call".

### Ditambahkan

- `scripts/ui/chat_phone.gd` (`ChatPhone`); `StoryUi.get_phone()`; parameter id pengirim/penelepon di `StoryUi.show_chat()` dan `show_call()`.
- Teks `story.phone.cepatcash`, `online`, `business`, `today`, `clock`, `time`, `input`.
- Test: intro membuka chat CepatCash dengan kartu saldo dan utang lalu pesan pengingat; kontak lain membuka thread baru; Darto di kanan; telepon membuka layar panggilan.

### Dihapus

- Node `NotificationPanel`/`Lines` di `story.tscn` (diganti `ChatPhone` yang dibuat `StoryUi`).

### Diperbaiki

- Sudut ponsel tidak lagi menampilkan kotak lancip gelap. Layar kini dipotong dengan masker rounded-rect (`clip_children`), bukan ditutup potongan warna bodi yang ujungnya mencuat keluar dari lengkung bodi.

## Unreleased — Revisi Ikon 6.4: ikon stiker penuh warna

Status: **IMPLEMENTATION COMPLETE — QA NOT YET PASSED**; masuk ke `1.0.0-rc.2` bersama revisi di bawah. Gameplay, layout, dan save tidak berubah.

### Diubah

- Semua 31 ikon (`IconPainter`) digambar ulang sebagai ilustrasi stiker penuh warna: outline cocoa, bibir gelap di bawah, dan kilau krem. Contohnya uang kertas dengan koin, ember berisi ekor ikan, warung beratap belang, gear dengan baut emas, gamepad, buku terbuka berpita, clipboard utang, piala berbintang, sarung tinju tegak, ikan bermata, dan pintu keluar dengan panah. Ini berlaku di semua tombol, tab Market, chip HUD, dan tombol tinju.
- Tangan Suwit (batu, gunting, kertas) kini ikon stiker berwarna kulit dengan lengan baju. Langkah asli hasil Charm ditandai cahaya teal (`MoveIcon.highlighted`), bukan lagi warna tangan.
- Ikon PLAY menjadi tombol play bulat (cakram emas, segitiga krem).
- Warna ikon tombol di theme menjadi putih (ikon tampil dengan warnanya sendiri). Ikon tombol disabled digambar pudar dan kurang jenuh. Generator theme `ui_art_builder` naik ke versi 4.
- Badge chip HUD memakai versi pastel dari warnanya, dan ikonnya sedikit lebih besar.

### Ditambahkan

- `IconPainter.ALL`, `commands_for()`, `icons_with_holes()`; ikon `ROCK`, `SCISSORS`, `PAPER`. Geometri tiap ikon dihitung sekali (±50 ms untuk semua ikon) lalu di-cache bersama triangulasinya.
- Test: setiap ikon berwarna dan beroutline, tidak ada celah yang tertutup jadi gumpalan, tombol menampilkan ikon dengan warna aslinya dan memudarkannya saat disabled.

## Unreleased — Revisi Font 6.3: Fredoka + Chewy

Status: **IMPLEMENTATION COMPLETE — QA NOT YET PASSED**; masuk ke `1.0.0-rc.2` bersama revisi di bawah. Gameplay, balance, cerita, audio, art 3D, layout, dan save tidak berubah.

### Diubah

- Semua teks game kini memakai dua font gratis yang boleh dikomersialkan, menggantikan font bawaan Godot: **Fredoka** (SIL OFL 1.1) untuk teks badan, dialog, tombol, header, dan HUD (bobot 500 dan 600), serta **Chewy** (Apache 2.0) untuk logo, judul, pita judul, dan teks "cat papan" (banner duel, PERFECT/MISS, Result, Wheel, credits, judul warung, tanda gigitan "!").
- Tombol Privacy "ENGINE LICENSES" menjadi "LICENSES". Halamannya kini juga memuat kredit dan teks lisensi lengkap kedua font.
- `AssetPolicyScan` mengizinkan tepat dua font ini, dan hanya bila file lisensinya ada. Font lain tetap ditolak.
- Generator theme `ui_art_builder` naik ke versi 3.

### Ditambahkan

- `assets/fonts/`: `Fredoka-Variable.ttf`, `Fredoka-OFL.txt`, `Chewy-Regular.ttf`, `Chewy-LICENSE.txt`. Ketiga preset export memaketkan `assets/fonts/*.txt`.
- `UiTokens.FONT_*` (file, lisensi, bobot); `UiSkin.regular_font()`, `make_body_font()`, `make_display_font()`.
- Test: cakupan glyph semua teks game di kedua font, font dan bobot theme, teks lisensi font di game, dan preset memaketkan lisensi font (total 273 test).

### Dihapus

- `UiSkin.make_bold()` (potongan tebal tiruan dari `variation_embolden`).

## Unreleased — Revisi Mobile 6.2: game HP portrait (Android & iOS, HP & tablet)

Status: **IMPLEMENTATION COMPLETE — QA NOT YET PASSED**; masuk ke `1.0.0-rc.2` bersama revisi UI dan visual di bawah. Gameplay, balance, cerita, audio, dan art tidak berubah.

### Diubah

- Game dikunci **portrait** dan ditata untuk HP dan tablet; layout landscape dihapus.
- Kanvas UI kini dalam *point* setara dp/pt: HP 390 pt lebar (tinggi mengikuti layar), tablet 600 pt; jendela yang lebih lebar dari 4:5 menampilkan kanvas portrait dengan bilah di samping. Tombol 48 pt kini benar-benar 48 dp / 44 pt di HP (sebelumnya kanvas 720 px membuat tombol ±26 pt dan teks ±10 pt di HP sungguhan).
- Safe area Android **dan iOS** (notch, Dynamic Island, status bar, home indicator, gesture bar) dihormati di semua layar; overlay berpusat di safe area, dialog cerita dan ponsel tidak lagi menempel ke tepi.
- Memancing: chip uang dan ember (ember kini ikon + jumlah) mengalir ke baris kedua bila sempit; baris jempol bawah berisi MARKET dan tombol CAST/STRIKE/REEL besar.
- Main Menu: emblem di atas judul yang menyesuaikan lebar layar; tombol menu selebar layar (maks. 400 pt) di zona jempol.
- Market: ledger menjadi bottom sheet; tab seperti tab bar HP (ikon di atas label); judul warung di barisnya sendiri; tombol Debt/Sell turun baris alih-alih terpotong; tombol aksi ikut digulir bila halaman terlalu pendek.
- Tinju: empat tombol jempol dengan ikon besar (panah ◀ ▶ untuk DODGE, sarung tinju untuk JAB/CROSS). Panco: bar tepat di atas MASH. Suwit: titik skor di baris sendiri, jarak antar pilihan 20 pt. Dance: lajur sebagai bottom sheet. Banner duel boleh dua baris.
- Settings: setiap volume menjadi nama + nilai di satu baris dan slider selebar panel di bawahnya.
- Kamera diorama hanya punya bingkai HP; tablet memperlihatkan dunia 1,25× lebih lebar. Inset HUD boleh berupa porsi tinggi layar untuk bottom sheet.
- Petunjuk menyebut tombol sentuh, atau tombol keyboard bila keyboard sedang dipakai.

### Ditambahkan

- Preset ekspor **iOS** (iPhone + iPad, iOS 14+, `build/ios/MancingManiaGelut.ipa`); platform save `ios`; PWA Web berorientasi portrait.
- `PlatformService`: `PHONE`/`TABLET`, `is_ios()`, `is_mobile()`, `is_tablet()`, `canvas_size_for()`, `aspect_mode_for()`, `set_simulated_insets()`, sinyal `safe_area_changed`.
- Argumen debug `--mm-insets=<kiri>,<atas>,<kanan>,<bawah>` untuk mensimulasikan notch dan home indicator.
- `GameButton.icon_pixels` dan `set_side_padding()`; `HudChip.add_stacked_content()`; `UiTokens.place_banner()`; ikon `ARROW_LEFT`, `ARROW_RIGHT`, `GLOVE`, `HAND`; `InputManager.is_keyboard_active()`.
- Test bentuk layar HP/tablet, simulasi inset, preset iOS (total 272 test).

### Dihapus

- Kelas tampilan `LANDSCAPE_WIDE`/`LANDSCAPE_COMPACT`, referensi 1280 × 720, dan semua cabang layout landscape.

## Unreleased — Revisi UI 6.1: "cozy warung card"

Status: **IMPLEMENTATION COMPLETE — QA NOT YET PASSED**; masuk ke `1.0.0-rc.2` bersama revisi visual di bawah. Gameplay, balance, cerita, audio, dan save tidak berubah.

### Diubah

- Palet UI mengikuti palet diorama (GDD 167.2): cream `#FFF9EE`/`#FCEFD6`, crust `#E0784C`, teal `#4F9A91`, cocoa `#3F2A1E`, plus token rim/lip/bayangan.
- Semua tombol menjadi tombol berlip yang tenggelam saat ditekan, dengan cincin fokus emas; varian baru Accent dan Round (tombol Pause bulat).
- Overlay (Pause, Settings, How to Play, Controls, Privacy, modal, Bucket, Receipt) menjadi kartu cream dengan pita judul crust dan animasi pop kecil.
- Main Menu: logo emblem bulat, judul bergaya cat papan, pita "GELUT EDITION" miring, tombol berikon yang muncul berurutan.
- Chip HUD (uang, ember, Market) memakai badge bulat berwarna berisi ikon; bar HP/stamina/strike/stress, timer duel, position bar, telegraph, track reel, dan titik Suwit memakai bentuk bulat yang sama.
- Market: tab map ledger, kartu ledger, slip upgrade dengan tag level emas, judul "BU YATI'S WARUNG" bergaya cat papan.
- Settings: header seksi berupa tab paper; tombol Pause/Settings/Close/How to Play/Result/Market memakai ikon.
- Dance: lajur bulat bernuansa warna, penerima nada, key cap, nada berbayangan yang memudar masuk; skor tebal berwarna.
- Wheel: roda kayu dicat dengan rim cream, pasak, hub matahari, pin penunjuk crust, palet UI, nama duel yang muat di segmennya.
- Dialog dan ponsel cerita: kartu cream, name tag crust, panah lanjut yang memantul, ponsel mainan bertubuh cocoa.
- Semua teks melayang di atas scene memakai potongan tebal dengan outline dan bayangan; judul besar (Result, Wheel, banner duel, credits) bergaya cat papan.

### Ditambahkan

- `scripts/ui/ui_skin.gd`, `icon_painter.gd`, `icon_texture.gd`, `logo_emblem.gd`, `advance_arrow.gd`; `GameButton.icon_id`; `HudChip.style_bar()` dan `HudChip.timer_style()`.
- Dua test: gaya UI (lip, tenggelam, varian theme, font tanpa file, ikon) dan alias teks cerita (total 271 test).

### Diperbaiki

- Pesan chat cerita tidak lagi menampilkan kunci teks mentah (alias di `ui_text.tres` kini diikuti `TextDb`).
- Kartu dialog cerita tidak lagi terdorong keluar layar oleh baris panjang.
- Bayangan kartu yang terpotong menjadi pita persegi (How to Play, ponsel cerita).

## Unreleased — Revisi Visual 6.1: diorama "Warm, Cozy & Cute"

Status: **IMPLEMENTATION COMPLETE — QA NOT YET PASSED** untuk revisi ini; build berikutnya adalah `1.0.0-rc.2` setelah QA dan human playtest ulang (GDD Section 194.4). Gameplay, balance, cerita, audio, dan save tidak berubah; UI 2D dirombak terpisah (lihat entri di atas).

### Diubah

- Seluruh visual mengikuti `VISUAL_STYLE_GUIDE.md`: diorama mini low-poly yang bulat dan empuk, warna solid hangat tanpa tekstur, cahaya keemasan.
- Kamera: satu `DioramaCamera` ortografis (yaw 45°, pitch 35°, `KEEP_WIDTH`) di semua 11 scene, dibingkai lewat marker `CameraFocus` per set dan bar HUD.
- Darto, Rini, Nisa, Bu Yati dibuat ulang sebagai karakter chibi 0,90 m (kepala ±42%, mata manik, pipi merona, poni di atas alis, topi di atas poni), satu mesh ≤ 2.000 segitiga.
- Enam ikan dibuat ulang sebagai ikan mainan yang montok dengan mata besar, sirip empuk, dan aksesori khas yang lebih besar.
- 29 prop dibangun ulang dengan rounded slab, kapsul, dan lathe pada skala chibi (meja warung 0,42 m).
- Tujuh set menjadi diorama: kolam Danau Cempaka, warung dan rumah sebagai rumah boneka (dinding dekat 0,16 m, jendela bertirai kotak-kotak), ring, meja panco, panggung joget, dek Suwit.
- Cahaya per panduan: latar `#F5E6CA`, ambient `#FFE3A8` × 0,55, Filmic white 1,2, matahari (-52°, -135°) tanpa bayangan, lampu interior `#FFAA44`; titik kunci 17:36 untuk ending dan 18:00 untuk credits.
- Bayangan palsu (cakram lembut) di bawah karakter, ikan, perabot, dan pohon; tanpa shadow map, SSAO, glow, atau fog.
- Preset grafis: LOW 75% / tanpa MSAA, MEDIUM 2× MSAA, HIGH 4× (Android 2×); tidak ada level yang menyalakan bayangan.
- Napas idle 1,35 rad/s dan squash & stretch `TRANS_BACK` untuk reaksi (dimatikan oleh Reduced Motion).
- Data staging cerita (`data/story/story_timelines.json`): framing memakai marker fokus set dan offset layar, bukan posisi kamera dan FOV.
- Lembar referensi (21) dan potret Fish Book dirender ulang; store art diambil ulang.

### Ditambahkan

- `scripts/visual/`: `DioramaStyle` (palet, profil kamera, rig cahaya, material standar, waktu cahaya), `DioramaCamera`, `DioramaMotion`, `AmbientMotion`.
- `tools/generators/soft_mesh.gd` (primitif halus panduan 4.1) dan `diorama_kit.gd`.
- Material `mat_vertex_color_round`, `mat_metal_soft`, `mat_glow_warm`, `mat_glass`, `mat_fake_shadow`; mesh `mesh_shadow_character`, `mesh_shadow_furniture`.
- Lembar referensi baru: Rini, Nisa, lima ikan lain, motor.
- Empat test gaya visual di suite `assets` (total 269 test).

### Diperbaiki

- Lengan sirip ikan di panco kini direntangkan sepanjang sumbunya sendiri (sebelumnya `Basis.scaled()` menskalakan sumbu dunia).

### Dihapus

- `shaders/lake_water.gdshader`, `shaders/foliage_sway.gdshader`, materialnya, dan `tools/generators/mesh_builder.gd` (builder faceted lama).

## 1.0.0-rc.1 — Milestone 10: Balance, Full QA, Release Candidate

Status rilis: **V1.0 RELEASE CANDIDATE — HUMAN PLAYTEST PENDING** (GDD Section 192.1).

### Ditambahkan

- Simulasi balance Section 179 (`tools/sim/`): 100.000 lemparan encounter, sampah, dan Wheel dengan kode game; model ekonomi 25.000 sesi per profil dan 10.000 progresi per strategi upgrade; opsi `--value-scale` untuk menguji usulan tuning. Hasil di `docs/balance_report.md`.
- Export preset Web (single-threaded, itch.io) dan Android (AAB, `com.mancingmania.gelutedition`, API 24–36, arm64-v8a, tanpa permission).
- Build Web dan ZIP itch.io; smoke test Chromium.
- Layar Settings → PRIVACY AND LICENSES: ringkasan privasi, kebijakan lengkap, dan lisensi engine, semuanya offline.
- Peringatan di Web bahwa menghapus storage browser menghapus save.
- Store art dari game asli (`tools/generators/store_art_generator.gd`): ikon 512, layer ikon adaptive, feature graphic, lima screenshot ponsel.
- Validator rilis dan manifest checksum (`tools/release/release_tool.gd`).
- `README_BUILD.md`, `PRIVACY_POLICY.md`, `release/privacy_policy.html`, `LICENSES.md`, `release/publisher_metadata.example.json`, `docs/store_compliance_report.md`, `docs/known_issues.md`, `docs/playtest_report.md`, `docs/release_checklist_v1.0.md`.
- Suite test `release` (5 test).

### Diubah

- Versi `1.0.0-rc.1` (Android versionCode 9901).
- Scene joget menyiapkan audio sendiri bila dibuka tanpa Boot.

### Belum diubah (menunggu keputusan pemilik)

- Harga jual ikan (ekonomi ~3× lebih cepat dari target), tinju JAB terus-menerus, istirahat panco. Lihat `docs/balance_report.md` dan `docs/known_issues.md`.

## 0.9.0 — Milestone 9: Final Art, UI/UX, Animation, Audio, Accessibility, Performance

### Ditambahkan

- Settings: bagian VISUAL (grafis LOW/MEDIUM/HIGH, fullscreen di Web/desktop), ACCESSIBILITY (UI scale, text scale, High Contrast HUD, HUD shake, reduced motion, reduced flash, mode input panco, tangan dominan, kecepatan dialog, durasi tahan-untuk-skip), dan CONTROLS.
- Layar KEYBOARD CONTROLS: remap semua aksi Section 189.15 dengan peringatan konflik (SWAP/CANCEL) dan RESET TO DEFAULTS.
- UI scale dan text scale yang berlaku seketika; preset grafis yang mengatur resolusi 3D, bayangan, kepadatan vegetasi, dan anti-aliasing.
- High Contrast HUD untuk chip HUD, marker tegangan, lajur joget, bar strike, titik skor Suwit, dan teks HUD.
- Hold Assist panco: tahan untuk 8 dorongan per detik dengan biaya stamina yang sama.
- Mode kidal untuk danau dan tinju.
- Model ponsel di tangan Darto saat adegan ponsel; pose membaca ponsel baru.
- Probe performa `tools/perf/perf_probe.gd` dan `docs/performance_report.md`.
- Suite test `a11y` (15 test).

### Diubah

- Motor Darto dibangun ulang sebagai motor bebek; rambut Rini dan Nisa tidak lagi menutupi mata; Nisa benar-benar lebih kecil; kursi plastik di adegan duduk.
- Titik skor Suwit menjadi lingkaran berbingkai.
- Kecepatan dialog RELAXED (sebelumnya nilai "slow" yang tidak cocok dengan save).

### Diperbaiki

- Error "p_size <= 0" saat Wheel digambar sebelum layout.

## 0.8.0 — Milestone 8: Narrative, Cutscenes, Event Arbitration, Ending

### Ditambahkan

- Scene Story dengan pemutar timeline: set rumah, danau, atau warung; aktor, prop, kamera statis per shot; baris dialog, layar ponsel (saldo, notifikasi, pesan, panggilan), jeda komedi, kartu judul, panel unlock, fade.
- 13 event cerita dengan teks final Section 183: prolog di rumah, ikan pertama, Market pertama, enam milestone hutang, kemenangan pertama Don Arowana, hutang lunas, final keluarga, unlock postgame.
- Tahan 0,8 detik (setting `skip_hold_sec`) untuk melewati; melewati tetap menerapkan unlock, chapter, seen, dan rute.
- Rini dan Nisa (model, rambut, 9 clip), clip cerita Darto, set rumah, motor Darto, helm, gelas minum, tikar, rice cooker.
- Rantai ending: hutang lunas → final keluarga → credits → FREE FISHING MODE UNLOCKED → danau.
- Credits bergulir di atas danau; bisa dibuka dari Main Menu.
- Postgame: tab Debt menjadi FAMILY SAVINGS dengan setoran SAVE 25.000/50.000/100.000 dan SAVE ALL.
- Main Menu setelah ending: tikar dan tiga gelas di samping tempat Darto.
- Notifikasi CePatCash di danau, paling sering satu tiap 18–35 menit permainan, berhenti setelah hutang lunas.
- Obrolan singkat Bu Yati sesekali di Market.
- Langkah debug `--mm-event`, `--mm-seen`, `--mm-credits`.
- Suite test `story` (13 test); total 245.

### Diubah

- New Game dan Continue pada save yang belum melihat prolog membuka prolog dulu.
- Ikan pertama memakai percakapan cerita lengkap; Market pertama memutar sambutan, baris setelah jualan pertama, dan baris setelah bayar pertama.
- Kemenangan pertama atas Don Arowana menyelesaikan event ceritanya di layar Result, lalu Darto menjawab "That's not a no."
- Keluar Market dengan event menunggu sekarang memutar scene Story, bukan notice.

## 0.7.0 — Milestone 7: Suwit, Wheel, Full Fish Personality Content

### Ditambahkan

- Suwit: first-to-two, seri diulang, pilihan ikan ditetapkan di awal hitungan, tell jujur atau bohong menurut stat ikan, PANIC PICK saat terlambat, Agate Charm yang menunjukkan langkah asli 0,8 detik.
- Wheel of Fate: delapan segmen dicat, hasil dipilih sebelum berputar, putaran 3,1–4,0 detik, tahan 0,6 detik untuk melewati setelah Wheel pertama; Wheel pertama selalu tinju.
- Scene Result: YOU WIN atau THE FISH GOT AWAY di tepi danau, ikan berbicara lalu Darto menjawab, CONTINUE dengan auto-continue 5 detik.
- Seluruh dialog ikan GDD 166: percakapan pertama tiap ikan, pool LAND, PLAYER_WIN, FISH_WIN_ESCAPE, REEL_ESCAPE, reaksi Darto, dan percakapan khusus kemenangan pertama atas Don Arowana.
- Kotak dialog di bagian bawah layar dengan nama pembicara; maju hanya dengan tap atau tombol.
- Aksesori khas: headband nila, kacamata hitam gurami, kalung emas ikan mas, ikat kepala militer gabus, rantai tipis dan bekas luka arwana.
- Set Suwit, meja bundar, clip Suwit Darto (7) dan keenam ikan (7).
- Alur lengkap danau → dialog → Wheel → keempat duel → Result → danau.
- 15 test baru (total 232), termasuk 24 pasangan ikan×duel lewat scene asli.

### Diubah

- Pemilihan duel sementara (D-071) digantikan Wheel.
- Duel tidak lagi menampilkan overlay hasil; hasilnya ditampilkan scene Result.
- Watchdog test per suite dinaikkan ke 600 detik.

## 0.6.0 — Milestone 6: Dance + Procedural Music Engine

### Ditambahkan

- Mesin musik prosedural: instrumen (kick, snare, hat, kendang rendah/tinggi, bass, pluck Karplus-Strong, pad, aksen), sequencer deterministik, renderer bertahap, dan engine yang memutar loop per state.
- Musik untuk danau dan menu (pluck jarang dengan jeda panjang), tinju (perkusi arcade), dan panco (beat heroik parodi).
- Joget Koplo: lagu koplo 132–156 BPM sepanjang 36–44 detik dibuat dari seed duel; chart diambil dari timeline lagu yang sama.
- Penilaian PERFECT/GREAT/GOOD/MISS terhadap jam lagu dari posisi pemutaran audio; skor dengan bonus combo sampai +50%.
- AI ikan menari nada per nada dari Rhythm Skill dan seed; tiebreak PERFECT, max combo, lalu encore empat nada.
- Black Coffee memperlambat nada di layar tanpa mengubah ketukan.
- Panggung joget di tepi danau dengan lampu untai; clip joget Darto (9) dan keenam ikan (7).
- HUD joget: empat lajur dengan bentuk berbeda, garis pukul, skor kedua pihak, combo, penilaian, beat pulse; lajur sentuh penuh di bagian bawah.
- Settings: bagian Rhythm dengan beat pulse, offset input dan visual, dan wizard kalibrasi dengan click track.
- Test bahwa setiap skrip terkompilasi.
- 18 test baru (total 217).

### Diubah

- `AudioManager.get_authoritative_song_time_sec()` sekarang mengembalikan posisi lagu yang sebenarnya.
- Pause di tengah joget memulai ulang joget dari hitungan awal dengan chart yang sama.

## 0.5.0 — Milestone 5: Arm Wrestling Complete

### Ditambahkan

- Panco Maut: MASH mendorong posisi ke arah Darto, menghabiskan stamina, dan memakai band tenaga 100/85/65/42%.
- Batas 10 tekan/detik tanpa hukuman: menekan lebih cepat tetap menghasilkan 10, bukan setengahnya.
- Stamina kembali 26/detik setelah jeda 0,35 detik. Herbal Tonic menaikkan stamina maksimum.
- Ikan mendorong terus dan melakukan burst dengan peringatan 0,7 detik; tier lebih tinggi burst lebih kuat.
- Ronde 32 detik, Sudden Grip saat hampir nol, dan rematch 10 detik untuk Don Arowana bila seri tepat.
- Meja panco di tepi danau dengan bantalan siku; clip panco Darto dan keenam ikan; lengan bersandar sesuai posisi.
- HUD panco: bar posisi, stamina dengan takik band, jam, peringatan burst yang berdenyut, tombol MASH besar.
- Enam SFX panco dengan tiga resep baru.
- 19 test baru (total 199).

### Diubah

- Selama Wheel belum ada, duel pertama tetap tinju; sesudahnya duel diundi dari seed encounter di antara duel yang tersedia.
- `--mm-duel` menerima id duel.
- Watchdog test sekarang per suite.

## 0.4.0 — Milestone 4: Boxing Complete

### Ditambahkan

- Tinju Empang: ikan memberi telegraph, pemain menghindar ke arah yang ditunjukkan, lalu membalas dengan jab atau cross di jendela counter.
- Perfect Dodge di 180 ms terakhir: freeze 70 ms, jendela counter lebih panjang, damage 2,4×.
- Pukulan tanpa celah di-block ikan (40%). Batas waktu 60 detik, pembanding persentase HP, dan sudden death saat seri.
- Keenam ikan bertinju dengan HP, serangan, dan telegraph masing-masing; Don Arowana menyerang lebih rapat.
- Ring tinju di tepi danau: matras, tiang bambu, tali, lampu gantung, dan bangku tempat ikan berdiri.
- Sarung tinju dan sembilan clip tinju Darto; sarung tinju dan sepuluh clip tinju untuk tiap ikan.
- HUD tinju: dua bar HP, jam ronde, penunjuk arah dodge, empat tombol sentuh, dan nama tombol keyboard yang mengikuti remap.
- Hasil duel: menang berarti ikan masuk ember, kalah berarti ikan lepas tanpa kerugian lain. Kalah di duel pertama hanya mengulang.
- Tujuh SFX tinju.
- Debug: bot duel, paksa arah serangan, paksa hasil, langsung masuk ring.
- 26 test baru (total 180), termasuk tangkapan pertama yang ditinju sampai masuk ember di scene asli.

### Diubah

- Ikan yang mendarat sekarang dibawa ke ring tinju, tidak lagi langsung ke ember.
- Potret Fish Book dirender tanpa sarung tinju.
- Watchdog test dinaikkan dari 180 ke 300 detik.

## 0.3.0 — Milestone 3: Market, Economy, Upgrades, Book, Records

### Ditambahkan

- Warung Bu Yati sebagai scene Market: set warung, Bu Yati di balik meja, Darto di depannya, kamera tetap untuk landscape dan portrait.
- Lima tab ledger: SELL, UPGRADES, DEBT, FISH BOOK, RECORDS. Market selalu terbuka di SELL.
- Jual semua atau per kategori dengan struk rincian. Ikan baru menjadi uang setelah dijual.
- Lima keluarga upgrade dengan level, efek sekarang, efek berikutnya, harga pasti, dan level maksimum.
- Debt Ledger: asal, terbayar, sisa, progress bar, PAY 25,000 / 50,000 / 100,000, PAY CUSTOM, PAY ALL AVAILABLE.
- Tutorial kunjungan pertama: jual, buka tab Debt, bayar Rp 10,000.
- Fish Book dengan potret hasil render; ikan yang belum dikalahkan tampil sebagai siluet. Halaman Records.
- Antrean event cerita: trigger milestone hutang, prioritas, satu event per kunjungan Market, tersimpan di save. Cutscene final menyusul di Milestone 8.
- Autosave setelah setiap transaksi, dengan dialog bila penyimpanan gagal.
- Bu Yati (rig dan lima clip), sembilan prop warung, set Market, enam potret Fish Book, dan tiga lembar referensi baru, semuanya dari generator.
- Tiga SFX Market (jual, beli, bayar hutang) dan ambience warung: radio kecil, dengung freezer, angin sore.
- Debug: langkah command line untuk menyiapkan cash, hutang, ember, dan flag cerita.
- 32 test baru (total 154), termasuk satu kunjungan Market penuh lewat tombol asli.

### Diubah

- Tombol MARKET di danau sekarang aktif.
- Validasi Boot mewajibkan potret Fish Book dan memeriksa data event cerita.
- Ambience disusun per tempat; lapisan yang dipakai bersama (angin) tidak terputus saat berpindah.
- Generator menyimpan prop yang dipakai sebuah set sebagai referensi scene, bukan salinan.
- Chip cash dan tombol Pause dipakai bersama oleh HUD danau dan Market (`HudChip`).

## 0.2.0 — Milestone 2: Fishing Vertical Slice

### Ditambahkan

- Loop memancing penuh: cast, menunggu, false nibble, bayangan ikan, strike window, reel, landing atau lepas.
- Roll encounter deterministik per seed: sampah atau ikan, berat, BIG ONE, waktu tunggu.
- Minigame reel: marker, zona hijau, progres landing, line stress, feint Don Arowana.
- Danau Cempaka, Darto, keenam ikan, joran, pelampung, ember, dan tiga sampah dari generator; tiga lembar referensi visual.
- HUD memancing untuk landscape dan portrait, dengan tombol kontekstual besar di layout sentuh dan ikon yang digambar dari kode.
- Prompt tutorial memancing memakai teks final GDD; ikan pertama selalu Bruiser Catfish.
- Pause menu, auto-pause saat kehilangan fokus, dan intip isi ember.
- Sembilan SFX memancing dan ambience danau, semuanya disintesis.
- Debug: paksa tangkapan, waktu tunggu cepat, bot reel, nilai internal reel di overlay, langkah otomatis lewat command line.
- 34 test baru (total 122), termasuk satu tangkapan penuh di scene asli.

### Diubah

- Main Menu memakai danau dan Darto sebagai latar. New Game dan Continue langsung menuju danau.
- Data ikan dan sampah menunjuk ke model hasil generator; validasi Boot mewajibkannya.
- Output generator dinormalkan (ID resource dan node) agar identik di setiap run.
- Play time dihitung selama berada di danau.

### Dihapus

- Pemberitahuan "FOUNDATION BUILD" di Main Menu.

## 0.1.0 — Milestone 1: Foundation

### Ditambahkan

- Baseline project: Godot 4.7, renderer Compatibility, 1280×720 landscape dengan referensi 720×1280 untuk portrait, orientasi Android portrait.
- InputMap untuk seluruh action gameplay dan UI dengan tombol default sesuai GDD Section 91.
- Sembilan autoload: `GameState`, `SaveManager`, `SceneRouter`, `AudioManager`, `InputManager`, `PlatformService`, `RNGService`, `StoryDirector`, `DebugService`.
- Kelas Resource dan data authoritative: 6 ikan, 3 sampah, 5 upgrade, serta konfigurasi fishing, tinju, panco, joget, dan suwit.
- Save schema v5: buat, muat, validasi, perbaikan otomatis, penulisan atomik, backup save rusak, import/export JSON, autosave setting.
- RNG gameplay deterministik berbasis seed, terpisah dari RNG kosmetik.
- Audio prosedural dasar: layout bus, volume per bus, dan tiga SFX UI yang disintesis dari kode.
- Pipeline generator aset: tema UI dan ikon aplikasi dibuat dari kode, manifest dengan checksum, pemeriksa kebijakan tanpa aset internet.
- Scene Boot dengan validasi data, dan Main Menu dengan Continue, New Game (konfirmasi dua langkah), How To Play, Settings (audio, reset save), dan pemulihan save rusak.
- Debug Overlay dasar (F10) dan tool screenshot UI lewat command line.
- 88 test headless dalam 8 suite.

### Diubah

- `project.godot`: renderer `mobile` diganti `gl_compatibility`, nama project menjadi `Mancing Mania Gelut Edition`.
- `.gitignore` dilengkapi sesuai GDD Section 191.6.

### Dihapus

- `icon.svg` bawaan Godot, diganti ikon hasil generator.
