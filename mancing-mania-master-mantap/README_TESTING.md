# Testing

Test berjalan headless lewat runner internal (GDD Section 136). Tidak memakai addon atau `npm`.

## Perintah

```text
godot --headless --path . --import
godot --headless --path . --script res://tests/run_all.gd
godot --headless --path . --script res://tests/run_all.gd -- --suite=save
```

- `--import` diperlukan sekali setelah checkout baru, dan setiap kali ada script baru yang memakai `class_name`. Tanpa itu test gagal dengan `Identifier "X" not declared`.
- `--suite=<nama>` menjalankan satu suite saja.
- Exit code `0` berarti semua lulus, `1` berarti ada yang gagal atau tidak ada test yang berjalan, `2` berarti watchdog menghentikan suite yang berjalan lebih dari 600 detik.
- Di CI atau script, bungkus perintah dengan batas waktu. Script yang error sebelum memanggil `quit()` membuat proses Godot tidak pernah berhenti.

Semua test bekerja di `user://test_tmp/` dan tidak pernah menyentuh save pemain.

## Suite

| Suite | File | Cakupan |
|---|---|---|
| `data` | `tests/suites/test_data.gd` | setiap skrip terkompilasi, BOOT-001..004, tabel ikan/sampah/upgrade/balance sesuai GDD, InputMap, tabel teks, terjemahan Bahasa Indonesia lengkap (placeholder cocok, nama per bahasa, setting bahasa ikut perangkat) |
| `state` | `tests/suites/test_game_state.gd` | API GameState, SAVE-012 (4.000 transaksi acak tanpa melanggar invariant) |
| `save` | `tests/suites/test_save.gd` | SAVE-001..009, migrasi, import/export, penulisan terputus, DEV DIRTY |
| `rng` | `tests/suites/test_rng.gd` | determinisme seed, distribusi 100.000 encounter |
| `audio` | `tests/suites/test_audio.gd` | sintesis SFX UI, memancing, dan Market tanpa NaN/clipping; ambience danau dan warung; bus; volume mengikuti setting |
| `services` | `tests/suites/test_services.gd` | PlatformService, InputManager, StoryDirector, DebugService, SceneRouter |
| `fishing` | `tests/suites/test_fishing.gd` | FISH-002..016: timeline cast, waktu tunggu, jendela strike, sampah, distribusi 100.000 encounter, aturan reel, line break, landing |
| `market` | `tests/suites/test_market.gd` | MKT-001..011, STORY-001..007 dan 011, BOOK-001..005: harga jual, Sell All dan per kategori, harga upgrade, batas pembayaran hutang, double tap, autosave gagal, antrean event cerita, round-trip save |
| `boxing` | `tests/suites/test_boxing.gd` | BOX-001..012: HP dan Tonic, nilai dan waktu jab/cross, setiap serangan ber-telegraph, dodge benar/salah, jendela perfect 180 ms, pengali 2,0× dan 2,4×, block 40%, timeout, sudden death, keenam ikan bisa dikalahkan, commit hasil duel |
| `arm_wrestle` | `tests/suites/test_arm_wrestle.gd` | ARM-001..011: posisi awal, impuls dan biaya stamina, batas 10 tekan/detik, jeda dan laju regen, stamina Tonic, band tenaga, burst dengan peringatan, timeout, Sudden Grip, rematch Arowana, setiap ikan kalah pada 7 tekan/detik |
| `dance` | `tests/suites/test_dance.gd` | DANCE-001..011, AUD-011: rentang BPM dan durasi, seed yang sama menghasilkan chart dan jadwal musik yang sama, jendela PERFECT/GREAT/GOOD, skor dan bonus combo, Coffee hanya visual, penilaian tidak bergantung FPS, offset kalibrasi, AI ikan per nada, tiebreak dan encore, loop musik |
| `suwit_wheel` | `tests/suites/test_suwit_wheel.gd` | SUWIT-001..008, WHEEL-001, 002, 005: first-to-two, seri diulang, pilihan tersembunyi sebelum tell, peluang tell jujur per ikan, panic pick, Charm, peluang Wheel 25%, hasil Wheel tetap di setiap FPS, Wheel pertama selalu tinju; kelengkapan dan keterpisahan dialog ikan |
| `spots` | `tests/suites/test_spots.gd` | Revisi 6.7 (GDD 198): data tempat dan ikan per tempat, Danau Cempaka tidak berubah, syarat buka dan perlengkapan, normalisasi tempat, migrasi save 5 → 6, sifat air (arus, air dalam, pasang surut, ombak), Wheel per tempat, keempat duel baru (aturan, determinisme, hasil paksa, bot menang melawan setiap ikan tempatnya, commit hasil), scene asli keempat duel, peta dan pindah tempat, Market TRAVEL GEAR, Fish Book per tempat |
| `story` | `tests/suites/test_story.gd` | NAR-001, NAR-002, STORY-007, 008, 012: semua teks cerita ada dan bukan placeholder, setiap timeline (set, aktor, clip, penanda, kamera) bisa diputar, ponsel cerita sebagai aplikasi chat (kartu akun, pesan CepatCash, thread per kontak, layar panggilan), skip menerapkan semua perubahan, baris menunggu pemain, obrolan Market, jeda CePatCash, Family Savings, Arowana tidak diputar dua kali; scene asli: New Game → prolog → danau, credits dari menu, bayar lunas → final keluarga → credits → postgame → danau → Main Menu setelah ending |
| `a11y` | `tests/suites/test_accessibility.gd` | Section 189: semua setting wajib ada di Settings, baris opsi berputar dan tersimpan, UI scale dan text scale, A11Y-001/002 tombol penting utuh di 130% UI + 150% teks dalam English dan Bahasa Indonesia, A11Y-003 High Contrast, A11Y-007 kalibrasi bertahan setelah reload, A11Y-008 Hold Assist mengalahkan semua ikan dengan biaya stamina sama, A11Y-009 tinju kidal di safe area, A11Y-010 konflik remap, A11Y-012 dialog INSTANT tetap menunggu, preset grafis |
| `release` | `tests/suites/test_release.gd` | Section 135, 186, 187, 191: kode runtime tanpa akses jaringan, layar Privacy (ringkasan, kebijakan lengkap, lisensi engine dan font) dan peringatan storage Web, export preset (path, single-thread, application ID, SDK 24–36, arm64, tanpa permission, filter paket), versi semantik sama dengan Android versionName, `.gitignore` dan tidak ada keystore |
| `assets` | `tests/suites/test_assets.gd` | kebijakan tanpa aset internet (kecuali dua font berlisensi), manifest generator, tema hasil generate, cakupan glyph font, ikon stiker (berwarna, beroutline, tanpa celah tertutup), aset Market, potret Fish Book, kontrak animasi tinju |
| `boot` | `tests/suites/test_boot_flow.gd` | scene asli: Boot → Main Menu → danau, New Game, Continue, pemulihan save rusak, satu tangkapan penuh, pause, guncangan HUD; lalu Market: blueprint scene, satu kunjungan penuh lewat tombol asli, pemberitahuan Fish Book saat keluar, pause, tata letak landscape dan portrait; lalu tinju: blueprint scene, tangkapan pertama sampai ember lewat duel, kalah di pelajaran pertama, input, pause, dan empat kontrol sentuh; lalu panco: blueprint, aksi dan tombol MASH, arah lengan, pause, hasil, layout portrait; joget, Suwit, Wheel, Result, dan setiap ikan di setiap duel lewat scene asli |

Test manual (MAN) di matriks QA GDD Section 180, seperti BOOT-005/006 dan SAVE-010/011, membutuhkan build Web dan perangkat Android. Itu dikerjakan saat export preset tersedia.

## Menulis test

- Suite meng-extend `res://tests/test_suite.gd` dan didaftarkan di `SUITES` pada `tests/run_all.gd`.
- Setiap method `test_*` harus diakhiri `return true`. Error runtime menghentikan fungsi GDScript dan mengembalikan `null`; runner menghitung itu sebagai gagal, bukan lulus diam-diam.
- Pakai `check`, `check_eq`, `check_near`, `check_empty`, `check_contains`. Jangan pakai `assert()`: assert yang gagal menghentikan runner sebelum `quit()`.
- Untuk menunggu waktu nyata pakai `wait_seconds()`, bukan `create_timer()`. Timer yang dibuat di akhir frame yang lambat ikut dipotong durasi seluruh frame itu dan bisa selesai terlalu cepat.
- Suite yang menulis save memanggil `SaveManager.configure_storage("user://test_tmp/<nama>")` dan mengembalikannya dengan `configure_storage()` di `after_all`.

## Pemeriksaan UI lewat screenshot

Debug build menerima argumen setelah `--` untuk memeriksa tata letak tanpa mengklik manual:

```text
godot --path . --resolution 1280x720 -- --mm-shot=C:/tmp/menu.png
godot --path . --resolution 540x960 -- --mm-press=MenuCanvas/SafeRoot/MenuButtons/SettingsButton --mm-shot=C:/tmp/settings.png
godot --path . -- --mm-overlay --mm-shot=C:/tmp/debug.png --mm-shot-delay=1.0
```

Langkah dijalankan berurutan sesuai urutan di command line:

| Argumen | Fungsi |
|---|---|
| `--mm-press=<path node>` | menekan tombol di scene aktif |
| `--mm-action=<action>` | menekan lalu melepas satu input action, misalnya `fish_cast` |
| `--mm-hold=<action>` / `--mm-release=<action>` | menahan dan melepas action |
| `--mm-wait=<detik>` | menunggu |
| `--mm-force=<id>` | memaksa tangkapan berikutnya (`catfish_bruiser`, `trash_tyre`, ...) |
| `--mm-fast-wait` | gigitan datang setengah detik setelah cast |
| `--mm-auto-reel` | bot memainkan reel |
| `--mm-auto-duel` | bot memainkan duel |
| `--mm-auto-dialogue` | dialog maju sendiri |
| `--mm-duel=<id ikan>[:<id duel>]` | memulai game bila belum ada, lalu langsung berduel melawan ikan itu (default tinju), misalnya `carp_golden:arm_wrestle` atau `belida_pendekar:silat` (duel `silat`, `tambang`, `gasing`, `pinang` revisi 6.7) |
| `--mm-result=<win\|loss>` | memaksa hasil duel berikutnya |
| `--mm-attack-side=<left\|right>` | memaksa arah serangan tinju |
| `--mm-upgrade=<id>:<level>` | mengatur level upgrade, misalnya `tonic:3` |
| `--mm-overlay` | membuka Debug Overlay |
| `--mm-goto=<fishing\|market>` | memulai game bila belum ada, lalu pindah ke scene itu |
| `--mm-location=<id tempat>` | membuka tempat (`kenanga`, `melati`, `anggrek`, `mawar`), memberi perlengkapannya, dan memindahkan Darto ke sana; pakai sebelum `--mm-goto=fishing` |
| `--mm-cash=<jumlah>` | mengatur cash |
| `--mm-debt-left=<jumlah>` | mengatur sisa hutang |
| `--mm-bucket=<id>:<jumlah>` | menaruh tangkapan di ember, misalnya `catfish_bruiser:3` |
| `--mm-win=<id ikan>` | mencatat satu kemenangan duel atas ikan itu (untuk Fish Book) |
| `--mm-story=<kunci>` | menyalakan satu flag cerita, misalnya `fish_book_unlocked` |
| `--mm-shot=<path png>` | menyimpan screenshot; run berhenti setelah langkah terakhir |

Contoh satu tangkapan penuh di portrait:

```text
godot --path . --resolution 540x960 -- --mm-fast-wait --mm-auto-reel --mm-press=MenuCanvas/SafeRoot/MenuButtons/NewGameButton --mm-wait=2.2 --mm-action=fish_cast --mm-wait=2.0 --mm-action=fish_cast --mm-wait=3.0 --mm-shot=C:/tmp/reel.png
```

Perintah ini memakai save asli di `user://`. Menekan `NewGameButton` akan membuat save sungguhan.

Contoh halaman Debt di Market tanpa menyentuh save (langkah `--mm-goto`, `--mm-cash`, `--mm-bucket`, dan sejenisnya menandai state sebagai `DEV DIRTY STATE`, sehingga tidak ada yang disimpan):

```text
godot --path . --resolution 1280x720 -- --mm-goto=fishing --mm-bucket=catfish_bruiser:3 --mm-cash=261000 --mm-goto=market --mm-wait=2 --mm-press=MarketCanvas/SafeRoot/TabBar/DebtTabButton --mm-shot=C:/tmp/debt.png
```

## Peringatan yang boleh diabaikan

`WARNING: ... ObjectDB instances were leaked at exit` kadang muncul di akhir suite `boot`. Suite itu membuang scene Main Menu saat dialog masih menunggu jawaban, sehingga coroutine yang tertunda masih hidup ketika proses berakhir. Ini hanya terjadi di test.
