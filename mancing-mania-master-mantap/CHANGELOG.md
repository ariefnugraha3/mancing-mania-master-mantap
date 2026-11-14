# Changelog

Format mengikuti Semantic Versioning (GDD Section 186.2). Tag milestone mengikuti GDD Section 191.3.

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
