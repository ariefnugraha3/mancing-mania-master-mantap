# Keputusan Implementasi

Catatan keputusan untuk detail yang tidak diatur GDD v6, sesuai aturan ambiguitas GDD Section 163.4. Tidak ada keputusan di sini yang mengubah aturan authoritative. Satu-satunya perubahan terhadap teks GDD adalah **D-003**, yang sudah disetujui pemilik project dan sudah dimasukkan ke GDD.

Setiap entri: apa yang diputuskan, alasannya, dan bagian GDD yang terkait.

## Milestone 1

### D-001 — Dokumentasi berada di dalam folder project Godot

`README.md`, `README_TESTING.md`, `CHANGELOG.md`, dan `docs/` disimpan di folder project Godot (`mancing-mania-master-mantap/`), bukan di root repository. `docs/.gdignore` membuat Godot mengabaikan folder itu.

Alasan: pemilik project meminta semua pekerjaan dilakukan di folder project Godot. GDD tetap berada di root repository.

### D-002 — Data sampah memakai resource `TrashData`

GDD Section 30 memberi tabel sampah (peluang dan harga) tetapi Section 170 tidak mendefinisikan skemanya. Dibuat `TrashData` (`id`, `display_name`, `chance`, `sale_value`, `model_scene`) di `res://data/trash/<id>.tres`, sejajar dengan `FishData`.

Alasan: Section 119.2 mewajibkan balancing berupa Resource, bukan angka di script.

### D-003 — REVISI GDD (disetujui): `fish_book` menyimpan `duel_wins` per ikan

GDD Section 171.5 mendefinisikan `favourite_duel` sebagai mode duel dengan kemenangan terbanyak untuk ikan itu, tetapi skema entri hanya punya total `wins`. Tanpa jumlah kemenangan per mode, nilai itu tidak bisa dihitung.

Setiap entri `fish_book` ditambah satu field:

```json
"duel_wins": { "boxing": 0, "arm_wrestle": 0, "dance": 0, "suwit": 0 }
```

`favourite_duel` tetap ada dan dihitung ulang dari `duel_wins` setiap kali berubah dan setiap kali save dimuat. Urutan tiebreak mengikuti GDD: `boxing`, `arm_wrestle`, `dance`, `suwit`.

Dampak: penambahan murni, schema tetap versi 5, tidak ada field GDD yang berubah arti.

Status: **disetujui pemilik project pada 2026-11-12.** GDD Section 171.5 sudah diperbarui dengan field ini, mengikuti alur perubahan desain Section 191.13.

### D-004 — Rentang berat empat ikan

GDD Section 82 hanya memberi contoh berat untuk Catfish (1,2–3,8 kg) dan Arowana (4,5–8,0 kg). Empat ikan lain diisi:

| Ikan | Berat |
|---|---|
| Gym-Rat Tilapia | 0,6–2,4 kg |
| Shady Gourami | 1,4–4,2 kg |
| Golden Carp | 1,6–5,0 kg |
| Snakehead Sergeant | 1,8–5,5 kg |

Alasan: berat hanya kosmetik (tidak memengaruhi harga) dan skema `FishData` mewajibkan nilainya. Angka dipilih agar naik mengikuti tier dan tetap di bawah Arowana.

### D-005 — Migrasi save: schema 5 adalah versi pertama

Codebase Godot ini belum pernah menulis schema selain 5. Kerangka migrasi berurutan sudah ada di `SaveManager.migrate_save()`, tetapi daftar migrasinya kosong. Save versi 1–4 dan versi di atas 5 dilaporkan sebagai `SAVE VERSION NOT SUPPORTED`, filenya tidak disentuh, dan salinannya dibuat sebelum pemain bisa menimpanya.

### D-006 — Setting sebelum ada save

Setting termasuk bagian dari file save (Section 171.9). Sebelum New Game, belum ada file. Aturannya:

- Setting yang diubah sebelum ada save disimpan di memori dan ikut ditulis saat New Game membuat save.
- New Game dan RESET SAVE mempertahankan setting yang sedang aktif.
- Setelah save ada, setiap perubahan setting di-autosave dengan jeda 0,4 detik agar menggeser slider tidak menulis file berkali-kali.

### D-007 — Format `input_remap`

GDD Section 171.9 hanya menyebut "override action keyboard yang valid". Formatnya:

```json
{ "open_market": ["key:77"], "fish_cast": ["key:32", "mouse:1"] }
```

`key:<physical keycode>` atau `mouse:<button index>`. Hanya action di daftar remappable Section 189.15 yang diterima. Action tanpa override memakai default project. UI remapping sendiri dikerjakan di milestone aksesibilitas.

### D-008 — Satu project untuk landscape dan portrait

`PlatformService` mengganti referensi stretch antara 1280×720 dan 720×1280 berdasarkan aspect ratio jendela (Section 167.7), bukan berdasarkan platform atau user agent. Web yang dipersempit dan Android portrait memakai jalur yang sama.

### D-009 — Fade transisi dimiliki `SceneRouter`

Section 169.4 meminta strategi fade terpusat, sedangkan blueprint Section 168 menaruh `TransitionLayer/FadeRect` di tiap scene. `SceneRouter` memakai overlay miliknya sendiri yang tetap hidup saat scene diganti, sehingga tidak ada satu frame pun tanpa penutup. `TransitionLayer/FadeRect` di tiap scene tetap ada sesuai blueprint dan dipakai untuk fade lokal scene (Boot memakainya untuk fade-in; cutscene akan memakainya untuk aksi `fade`).

### D-010 — Action dilacak dari input yang tidak ditangani UI

`InputManager` membaca action dari `_unhandled_input`. Klik yang sudah dikonsumsi tombol UI tidak ikut terbaca sebagai `fish_cast` (yang juga terikat ke klik kiri). Tombol sentuh memanggil `InputManager.press_action()` / `release_action()`, sehingga keyboard, mouse, dan sentuh memakai jalur yang sama (Section 123).

Tekanan yang tersimpan kedaluwarsa setelah 150 ms dan dibuang saat input gameplay dimatikan, sesuai Section 176.1.

### D-011 — Teks terpusat di `ui_text.tres`

Semua teks yang dilihat pemain ada di `res://data/dialogue/ui_text.tres` dan diambil lewat `TextDb.t()`. Key yang tidak ada mencatat error dan tampil sebagai `#key#`, supaya ketahuan saat QA dan tidak menjadi teks kosong.

### D-012 — `UpgradeData.stat_key` menunjuk field di balance config

Efek upgrade yang benar-benar dipakai gameplay ada di balance config (misalnya `FishingBalance.rod_half_width_per_level`). `UpgradeData.effect_per_level` dipakai untuk tampilan toko. `stat_key` berisi nama field config itu, dan validasi Boot menolak data bila kedua angka berbeda.

### D-013 — Generator aset

- Hanya builder yang sudah menghasilkan aset yang dibuat (`ui_art_builder.gd`). Builder mesh, karakter, ikan, prop, lingkungan, dan kendaraan ditambahkan oleh milestone yang pertama membutuhkannya, bukan sebagai file kosong (Section 163.2).
- Perintah yang divalidasi: `godot --headless --path . --script res://tools/generators/generate_all_assets.gd`. Varian `--editor` dari Section 184.2 juga berjalan.
- Agar hasil kedua varian identik byte demi byte, `generator_io.gd` membuang `uid="uid://..."` yang ditambahkan editor di header, dan setiap sub-resource diberi ID tetap.
- Tema tidak menyimpan data piksel. Handle slider memakai `GradientTexture2D` radial, karena `ImageTexture` selalu disimpan dengan ID acak.

Catatan untuk milestone berikutnya: scene hasil generator yang mereferensikan resource lain juga bisa mendapat UID dari editor di baris `ext_resource`. Normalisasi yang sama perlu diterapkan di sana.

### D-014 — Isi Main Menu di Milestone 1

- `LakeSet` dan `DartoMenuPose` dari blueprint Section 168.2 belum ada karena set danau dibuat generator di Milestone 2. Latar sementara adalah langit prosedural hangat dengan garis horizon.
- Tombol CREDITS tampil tetapi nonaktif. Isi credits masuk lingkup Milestone 8.
- HOW TO PLAY sudah memakai teks final Section 183.19. Diagram dan ikon input menyusul di Milestone 9.
- Selama `fishing.tscn` belum ada, New Game dan Continue menampilkan pemberitahuan "FOUNDATION BUILD" setelah save siap. Begitu scene itu ada, alur otomatis menuju danau dan teks pemberitahuan bisa dihapus.

### D-015 — Konfirmasi kedua New Game

Section 85 meminta dua langkah konfirmasi tetapi hanya memberi satu kalimat. Langkah kedua memakai judul "ARE YOU SURE?" dengan isi "Your current progress will be gone for good." Tombol aman ("KEEP MY SAVE") selalu mendapat fokus awal dan dipilih oleh Esc/back.

### D-016 — Dialog pemulihan save

Sesuai Section 117 dan 183.21, dialog hanya punya TRY AGAIN dan START NEW GAME, tanpa tombol batal. TRY AGAIN yang gagal lagi menampilkan dialog yang sama. START NEW GAME langsung membuat save baru tanpa konfirmasi dua langkah, karena save lama tidak terbaca dan salinannya sudah diamankan.

### D-017 — Penulisan save yang terputus

Save ditulis ke file sementara, dibaca ulang untuk verifikasi, lalu menggantikan save lama. Saat memuat:

- Jika save utama ada dan file sementara tertinggal, file sementara dibuang dan save lama dipakai (QA SAVE-008).
- Jika save utama tidak ada tetapi file sementara lengkap, file sementara dipromosikan. Ini menutup celah di Windows, tempat proses rename menghapus target lebih dulu.

### D-018 — Aset wajib di `FishData` diperiksa bertahap

`model_scene` dan `portrait_texture` wajib menurut Section 170.1, tetapi asetnya baru dibuat di Milestone 2 dan 9. `GameData.validate_all(require_assets)` menerima flag untuk pemeriksaan itu. Flag dinyalakan oleh milestone yang menghasilkan asetnya.

### D-019 — Lingkup `StoryDirector`

Milestone 1 mengimplementasikan antrean event: tambah, tandai sudah dilihat, serial kunjungan Market, dan pembersihan event yang tidak valid. Evaluasi trigger, arbitrasi prioritas saat keluar Market, dan pemutaran event membutuhkan data `StoryEvent` dan scene Story, yang masuk Milestone 3 dan 8. Sampai saat itu `resolve_market_exit_event()` tidak pernah memilih event.

### D-020 — Action tambahan

- `ui_confirm` terikat ke Enter, Enter numpad, dan Space. GDD tidak menyebut tombolnya.
- `ui_cancel` memakai action bawaan Godot (Esc).
- `debug_toggle_overlay` (F10) dibuat sebagai action agar tool debug juga tidak membaca keycode langsung.

### D-021 — Mutasi debug tidak pernah tersimpan diam-diam

Sesuai Section 178.3, setelah cash, hutang, upgrade, atau seed diubah lewat `DebugService`, `SaveManager.save_game()` melewati penulisan untuk semua alasan kecuali `SAVE DEBUG STATE`. Fungsi tetap mengembalikan `true` agar alur game berjalan; yang dilewati hanya penulisan file, dan itu dicatat di log.

### D-022 — Catatan teknis: jangan pakai `SceneTreeTimer` untuk jendela waktu gameplay

Ditemukan saat menulis test: timer yang dibuat di akhir frame yang lambat dipotong durasi seluruh frame itu pada frame berikutnya, sehingga bisa selesai jauh lebih cepat dari waktu nyata. Untuk strike window, telegraph, dan timer duel di milestone berikutnya, akumulasikan `delta` di `_process` dan batasi `delta` per frame agar satu frame yang tersendat tidak menghabiskan jendela reaksi pemain.


## Milestone 2

### D-023 — Field tambahan di `FishingBalance`

Skema Section 170.3 tidak memuat beberapa angka yang dibutuhkan aturan memancing. Semuanya ditambahkan sebagai field dengan nilai default, supaya tetap berupa data dan bukan angka di script:

| Field | Nilai | Sumber |
|---|---|---|
| `trash_strike_window_sec` | 0,90 | GDD Section 28 |
| `zone_retarget_min_sec` / `max_sec` | 0,65 / 1,40 | GDD Section 33 |
| `land_slowdown_sec` | 0,25 | GDD Section 37 |
| `bite_warning_sec` | 1,1 | tidak ada di GDD; lama bayangan ikan terlihat sebelum gigitan asli |
| `boss_feint_probability` / `boss_feint_sec` | 0,35 / 0,3 | tidak ada di GDD; Section 33 hanya menyebut Arowana "sesekali" feint |

Dua baris terakhir adalah angka rasa yang boleh di-tuning setelah playtest manusia. Tabel authoritative GDD tidak berubah.

### D-024 — Encounter di-roll saat cast, dari satu seed

Section 29 berkata roll terjadi "setiap successful strike", tetapi jendela strike bergantung pada jenis ikan (Section 28), jadi isi kail harus sudah diketahui sebelum jendela dibuka. Encounter di-roll saat cast dimulai dari satu seed lewat channel RNG bernama (`trash`, `fish`, `trash_type`, `weight`, `big_one`, `wait`, `nibble_*`). Peluang per strike yang berhasil tetap sama dengan tabel Section 29, dan satu seed mereproduksi seluruh gigitan.

### D-025 — Sampah tidak melewati reel

GDD memberi jendela strike untuk sampah (0,90 detik) tetapi tidak memberi lebar zona, kecepatan, atau stress untuk reel. Sesuai aturan ambiguitas, pilihan paling sederhana diambil: strike yang berhasil pada sampah langsung mengangkatnya ke ember (QA FISH-010).

### D-026 — Tujuan ikan yang mendarat sebelum duel ada

Urutan routing: Wheel bila scene-nya ada; kalau tidak, duel pertama yang scene-nya ada (atau duel paksaan debug); kalau tidak ada duel sama sekali, ikan masuk ember dan HUD menampilkan "No duels in this build yet." Jalur terakhir hilang dengan sendirinya begitu scene duel pertama dibuat di Milestone 4. Di jalur itu `record_fish_win` tidak dipanggil, karena tidak ada duel yang dimenangkan; ikan belum tercatat "discovered" di Fish Book.

### D-027 — Ikan pertama yang diskrip

Selama `stats.fish_landed` masih 0 dan tutorial `reeling_seen` belum diset, setiap cast menghasilkan Bruiser Catfish (Section 13, 176.10). Aturan berhenti begitu satu ikan berhasil didaratkan, bukan setelah satu kali cast, supaya pemain yang gagal tetap mendapat lele berikutnya.

### D-028 — Satu input kontekstual

Space, klik kiri, dan tombol aksi sentuh memakai action yang sama: cast saat idle, strike saat menunggu atau saat gigitan, dan reel selama ditahan. Tekanan yang memicu strike boleh terus ditahan menjadi reel. Setiap tekanan dikonsumsi satu kali, jadi tap yang melempar tidak bisa ikut terhitung sebagai strike (Section 176.1).

Strike saat belum ada gigitan asli, termasuk saat bayangan ikan sudah terlihat, dihitung false strike: tunda 0,8 detik, tanpa hukuman lain.

### D-029 — Waktu yang tidak disebut GDD

- Pelampung menyentuh air 1,05 detik setelah cast dimulai (lepas di 0,48; Section 24 menyebut ayunan selesai di 1,05).
- Reveal tangkapan ikan 3,2 detik dan sampah 1,5 detik sebelum game lanjut.
- Jeda setelah ikan lepas 1,3 detik.
- Langkah waktu per frame dibatasi 0,1 detik (lihat D-022).

### D-030 — Rig ikan dan karakter

- Ikan memakai satu mesh yang di-skin sepanjang tulang punggung, sehingga badan melengkung mulus saat berenang dan menggelepar. Rig punya 9 tulang sesuai Section 184.7.
- Karakter manusia memakai ikatan kaku: setiap bagian tubuh terikat penuh ke satu tulang (Section 184.6 mengizinkan). Rig Darto punya 18 tulang.
- Tulang tidak punya rotasi rest, jadi nilai kunci animasi adalah sudut sendi itu sendiri.
- Keenam ikan sudah punya profil badan, sirip, dan warna sendiri. Aksesori dan clip duel ditambahkan oleh milestone duel dan dialog masing-masing.

### D-031 — Darto berdiri saat memancing

GDD menggambarkan gerakan cast (joran ditarik ke belakang lalu diayun) tetapi tidak menyebut duduk atau berdiri di fase memancing. Darto berdiri di tepi. Posisi Darto, pelampung, ember, dan kamera disimpan sebagai marker di dalam `env_lake_set.tscn`, sehingga scene memancing dan Main Menu membaca titik yang sama.

Kamera tetap per layout: satu bingkai untuk landscape, satu untuk portrait. Kamera hanya berpindah saat layout berubah dan tidak pernah bergetar.

### D-032 — Rumput dan alang-alang dirakit saat scene dimuat

MultiMesh menyimpan data instance di perangkat grafis, sehingga generator headless tidak bisa menuliskannya ke file. Generator menyimpan mesh rumpun dan daftar penempatan; `ScatterField` merakit MultiMesh saat node masuk scene. Hasilnya tetap instancing satu draw call per jenis, sesuai Section 101.

### D-033 — Normalisasi file hasil generator

Selain UID (D-013), penyimpan teks Godot memberi ID acak pada sub-resource, referensi eksternal, dan setiap node scene (`unique_id`). `generator_io.gd` menomori ulang ID resource menurut urutan muncul dan membuang `unique_id`. Dua run berturut-turut menghasilkan manifest yang identik.

### D-034 — Lembar referensi

`reference_sheet_generator.gd` dijalankan terpisah dengan jendela, karena render butuh kartu grafis. Outputnya dicatat di manifest yang sama; generator headless mempertahankan catatan itu saat menulis ulang manifest. Karena dirender GPU, file PNG bisa berbeda tipis antar mesin.

Sheet model berisi tampak samping, depan, belakang, tiga perempat, siluet, pose hero, palet, dan skala setengah meter. Folder `generated/references/` diberi `.gdignore` agar tidak diimpor sebagai konten game.

### D-035 — Ambience dirender menjadi loop

Section 175.2 menyarankan `AudioStreamGenerator` untuk stream kontinu. Menyintesis 48.000 sampel per detik di GDScript setiap saat terlalu mahal untuk Web dan Android. Lapisan kontinu (air, angin) disintesis sekali menjadi loop mulus 6–8 detik pada 16 kHz, dikerjakan bertahap dengan anggaran 3 ms per frame agar tidak tersendat. Kicau burung adalah one-shot terpisah dengan jeda acak 5–12 detik, sehingga ambience tidak terdengar seperti loop pendek (Section 108).

Tetap 100% dari kode: tidak ada file audio. Musik danau masih diam sampai mesin musik prosedural dibuat di Milestone 6.

### D-036 — Tombol Music dan Sound di Pause

Section 90 meminta toggle MUSIC dan SOUND. Toggle mengubah setting volume yang sama dengan slider: OFF menjadi 0, ON kembali ke nilai default. Nilai itu tersimpan seperti setting lain.

### D-037 — Teks dan ikon di atas dunia 3D

Prompt, banner, dan judul menu tampil langsung di atas scene 3D, jadi memakai teks terang dengan outline gelap agar terbaca di atas air, rumput, maupun kanopi pohon. Ikon digambar dengan `_draw()` dari garis, busur, dan poligon (Section 184.11); tidak ada file gambar ikon.

### D-038 — Penempatan kontrol dengan `UiTokens.anchor_at()`

Mode "minimum size" pada preset anchor Godot mengabaikan `custom_minimum_size`, sehingga tombol yang lebih besar dari teksnya menggantung di luar anchor dan bisa terpotong tepi layar. Helper `anchor_at()` mengukur kontrol dulu lalu menempatkannya dengan ukuran itu.

### D-039 — Tool QA memancing

Hanya di debug build: paksa tangkapan, waktu tunggu 0,5 detik, dan bot reel yang menahan saat marker di bawah tengah zona. Semuanya override runtime dan tidak pernah disimpan (Section 178.3). Langkah otomatis lewat command line dijelaskan di `README_TESTING.md`.

### D-040 — Validasi aset

Model hasil generator sekarang wajib untuk keenam ikan dan ketiga sampah; Boot gagal bila ada yang hilang. Potret Fish Book baru diwajibkan setelah dirender di Milestone 3 (`require_portraits`). Ini menggantikan flag tunggal di D-018.

## Milestone 3 — Market, ekonomi, upgrade, Book, Records

### D-041 — Event cerita sebelum Story scene ada

Target Milestone 3 adalah antrean trigger tanpa cutscene final. Selama `story.tscn` belum ada, event yang terpilih saat keluar Market langsung diselesaikan seolah di-skip: ditandai sudah dilihat, unlock-nya diterapkan, chapter diperbarui, lalu disimpan. Dengan begitu Fish Book tetap terbuka di lifetime debt Rp 600,000 walaupun adegannya belum bisa ditonton.

Event yang membuka sesuatu diumumkan lewat dialog singkat (`story.notice.<id>`). Saat ini hanya `story_debt_600k`. Begitu Story scene ada di Milestone 8, `MarketController.leave_market()` menyerahkan event ke `StoryDirector.play_event()` dan dialog ini tidak dipakai lagi.

### D-042 — Tutorial Market

`story_first_market` (Section 173.6) ditandai selesai pada kunjungan pertama, karena adegannya belum ada. Bagian yang bisa dimainkan sudah ada: tiga petunjuk berurutan dari Section 183.20 (`SELL YOUR CATCH`, `OPEN THE DEBT TAB`, `PAY Rp 10,000`) dan tombol pembayaran Rp 10,000 di tab Debt.

Petunjuk tidak mengunci apa pun; pemain boleh mengabaikannya dan pergi. Tutorial selesai (`market_seen`) setelah pembayaran hutang pertama, berapa pun jumlahnya, lalu muncul `UPGRADES CAN WAIT — OR NOT. YOUR CHOICE.` selama 6 detik. Dialog Darto dan Bu Yati di Section 183.5 menunggu sistem dialog.

### D-043 — Aturan antrean event

- Hanya event bertanda `market_event` yang dievaluasi setelah transaksi. Prolog, ikan pertama, dan ending punya alur sendiri (Section 177).
- Prioritas: 100k 400, 300k 450, 600k 500, 1000k 550, 1400k 600, 1650k 650, kemenangan pertama atas Arowana 800, hutang lunas 1000. Bila sama: urutan masuk antrean, lalu urutan abjad.
- `story_debt_paid` menggantikan keenam milestone hutang. Event yang digantikan ditandai sudah dilihat dan dikeluarkan dari antrean, sehingga tidak pernah diputar setelah ending.
- Satu event per kunjungan. Kunjungan dihitung saat scene Market dibuka (`begin_market_visit()`).
- `DataValidator.validate_story_events()` memeriksa ID, tipe trigger, prioritas, dan rujukan `supersedes` saat Boot.

### D-044 — Urutan dan kunci transaksi

Setiap transaksi berjalan: validasi → ubah `GameState` → evaluasi trigger cerita → autosave → sinyal ke UI. GDD memberi dua urutan: Section 169.12 menaruh evaluasi trigger setelah autosave dan refresh UI, Section 171.13 menaruhnya sebelum save. Yang dipakai urutan 171.13, supaya antrean event ikut tersimpan bersama transaksinya dan tidak hilang bila aplikasi ditutup tepat setelahnya. Hasil yang dilihat pemain sama.

Setelah transaksi diterima, `MarketController` menolak transaksi berikutnya selama 250 ms. Tap ganda tidak membeli atau membayar dua kali (MKT-010).

Bila autosave gagal, state tetap di memori dan muncul dialog RETRY SAVE / CONTINUE WITHOUT SAVING (Section 176.8). Keluar dari Market menunggu dialog itu ditutup.

### D-045 — Tombol pembayaran hutang

- Tombol nominal aktif bila cash cukup untuk nominal itu, atau cukup untuk melunasi sisa yang lebih kecil. Jumlah yang dibayar selalu dibatasi cash dan sisa hutang.
- PAY CUSTOM memakai tombol langkah −10K, −1K, +1K, +10K di sekitar tombol bayar. Tidak ada kolom ketik: keyboard virtual di Web dan Android menutupi layar dan menambah banyak kasus tepi untuk hal yang jarang dipakai.
- PAY ALL AVAILABLE langsung membayar tanpa konfirmasi, seperti yang tertulis di Section 79. Jumlahnya ditampilkan di atas tombol sebelum ditekan.
- Tombol di halaman ini setinggi 48 px (batas minimum sentuh), bukan 56 px, agar baris ledger tetap terlihat di atasnya pada 720p.

### D-046 — Tata letak Market

Ledger berada di kanan pada layar lebar (48% lebar, 500–640 px) dan di bagian bawah pada layar tinggi (mulai 37% dari atas). Warung, Bu Yati, dan Darto tetap terlihat di sisanya; set punya satu marker kamera untuk tiap bentuk layar.

Tab digambar sebagai pembatas buku besar: tab yang terbuka sewarna halaman dan tanpa garis bawah. Tab FISH BOOK selalu ada; sebelum dibuka cerita, halamannya berisi satu kalimat.

Tidak ada interaksi berjalan di Market (Section 176.16). LEAVE MARKET adalah satu-satunya jalan keluar selain Quit to Menu di Pause.

### D-047 — Fish Book dan potret

- Entri terbuka setelah kemenangan duel pertama atas ikan itu (`discovered`). Sebelum itu: siluet, `???`, dan `Not beaten yet.` Angka pertemuan tetap ditampilkan bila sudah pernah bertemu.
- Potret dirender oleh `reference_sheet_generator.gd` ke `generated/textures/fish_book/tex_fishbook_<id>.png`: 512×288, latar transparan, ikan menghadap kanan. Siluet memakai potret yang sama lewat `shaders/ui_silhouette.gdshader`, jadi tidak ada file kedua.
- Potret sekarang wajib untuk keenam ikan; `GameData.validate_all()` tidak lagi punya parameter `require_portraits`. Ini menutup D-018 dan D-040.
- Belum ada duel, jadi di build ini Fish Book hanya terisi lewat tool debug. Datanya sudah dicatat `GameState.record_fish_win()` sejak Milestone 1.

### D-048 — Records

Keenam belas baris mengikuti Section 83. `Lifetime Fish Sales` menampilkan statistik `lifetime_sales`, yaitu seluruh hasil penjualan termasuk sampah; skema save hanya punya satu angka penjualan. Play time sekarang juga dihitung selama berada di Market.

### D-049 — Set Market

- Kesembilan prop Section 72 dibuat sebagai scene tersendiri dan dipasang di set sebagai instance. `GeneratorIo` berhenti mengklaim node di dalam instance, sehingga file set hanya menyimpan referensi.
- Papan harga dan spanduk tidak memuat tulisan. Teks di tekstur 3D tidak bisa diterjemahkan atau diperbesar, dan semua teks pemain harus lewat tabel teks.
- Motor Bu Yati (Section 72) belum ada. Ia dibuat bersama motor Darto oleh `vehicle_builder` di Milestone 9.
- Baling-baling kipas adalah node terpisah dan berputar terus (Section 172.9).
- Reaksi Bu Yati: menimbang lalu menghitung uang saat penjualan, menghitung uang saat upgrade, menoleh ke Darto saat hutang dibayar. `deadpan_blink` adalah anggukan kecil karena wajahnya tidak punya kelopak mata.

### D-050 — Audio Market

- Tiga resep baru di `SfxRenderer`: `tick_cluster` (`ui_sell`), `two_note` (`ui_purchase`), `chime` (`ui_debt_ding`), mengikuti Section 175.7. `ui_save` bersifat opsional dan tidak dibuat.
- `AmbienceEngine` sekarang menyusun ambience per tempat. Warung punya tiga lapisan: radio, dengung freezer, dan angin yang sama dengan danau dengan volume lebih rendah. Kicau burung tetap ada, lebih pelan.
- Radio (Section 175.12) adalah loop 9,6 detik: melodi pentatonik hasil jalan acak ber-seed tetap, ketukan sederhana, dibatasi ke pita tengah, dengan flutter amplitudo. Bukan lagu yang ada.
- Loop warung dirender saat pemain masih di danau, sehingga sudah siap ketika Market dibuka.
- State musik `market` masih diam sampai mesin musik Milestone 6.

### D-051 — Tool QA Market

Langkah command line baru untuk debug build: `--mm-goto`, `--mm-cash`, `--mm-debt-left`, `--mm-bucket`, `--mm-win`, `--mm-story`. Semuanya menandai `DEV DIRTY STATE`, jadi tidak ada yang tersimpan. Halaman Market ikut diperbarui bila cash, hutang, ember, atau upgrade berubah dari luar transaksi.

### D-052 — Banter Market ditunda

Banter Bu Yati dan Darto (Section 183.17) membutuhkan kotak dialog, yang dibuat di Milestone 8. Belum ada di build ini.

## Milestone 4 — Tinju

### D-053 — Simulasi dengan tick tetap

`BoxingController` maju dalam tick 1/120 detik, dengan frame panjang dibatasi 0,1 detik. Jendela pukulan dan dodge jadi sama panjang di frame rate berapa pun (Section 176.17), dan seed yang sama dengan input yang sama selalu menghasilkan pertarungan yang sama. Ronde dibuka dengan jeda 1,2 detik sebelum jam berjalan.

### D-054 — Aturan dodge

GDD menetapkan jendela perfect dan jendela counter, tetapi tidak menetapkan kapan sebuah dodge dianggap menjawab serangan. Aturannya:

- Dodge pertama selama telegraph adalah jawabannya. Darto menahan posisi miring itu sampai pukulan tiba. Arah yang salah tidak bisa diperbaiki dengan menekan lagi.
- Dodge yang ditekan pada 180 ms terakhir sebelum impact adalah Perfect Dodge; lebih awal dari itu adalah dodge biasa.
- Dodge di luar telegraph hanya langkah 0,32 detik dan tidak menjawab apa pun.
- Begitu pukulan meleset, Darto langsung bebas membalas.

### D-055 — Block dan counter

- Di luar jendela counter ikan selalu mem-block: pukulan hanya masuk 40% (Section 45).
- Di dalam jendela counter setiap pukulan yang mendarat dikalikan 2,0× atau 2,4×. Jendela bisa memuat lebih dari satu pukulan bila waktunya cukup.
- Pukulan pemain tidak menghentikan serangan ikan. Bila Darto terkena saat pukulannya belum mendarat, pukulan itu batal.

### D-056 — Angka yang tidak ada di GDD

Hit stun Darto 0,45 detik dan lama dodge 0,32 detik diambil dari panjang clip di Section 172.2. Dua angka dipilih sendiri: ikan butuh 0,55 detik untuk kembali siap setelah pukulannya masuk, dan jeda pembuka ronde 1,2 detik.

### D-057 — Sudden death

Saat persentase HP sama persis di detik ke-60, pertarungan lanjut tanpa jam. Pukulan ikan yang masuk mengalahkan pemain; pukulan pemain di jendela counter mengalahkan ikan. Pukulan yang di-block tidak dihitung dan tidak memberi damage, karena Section 48 meminta "serangan pertama yang berhasil".

### D-058 — Temuan balance: menekan tombol terus-menerus

Diukur dengan 20 seed per ikan, pemain yang hanya menekan JAB tanpa pernah menghindar:

| Ikan | Hanya JAB | Hanya CROSS | Bermain benar |
|---|---|---|---|
| Bruiser Catfish | menang 20/20, 6,3 dtk | menang 20/20 | menang 20/20, 5,8 dtk |
| Gym-Rat Tilapia | menang 20/20, 8,4 dtk | menang 20/20 | menang 20/20, 5,9–8,6 dtk |
| Shady Gourami | menang 20/20, 9,7 dtk | menang 20/20 | menang 20/20, 5,8–8,4 dtk |
| Golden Carp | menang 20/20, 11,4 dtk | menang 20/20 | menang 20/20, 6,2–11,3 dtk |
| Snakehead Sergeant | menang 13/20 | kalah 20/20 | menang 20/20, 8,6–14,0 dtk |
| Don Arowana | kalah 20/20 | kalah 20/20 | menang 20/20, 7,9–14,4 dtk |

Dengan angka GDD apa adanya (block 40%, tanpa hukuman lain), empat ikan pertama bisa dikalahkan tanpa membaca telegraph sama sekali. Ini bertentangan dengan niat Section 41 ("player tidak diminta spam attack"), tetapi mengikuti angkanya. **Tidak ada yang diubah**; mengubah angka block atau menambah hukuman adalah revisi GDD dan menunggu keputusan pemilik project. Simulasi balance resmi ada di Milestone 10.

### D-059 — Komposisi ring

- Kamera berada di belakang-kanan Darto. Darto di kiri depan, ikan di kanan menghadapnya, sehingga keduanya terlihat utuh (Section 176.14).
- Ikan berdiri di atas bangku pojok (`prop_boxing_corner_stool`), setinggi dada Darto. Tanpa itu ikan 80 cm tertutup punggung Darto.
- Sisi ring yang menghadap kamera tidak diberi tali, supaya tidak ada tali yang melintang di depan pertarungan.
- Ring berada di tepi danau; ambience yang terdengar adalah ambience danau.

### D-060 — Clip tinju

- Clip serangan ikan memakai jam ternormalisasi: telegraph mengisi 0,0–1,0 dan dimainkan pada kecepatan 1 / `boxing_telegraph_sec`, jadi lama ancang-ancang di layar selalu sama dengan hitungan aturan (Section 172.6). Setelah impact clip berjalan pada kecepatan normal.
- Tiga variasi serangan (lurus, hook, dari atas) masing-masing punya versi cermin: clip polos untuk "dodge kiri", `_mirror` untuk "dodge kanan". Pose ancang-ancang dicapai di seperempat pertama telegraph lalu ditahan.
- Pukulan pemain yang di-block tidak pernah memotong clip ancang-ancang.
- Gerak khas tiap spesies (Section 172.7) baru berupa tempo dan tinggi lompatan kuda-kuda. Sisanya menyusul di Milestone 7.
- Semua ikan sekarang punya sarung tinju. Potret Fish Book dirender tanpa sarung.

### D-061 — Hasil duel sebelum Result scene ada

Result scene dan Wheel adalah Milestone 7. Sampai saat itu:

- Ikan yang mendarat langsung dibawa ke tinju.
- `DuelOutcome.commit()` adalah satu-satunya tempat hasil duel mengubah game: menang menambah ikan ke ember, Fish Book, dan statistik; kalah hanya mencatat kekalahan. Lalu disimpan.
- `DuelResultOverlay` menampilkan teks Section 88 dengan tombol CONTINUE yang menekan dirinya sendiri setelah 5 detik.
- Keluar ke menu di tengah duel membuang ikan itu tanpa mencatat apa pun.

### D-062 — Pelajaran tinju pertama

Duel pertama memberi petunjuk satu baris yang diambil dari teks How To Play (Section 183.19). Kalah di duel itu tidak dicatat dan langsung diulang (Section 176.10). Dialog Catfish dan Darto untuk momen ini (Section 183.4) menunggu sistem dialog; teks layar ulang `THAT WAS ROUGH.` diambil dari dialog itu, sedangkan `No harm done. Again.` ditulis sendiri.

### D-063 — HUD tinju

- Arah dodge ditunjukkan dengan tiga cara sekaligus: bentuk chevron, sisi tempat chevron berada, dan tulisan `DODGE LEFT` / `DODGE RIGHT`. Momen perfect ditandai chevron kedua dan bagian akhir bar yang diberi takik dan arsiran. Tidak ada informasi yang hanya berupa warna (Section 189.5).
- Pemain keyboard melihat nama keempat tombol di bawah layar; teksnya dibaca dari InputMap, jadi mengikuti remap.
- Layout sentuh memberi empat tombol: dodge di kiri, pukulan di kanan. Di portrait tombol menempati 38% bawah layar (Section 94).
- Opsi menukar kelompok tombol kiri/kanan untuk kidal (Section 189.12) belum ada.

### D-064 — Audio tinju

Tujuh preset Section 175.8. Enam memakai resep yang sudah ada; `box_ko` memakai resep baru `tom_sequence`. Telegraph tidak punya suara sendiri karena GDD tidak mendaftarkannya. Musik tinju masih diam sampai Milestone 6.

### D-065 — Tool QA tinju

Debug build: bot duel (`BoxingBot`, membaca snapshot yang sama dengan HUD dan hanya memakai dua permintaan yang dimiliki pemain), paksa arah serangan, paksa hasil, dan `--mm-duel` untuk langsung masuk ring.
