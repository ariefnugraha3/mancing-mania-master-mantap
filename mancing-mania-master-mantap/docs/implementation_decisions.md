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

Duel pertama memberi petunjuk satu baris yang diambil dari teks How To Play (Section 183.19).

Revisi 6.10 mengganti aturan lama. Dulu kekalahan di duel ini tidak dicatat dan langsung diulang dengan layar `THAT WAS ROUGH.` / `TRY AGAIN`. Kini kekalahan di duel pertama sama dengan kekalahan lain: ikan lepas, kekalahan tercatat, dan layar hasil menampilkan THE FISH GOT AWAY. Petunjuknya tetap muncul di duel tinju berikutnya sampai pemain menang sekali, karena `boxing_seen` baru diset saat menang. Teks layar ulang dan `DuelResultOverlay.show_retry()` dihapus.

### D-063 — HUD tinju

- Arah dodge ditunjukkan dengan tiga cara sekaligus: bentuk chevron, sisi tempat chevron berada, dan tulisan `DODGE LEFT` / `DODGE RIGHT`. Momen perfect ditandai chevron kedua dan bagian akhir bar yang diberi takik dan arsiran. Tidak ada informasi yang hanya berupa warna (Section 189.5).
- Pemain keyboard melihat nama keempat tombol di bawah layar; teksnya dibaca dari InputMap, jadi mengikuti remap.
- Layout sentuh memberi empat tombol: dodge di kiri, pukulan di kanan. Di portrait tombol menempati 38% bawah layar (Section 94).
- Opsi menukar kelompok tombol kiri/kanan untuk kidal (Section 189.12) belum ada.

### D-064 — Audio tinju

Tujuh preset Section 175.8. Enam memakai resep yang sudah ada; `box_ko` memakai resep baru `tom_sequence`. Telegraph tidak punya suara sendiri karena GDD tidak mendaftarkannya. Musik tinju masih diam sampai Milestone 6.

### D-065 — Tool QA tinju

Debug build: bot duel (`BoxingBot`, membaca snapshot yang sama dengan HUD dan hanya memakai dua permintaan yang dimiliki pemain), paksa arah serangan, paksa hasil, dan `--mm-duel` untuk langsung masuk ring.

## Milestone 5 — Panco

### D-066 — Dorongan ikan

GDD menetapkan Arm Strength, durasi dan cooldown burst, tetapi tidak menetapkan rumusnya. Di `ArmWrestleConfig`:

- Dorongan tetap ikan = Arm Strength × 0,12 posisi/detik (Bruiser Catfish 5,0; Don Arowana 10,1).
- Sebelum burst ikan menegang 0,7 detik (peringatan). Burst menambah dorongan sebesar (0,5 + 0,2 × tier) kali dorongan tetapnya.
- Durasi burst 0,65–1,15 detik dan cooldown 3,0–5,5 detik sesuai Section 55.

Angka dipilih dari simulasi 20 seed per ikan:

| Gaya pemain | Hasil |
|---|---|
| Tidak menekan | kalah melawan semua ikan |
| 5 tekan/detik | menang sampai Golden Carp, kalah melawan Snakehead dan Arowana |
| 7 tekan/detik (nyaman) | menang melawan semua ikan; Arowana tepat di detik terakhir |
| 10 tekan/detik | menang melawan semua ikan dalam 5–8 detik |

Section 176.13 meminta tidak ada keharusan melebihi kecepatan nyaman; 7 tekan/detik cukup untuk semua ikan.

### D-067 — Batas 10 tekan/detik

Batasnya berupa token bucket: satu token per tekan, terisi 10 per detik, maksimal 2 tersimpan. Interval minimum 0,1 detik sempat dicoba, tetapi itu membuat orang yang menekan 14 kali/detik hanya mendapat 7 karena setiap tekan kedua jatuh terlalu cepat. Itu hukuman, dan Section 176.13 melarangnya. Tekan yang diabaikan tidak memakan stamina.

### D-068 — Temuan balance: istirahat tidak pernah lebih baik

Dengan angka GDD (regen hanya setelah 0,35 detik tanpa tekan, tenaga minimum 42%), terus menekan selalu menghasilkan dorongan lebih besar daripada berhenti untuk memulihkan stamina. Petunjuk "stop briefly to recover" dari How To Play tetap benar dalam arti tenaga naik lagi, tetapi secara angka istirahat tidak menguntungkan. Tidak diubah; masuk ke simulasi balance Milestone 10.

### D-069 — Sudden Grip dan seri

- Di detik ke-32, posisi dalam ±2 masuk Sudden Grip: paling lama 5 detik tambahan, yang pertama mencapai ±5 menang.
- Setelah itu dibandingkan posisi dengan tiga desimal ("0.000"). Bila tepat nol: ikan non-boss kalah (pemain menang), Don Arowana meminta rematch 10 detik dari tengah dengan stamina penuh.
- Bila rematch juga berakhir tepat nol, pemain menang. GDD tidak mengatur kasus ini.

### D-070 — Tampilan panco

- Kamera di belakang bahu kanan Darto. Saat Darto unggul, tangan miring ke kiri Darto, yaitu kiri layar; bar posisi meletakkan ujung Darto di kiri supaya keduanya bergerak ke arah yang sama.
- Kemiringan lengan bawah Darto ditulis setelah clip tubuh setiap frame, jadi lengan selalu menunjukkan posisi sebenarnya sementara tubuh menunjukkan usaha (push light/hard, recover). Ini menggantikan blend parameter Section 172.3 dengan hasil yang sama.
- Sirip ikan yang menggenggam adalah tabung yang direntangkan dari tulang sirip ke kepalan Darto setiap frame, sehingga tangan selalu bertemu walaupun ukuran ikan berbeda jauh. Untuk Don Arowana tabung ini panjang dan terlihat aneh.
- Ikan berdiri di atas meja; sarung tinjunya disembunyikan.

### D-071 — Pemilihan duel sebelum Wheel

Selama Wheel belum ada (Milestone 7): duel pertama selalu tinju (Section 176.10). Sesudahnya duel dipilih dari seed encounter dengan peluang sama di antara duel yang ada di build, jadi pilihannya tetap sebelum apa pun ditampilkan (Section 38).

### D-072 — Audio panco

Enam suara Section 175.9: derit meja (`creak`, bervariasi), regangan tangan (`noise_sweep`, bervariasi), klik MASH yang makin pelan saat laju naik, denyut naik sebelum burst (`rising_pulse`), fanfare parodi menang (`fanfare`), dan dua nada turun saat kalah (`two_note_down`). Musik panco masih diam sampai Milestone 6.

## Milestone 6 — Joget dan musik prosedural

### D-073 — Musik dirender, bukan disintesis langsung

Section 175.2 menyarankan `AudioStreamGenerator` untuk stream kontinu. Mensintesis banyak suara pada 48 kHz di GDScript setiap frame terlalu mahal untuk Web dan Android. Musik dirender lebih dulu ke `AudioStreamWAV` di memori pada 22.050 Hz mono:

- setiap nada (instrumen, nada, panjang) disintesis sekali dan dipakai ulang;
- jadwal nada dicampur sedikit demi sedikit dengan anggaran 4 ms per frame;
- loop state (danau, menu, tinju, panco) dirender di latar saat pertama dibutuhkan;
- lagu joget dirender saat layar "GET READY", sebelum duel dimulai.

Semuanya tetap dari kode dan angka; tidak ada file audio. Jadwal musik dibuat sebelum duel (Section 175.10).

### D-074 — Jam lagu

Jam lagu = posisi pemutaran + waktu sejak mix terakhir − latensi output, dan tidak pernah mundur. Penilaian memakai jam ini, bukan delta frame. Tombol lajur dibaca di `_unhandled_input` dan sentuhan di `button_down`, jadi waktunya diambil saat input datang. Input tetap baru sampai ke game di awal frame berikutnya, sehingga di 30 FPS rata-rata terlambat sekitar 16 ms; offset kalibrasi mengimbanginya.

### D-075 — Chart

- Seed chart = seed duel (save seed + penghitung duel) dicampur id ikan (Section 58).
- Nada diambil dari pukulan kendang, snare, dan melodi di timeline lagu, jadi setiap nada adalah sesuatu yang terdengar. Kendang rendah → lajur 1, kendang tinggi → lajur 2, snare → lajur 3, melodi → lajur 4; tiga nada beruntun di satu lajur digeser ke lajur sebelah.
- Kepadatan naik dari 1,3 ke 2,4 nada per detik; jarak minimum seperdelapan ketukan.
- Bar pertama adalah hitungan masuk tanpa nada. Dua bar cadangan di akhir lagu menampung encore.

### D-076 — Penilaian dan skor

- Tekanan menilai nada terbuka terdekat di lajurnya dalam jendela GOOD. Tekanan tanpa nada di dekatnya tidak dihukum.
- Sebelum menilai, nada yang jendelanya sudah lewat dinyatakan MISS, sehingga combo putus dalam urutan yang benar.
- Bonus combo dihitung dari combo setelah nada itu: nada ke-10 berturut-turut mendapat +10%.

### D-077 — AI ikan

Peluang per nada dari Rhythm Skill: x = (skill − 50) / 45, dibatasi 0–1; PERFECT 0,18 + 0,42x, GREAT 0,32, MISS 0,20 − 0,16x, sisanya GOOD. Bruiser Catfish (62) kira-kira 29/32/23/16%, Don Arowana (90) 55/32/7/6%. Penari yang selalu GREAT mengalahkan semua ikan; pemain yang tidak menekan selalu kalah.

### D-078 — Seri dan encore

Urutan Section 63: skor, jumlah PERFECT, max combo, lalu encore empat nada. Bila setelah encore masih seri sepenuhnya, pemain menang; GDD tidak mengatur kasus ini.

### D-079 — Pause dan audio di Web

Duel joget baru dimulai setelah lagu siap dan audio sudah bisa didengar (Section 175.16). Setiap pause, termasuk karena jendela kehilangan fokus, memulai ulang joget dari hitungan awal dengan chart yang sama.

### D-080 — Kalibrasi

Wizard di Settings: click track 100 BPM, 16 ketukan; dua tekanan pertama diabaikan; median selisih ke ketukan terdekat, dibatasi ±150 ms (Section 189.10). Offset input menggeser acuan penilaian; offset visual hanya menggeser gambar nada. Keduanya juga bisa diatur manual per 5 ms.

### D-081 — Tampilan joget

Di landscape lajur berada di kanan (lebar 460 px) agar Darto dan ikan terlihat di kiri. Di portrait lajur memenuhi lebar layar di 58% bawah. Setiap lajur punya bentuk sendiri (lingkaran, belah ketupat, kotak, segitiga) selain warnanya. Ikan diperbesar 1,5× di panggung dan menghadapkan sisinya ke kamera.

## Milestone 7 — Suwit, Wheel, Result, kepribadian ikan

### D-082 — Ronde Suwit

- Pilihan ikan, apakah tell-nya jujur, dan kebohongan yang akan dipakai ditetapkan di awal hitungan; tell muncul 1,1 detik kemudian (SUWIT-003).
- Pilihan pemain dikunci saat pertama ditekan. Ronde selesai saat hitungan habis, bukan saat pemain memilih.
- Gerakan PANIC PICK diundi di awal ronde, jadi terlambat memilih tidak menggeser urutan acak ronde berikutnya.
- Charm hanya bisa dipakai saat hitungan berjalan, satu per ronde, dan tidak pernah mengubah pilihan ikan.
- Setelah ronde, hasil ditampilkan 1,4 detik sebelum hitungan berikutnya.

### D-083 — Wheel

- Hasil dipilih dari seed encounter tangkapan itu (jadi tangkapan yang sama selalu mendarat di duel yang sama), lalu putaran diatur agar berhenti tepat di salah satu dari dua segmen duel itu.
- Langkah waktu putaran dibatasi 0,1 detik per frame; frame yang sangat lambat memperlambat putaran tetapi tidak mengubah hasil.
- Wheel pertama di sebuah save selalu tinju dan tidak bisa dilewati (Section 176.10, WHEEL-003).
- Menahan aksi utama 0,6 detik melewati putaran; reveal 0,8 detik tetap ditampilkan.

### D-084 — Dialog ikan

- Teks GDD 166 disimpan apa adanya. Pool ada di tabel teks (`dialogue.<ikan>.<pool>.<n>`); percakapan pertama tiap ikan adalah `DialogueSequence` di `data/dialogue/fish_<id>.tres`.
- Pilihan baris memakai seed encounter dengan aliran acak sendiri; dialog tidak pernah menyentuh RNG gameplay (diuji).
- Percakapan pertama diputar saat ikan spesies itu pertama kali mendarat; sesudahnya satu baris LAND. Tangkapan menunggu sampai dialog selesai sebelum Wheel.
- Kemenangan pertama atas Don Arowana memakai percakapan khusus Section 166.6 di layar Result. Adegan lengkapnya (Section 173.8) dibuat di Milestone 8.
- Dialog hanya maju dengan tap atau tombol; Esc melewati semuanya. Kecepatan munculnya teks mengikuti setting `dialogue_speed`.

### D-085 — Scene Result

- Panggungnya tepi danau di tempat Darto memancing. Saat menang, ikan terkulai di dekat ember; saat kalah, ikan melompat kembali ke danau.
- Auto-continue 5 detik (Section 88) baru berjalan setelah dialog selesai, supaya dialog penting tidak maju sendiri.

### D-086 — Aksesori khas

Sesuai Section 69: headband merah-putih (nila), kacamata hitam (gurami), kalung emas besar (ikan mas), ikat kepala militer dengan lencana (gabus), rantai perak tipis, bekas luka, dan ujung sirip ekor gelap (arwana). Semuanya mesh hasil generator di `AccessoryMeshes/Signature`. Gerak khas spesies (Section 172.7) masih sebatas tempo, lompatan, dan goyangan kuda-kuda.

### D-087 — Tool QA

`--mm-auto-dialogue` membuat dialog maju sendiri setiap 0,25 detik (debug build saja), supaya alur penuh bisa diuji tanpa tangan.

## Milestone 8 — Cerita, cutscene, ending

### D-088 — Timeline cerita sebagai data

Seluruh staging cerita ada di `data/story/story_timelines.json`: set, aktor (penanda set atau posisi relatif), prop, kamera, dan daftar langkah. Setiap teks yang terlihat adalah kunci di `ui_text.tres`, jadi semua teks Inggris tetap di satu tabel. `StoryController` membaca timeline itu dan menjalankan langkah satu per satu. Kamera hanya cut statis, tanpa orbit (Section 173).

### D-089 — Skip

Menahan konfirmasi, sentuhan, atau tombol cast selama `skip_hold_sec` (bawaan 0,8 detik) mengakhiri event. Event yang dilewati tetap dicatat seen, unlock dan chapter tetap berlaku, event yang di-supersede tetap pensiun, dan rute berikutnya sama dengan menonton sampai habis.

### D-090 — Event di dalam scene lain

Tiga event diputar di tempat kejadiannya, bukan di scene Story, supaya alur tidak terputus:

- `story_first_fish`: percakapan lele di danau sebelum Wheel pertama.
- `story_first_market`: sambutan saat warung dibuka, dua baris setelah jualan pertama, empat baris setelah bayar pertama (tutorial Market tetap jalan).
- `story_arowana_first_win`: percakapan di layar Result (D-084) ditambah baris terakhir Darto; event selesai di sana sehingga Market tidak memutarnya lagi. Jika pemain keluar sebelum dialog selesai, event tetap antre dan diputar di scene Story pada kunjungan Market berikutnya.

### D-091 — Rantai ending

`story_debt_paid` (prioritas 1000) diputar saat keluar Market. Setelahnya `story_final_family` langsung, lalu credits, lalu `story_postgame_unlock`, lalu danau. Unlock postgame menyetel `postgame_unlocked`, `ending_completed`, dan chapter `postgame`. Credits yang dibuka dari Main Menu kembali ke menu tanpa mengubah apa pun.

### D-092 — Free Fishing dan Family Savings

Free Fishing adalah permainan biasa tanpa hutang: semua sistem tetap jalan. Setelah postgame, tab Debt berganti nama SAVINGS dan menjadi FAMILY SAVINGS: uang tunai bisa disetor ke statistik `family_savings`. Tidak ada hadiah gameplay (Section 19).

### D-093 — CePatCash dan obrolan Market

- CePatCash: pengingat pertama paling cepat 18 menit setelah sesi dimulai, sesudahnya jeda acak 18–35 menit (seed dari waktu main). Hanya muncul saat Darto diam atau menunggu di danau, tidak saat dialog, duel, atau cutscene, dan berhenti setelah hutang lunas. Darto menjawab setiap notifikasi kedua.
- Obrolan Bu Yati: tidak di kunjungan pertama, satu kali tiap tiga kunjungan, tidak pernah saat ada event yang menunggu, tiga percakapan bergiliran.

### D-094 — Credits

Struktur mengikuti Section 183.22: judul, subjudul, tujuh kategori, kartu penutup dua baris. Satu pembuat mengisi semua peran, jadi namanya diulang (diizinkan 183.22); nama yang dipakai adalah nama pemilik project dan perlu dikonfirmasi. Isi SPECIAL THANKS tidak ditetapkan GDD dan ditulis untuk game ini.

## Milestone 9 — Art, UI/UX, aksesibilitas, performa

### D-095 — UI scale dan text scale

- UI SCALE (90/100/115/130%) memakai `content_scale_factor` jendela: semua control ikut membesar, dunia 3D dan FOV tidak berubah (Section 189.2). Layout yang memakai anchor dan safe area menyesuaikan diri dengan ruang kanvas yang mengecil.
- TEXT SCALE (100/115/130/150%) mengalikan semua ukuran font di theme project. Ukuran yang diset di kode lewat `UiTokens.outline_text` dan prompt danau memakai `DisplaySettings.text_size()`. Teks yang digambar langsung (lajur joget, Wheel) tidak ikut membesar; ukurannya mengikuti ukuran elemennya.
- Keduanya berlaku seketika saat diubah dan saat save dimuat.

### D-096 — Preset grafis

| | LOW | MEDIUM (bawaan) | HIGH |
|---|---|---|---|
| Resolusi 3D | 75% | 100% | 100% |
| Bayangan matahari | mati | hidup | hidup |
| Kepadatan rumput/alang-alang | 50% | 100% | 100% |
| MSAA 3D | mati | mati | 2× |

Arah seni tidak berubah di preset mana pun. Preset berlaku saat diubah dan setiap kali scene baru dibuka.

### D-097 — High Contrast HUD

Panel chip HUD menjadi tidak transparan dengan border lebih tebal dan gelap; outline teks HUD +4 px; marker tegangan dan border HUD +2 px; lajur joget mendapat tepi krem tebal dan bentuk not bergaris lebih tebal; bar strike diberi bingkai tegas; titik skor Suwit ikut menebal. Dunia 3D tidak berubah (Section 189.4).

### D-098 — Hold Assist panco

Menahan tombol menghasilkan 8 dorongan per detik; dorongan pertama tepat saat ditekan. Setiap dorongan lewat `request_mash()` yang sama, jadi stamina, batas 10 per detik, dan power band tidak berubah (Section 189.11). Teks tombol dan tutorial berganti menjadi HOLD.

### D-099 — Mode kidal

Danau: tombol Market pindah ke kanan bawah. Tinju: kelompok tombol menghindar dan memukul bertukar sisi; urutan di dalam kelompok tetap, jadi DODGE LEFT selalu yang kiri. Suwit dan joget tidak diubah (Section 189.12).

### D-100 — Remap keyboard

- Remap mengganti tombol keyboard sebuah aksi dan mempertahankan tombol mouse-nya, jadi klik tetap bisa melempar kail setelah tombol cast dipindah.
- F5, F11, F12, Tab, modifier, dan kombinasi Ctrl/Alt/Meta ditolak (dipakai browser atau OS).
- Tombol yang sudah dipakai aksi lain memunculkan pilihan SWAP atau CANCEL; SWAP memberikan tombol lama ke aksi lain sehingga tidak ada aksi tanpa tombol.
- Esc membatalkan penangkapan, kecuali saat sedang memetakan Back atau Pause.
- Hanya di Web dan desktop; Android tidak menampilkan bagian CONTROLS.

### D-101 — Polesan art

- Pose "melihat ponsel" Darto: tangan kanan di depan dada, kepala menunduk; model ponsel (`prop_phone`) dipasang ke tulang tangan saat clip ponsel diputar dan disembunyikan saat clip lain.
- Motor Darto dibangun ulang sebagai motor bebek: ban tipis, garpu depan, setang dengan grip, pelindung kaki, knalpot, lampu depan dan belakang.
- Rambut Rini dan Nisa: cincin bawah dipindah ke belakang wajah sehingga mata tidak tertutup.
- Nisa diskalakan pada root (skala Skeleton3D tidak berlaku untuk mesh ter-skin); scene Story mempertahankan skala bawaan aktor.
- Final keluarga dan event 1,65 juta: kursi plastik di bawah tokoh yang duduk.
- Titik skor Suwit: lingkaran penuh berbingkai untuk poin yang didapat, cincin kosong untuk yang belum; label "FISH" pindah ke tabel teks.

### D-102 — Pengukuran performa

`tools/perf/perf_probe.gd` membuka setiap scene lewat router di jendela nyata, menunggu 2,5 detik, lalu mengambil sampel 4 detik: FPS rata-rata, frame terburuk, draw call dan primitif maksimum, memori statis, memori video. Diakhiri 20 kali bolak-balik Danau ↔ Market untuk cek kebocoran (Section 190.4). Hasilnya di `docs/performance_report.md`. Ini baseline di mesin pengembang, bukan perangkat referensi Section 190.1.

## Milestone 10 — Balance, QA, release candidate

### D-103 — Simulasi balance

Bagian distribusi memakai kode game sendiri pada seed 1–100.000, jadi hasilnya pasti untuk build. Bagian ekonomi adalah model: peluang menang dari titik tengah Section 179.3, waktu per langkah diperkirakan dari timing game (lihat `docs/balance_report.md`). Model memakai `RandomNumberGenerator` sendiri dengan seed tetap per konfigurasi, jadi hasilnya bisa diulang.

### D-104 — Angka balance tidak diubah

Model menunjukkan ekonomi ~3× lebih cepat dari target Section 179.4–179.5 karena satu putaran tangkapan (waktu tunggu 4,5–9,5 dtk + duel) jauh lebih singkat daripada yang diandaikan target pendapatan. Section 179.9 dan 191.12 meminta perubahan angka authoritative dicatat di GDD, dan keputusan sebelumnya untuk D-058 adalah menunggu pemilik. Jadi angka tetap; usulan (harga lima ikan biasa ×0,22, Arowana tetap Rp300.000) dan hasil modelnya ada di laporan balance.

### D-105 — Build Web single-threaded

Preset Web memakai `thread_support=false` agar berjalan di itch.io tanpa header cross-origin isolation (Section 135). Musik prosedural sudah dirender bertahap dalam anggaran 4 ms per frame sejak Milestone 6, jadi tidak membutuhkan thread.

### D-106 — Android

Preset Android dibuat sesuai Section 135 dan 186.3, tetapi build belum dibuat: butuh path Android SDK dan JDK 17+ di Editor Settings Godot (pengaturan global milik pengguna, tidak diubah otomatis), template build Android di project, dan keystore rilis milik pemilik. Langkahnya di `README_BUILD.md`. versionCode release candidate 9901 agar rilis 1.0.0 tetap bisa memakai 10000.

### D-107 — Store art

Screenshot toko diambil dari scene asli lewat router. Jendela desktop tidak bisa lebih tinggi dari layar, jadi screenshot portrait dirender pada 590×1049 (9:16) lalu diperbesar ke 1080×1920; untuk listing final diambil ulang di perangkat. Feature graphic adalah Main Menu tanpa tombol pada 1024×500 asli. Layer ikon adaptive dibuat dari ikon generator (latar krem polos, ikon di zona aman 288 px).

### D-108 — Privasi di dalam game

Settings → PRIVACY AND LICENSES menampilkan ringkasan Section 187.7, kebijakan lengkap Section 187.6, dan teks lisensi Godot beserta daftar komponennya dari `Engine`, semuanya offline; tidak ada tombol yang membuka URL karena game tidak membuka koneksi apa pun. Email dukungan tetap placeholder `[PUBLISHER SUPPORT EMAIL]` sampai pemilik mengisinya; validator rilis menolak build publik selama placeholder itu ada.

## Revisi Visual 6.1 — Diorama "Warm, Cozy & Cute"

Seluruh visual dirombak mengikuti `../VISUAL_STYLE_GUIDE.md` atas permintaan pemilik (GDD header revisi 6.1, Section 194.4). Gameplay, balance, cerita, audio, dan save tidak berubah; UI 2D menyusul dirombak pada D-117–D-121.

### D-109 — Satu kamera diorama untuk semua scene

`scripts/visual/diorama_camera.gd` (`DioramaCamera`) menggantikan semua kamera perspektif: ortografis, yaw 45°, pitch 35°, `KEEP_WIDTH`, jarak 30 m, near 0,05, far 200. Setiap set membawa marker `CameraFocus` dengan metadata `width_landscape` / `width_portrait` (dan opsional `focus_portrait`), selalu di rentang zoom panduan 5,6–11,0 m. Panduan ditulis untuk bingkai portrait 720 px; game ini juga punya landscape 1280 × 720, jadi lebar landscape dipilih per scene agar diorama pas di ruang antara bar HUD (karakter ±100–170 px). Kamera tidak pernah shake; story memakai cut, dengan satu `glide_to` lembut yang menjadi cut saat Reduced Motion.

### D-110 — Rig tulang kaku, bukan node terpisah

Panduan Section 9.2 menyusun karakter dari node berpivot tanpa skeleton. Di sini tetap dipakai `Skeleton3D` kecil dengan **binding kaku** (setiap verteks ke satu tulang, kecuali torso/celemek yang di-blend di tulang punggung): tiap tulang berfungsi sebagai pivot node, hasil visualnya sama, satu karakter cukup satu draw call, dan seluruh klip duel GDD 172 (nama tulang, marker, durasi yang dikunci test) tetap berlaku. Klip tetap generated `AnimationPlayer`; napas idle dan squash & stretch adalah lapisan prosedural panduan Section 10.

### D-111 — Skala chibi dan anggaran

Darto 0,90 m (Rini ×0,93, Nisa ×0,885, Bu Yati ×0,91 lewat skala root). Panjang ikan 0,56–0,90 m sehingga ikan berdiri setinggi ±0,7–0,9 m tanpa `FISH_SCALE` di scene. Offset posisi di klip (jongkok, menghindar, duduk, KO) dihitung ulang untuk kaki chibi 0,17 m. Anggaran 500–2.000 segitiga dipenuhi dengan menurunkan segmen bagian kecil (mata, alis, kumis, tali); primitif utama memakai segmen panduan.

### D-112 — Tanpa shader kustom di dunia 3D

`lake_water.gdshader` dan `foliage_sway.gdshader` dihapus karena panduan 5.1 mewajibkan `StandardMaterial3D`. Air menjadi bidang berwarna verteks (dangkal → dalam) dengan garis air geometri yang melayang; goyangan pohon dan alang-alang menjadi transform node berbasis sinus di `AmbientMotion` (GDD 172.9). Satu-satunya shader yang tersisa adalah `ui_silhouette.gdshader` untuk UI Fish Book (2D, di luar cakupan panduan).

### D-113 — Kompensasi palet terhadap cahaya hangat

Matahari dan ambient sama-sama `#FFE3A8`, sehingga warna dasar bergeser ke kuning saat dirender. Hijau dan biru turunan (rumput, daun, air) dipilih sedikit lebih sejuk di data supaya hasil di layar tetap hijau hangat dan biru-hijau pastel. Warna khas tokoh di GDD 185 diperbarui dengan cara yang sama.

### D-114 — Komposisi duel

Tinju: Darto kiri-dekat dan ikan kanan-jauh secara diagonal agar tidak saling menutupi dan tidak tertutup widget telegraph; panah DODGE LEFT/RIGHT di HUD tetap acuan arah. Panco: meja persegi kecil dilihat dari sudut, Darto kiri dan ikan kanan, lengan sirip direntangkan sepanjang sumbunya sendiri (perbaikan `Basis.scaled()` yang sebelumnya menskalakan sumbu dunia). Joget dan Wheel: ikan tiga-perempat ke kamera supaya profil dan matanya terbaca. Ring tinju memakai potongan rumah boneka: tali hanya di dua sisi jauh.

### D-115 — Waktu cahaya

`DioramaStyle.apply_daylight()` menerapkan titik kunci panduan 6.3. Gameplay memakai 15:00; ending keluarga dan Main Menu setelah ending 17:36; Credits 18:00. Timeline cerita boleh memberi `"hour"`.

### D-116 — Test dan pemeriksaan visual

Test baru di suite `assets`: profil kamera, rig cahaya tiap set, larangan shader kustom/tekstur di aset 3D, material standar, tinggi dan anggaran karakter, cakram bayangan, meja warung di bawah garis dada. Test kamera lama (marker `CameraLandscape/CameraPortrait`, FOV) diganti pemeriksaan lebar bingkai `CameraFocus`. Preset grafis tidak lagi menyalakan bayangan; MEDIUM 2× MSAA, HIGH 4× (Android dibatasi 2×). Pemeriksaan visual dilakukan lewat screenshot `--mm-shot` di 1280 × 720 dan portrait untuk setiap scene, ditambah lembar referensi baru.

## Revisi UI 6.1 — "Cozy warung card"

Atas permintaan pemilik, UI 2D (menu, tombol, overlay, HUD, Market, dialog, Wheel) dirombak agar tidak lagi terlihat seperti placeholder dan serasi dengan dunia diorama (GDD header revisi UI 6.1, Section 167, 185.20).

### D-117 — Satu sumber gaya: `UiTokens` + `UiSkin`

Token warna mengikuti palet diorama (cream/vanilla, crust, caramel, cocoa, teal pastel) ditambah token kedalaman `EDGE_CREAM`, `EDGE_PAPER`, `SHADOW`, `BACKDROP`. `scripts/ui/ui_skin.gd` membuat semua StyleBox (tombol berlip, cincin fokus, kartu, well, pil, pita, badge, tab, bar) dan potongan font tebal. Generator theme (`ui_art_builder.gd`, versi 2) dan setiap HUD yang menata kontrol lewat kode memakai fungsi yang sama, sehingga rim, lip, sudut, dan bayangan selalu konsisten. Hampir semua `StyleBoxFlat.new()` buatan tangan di HUD diganti.

### D-118 — Tombol berlip yang tenggelam

Tombol digambar sebagai wajah dengan rim 3 px dan rim bawah 6 px (lip). State pressed menipiskan lip menjadi 2 px dan memakai `expand_margin_top` negatif sehingga wajah turun 4 px; content margin ikut bergeser agar label turun bersama wajah. Ukuran minimum normal dan pressed sama (dikunci test), jadi layout tidak melompat. Animasi skala tekan `GameButton` tetap berjalan di atasnya.

### D-119 — Font tebal dan ikon tanpa file

*(Bagian font digantikan oleh D-128–D-130, revisi 6.3.)* Tetap tanpa file font (GDD 184.12, test `default_font == null`): potongan bold/heavy adalah `FontVariation` tanpa `base_font` dengan `variation_embolden`. Ikon digambar prosedural oleh `IconPainter` pada grid 24 unit; `IconTexture` (subkelas `Texture2D`) membuatnya bisa dipakai sebagai `Button.icon` dan diwarnai theme, `UiIcon` memakainya untuk badge chip HUD. `GameButton.icon_id` memasang ikon cukup dengan id.

### D-120 — Gerak dekoratif dan run headless

Pop overlay, masuknya logo dan tombol Main Menu, goyang emblem, dan pantulan panah dialog dilewati saat Reduced Motion dan saat `DisplayServer` headless, supaya test tetap deterministik. Container mereset rotasi saat menata anak, jadi kemiringan pita subjudul diterapkan ulang pada `sort_children`.

### D-121 — Perbaikan yang ditemukan saat QA screenshot UI

- Bayangan kartu di dalam area yang di-clip (panel TabContainer di How to Play, ponsel cerita) terpotong menjadi pita persegi; kartu tersebut kini tanpa bayangan.
- Kartu dialog cerita kini menempel ke bawah dan tumbuh ke atas (`GROW_DIRECTION_BEGIN`), sebelumnya baris panjang mendorong kartu keluar layar; panah lanjut kini satu baris dengan prompt, tidak menimpanya.
- Pesan chat cerita menampilkan kunci mentah (mis. `story.story_debt_300k.01`) karena baris genap di `ui_text.tres` adalah alias ke baris sebelumnya. `TextDb.t()` kini mengikuti alias (maksimal 4 langkah). Bug ini sudah ada sejak RC1; test baru memeriksa setiap baris cerita.
- Tab ledger Market menimpa rim atas kartu sebesar `MarketHud.LEDGER_RIM` (4 px); toleransi test tata letak mengikuti konstanta itu, bukan angka 3 yang tertanam.
- Nama duel pada Wheel mengecil agar muat di segmennya ("ARM WRESTLING" sebelumnya terpotong).

## Revisi Mobile 6.2 — Game HP portrait

Atas permintaan pemilik, game ini menjadi game HP: portrait saja, Android dan iOS, HP dan tablet (GDD header revisi Mobile 6.2, Section 92–96, 122, 135, 167.7, 167.8, 169.7).

### D-122 — Kanvas dalam point, bukan piksel referensi 720

Kanvas portrait lama 720 × 1280 membuat satu "px" UI hanya ±0,54 pt di HP sungguhan: teks badan 18 px menjadi ±10 pt dan tombol 48 px ±26 pt, jauh di bawah pedoman (44 pt iOS, 48 dp Android). Kanvas kini 390 × 694 pt untuk HP dan 600 × 800 pt untuk tablet (`expand`), sehingga token UI yang ada (teks 18, tombol 48–56) langsung bermakna dp/pt. Alternatifnya, mengalikan semua token dan angka layout ×1,8 di kanvas 720, memberi hasil sama dengan perubahan jauh lebih banyak. Pembagian HP/tablet memakai rasio layar (≥ 0,62 = tablet) karena DPI tidak andal di desktop dan Web; kanvas tablet yang lebih lebar memberi ruang lebih dan tampilan sedikit lebih besar.

### D-123 — Jendela lebar menjadi kolom portrait

Desktop, browser landscape, dan foldable terbuka (> 0,8) memakai mode `KEEP` dengan kanvas 640 × 800, sehingga tampil sebagai kolom portrait dengan bilah di samping. Tidak ada lagi layout landscape untuk dirawat; build Web tetap ada sebagai build sekunder.

### D-124 — Safe area untuk Android dan iOS

`get_safe_rect()` memetakan `DisplayServer.get_display_safe_area()` ke kanvas lewat `get_final_transform()` (benar juga saat ada bilah), untuk Android dan iOS. `SafeAreaRoot`, overlay (CenterContainer di safe area), dialog cerita, dan ponsel cerita memakainya. `--mm-insets` dan `set_simulated_insets()` mensimulasikan notch dan home indicator di desktop untuk QA dan test.

### D-125 — Kamera: satu bingkai HP, tablet lebih lebar

`DioramaCamera` kini hanya punya `frame(focus, width)` dengan lebar HP dari metadata `width_portrait`; tablet memakai lebar × 1,25 (dibulatkan ke langkah zoom panduan) agar diorama tetap kebagian porsi layar. `width_landscape` di marker hanya dipakai lembar referensi. Inset HUD dalam point, atau porsi tinggi layar (≤ 1,0) untuk bottom sheet Market, Dance, dan Panco.

### D-126 — Layout jempol dan konten yang mengalir

Status dan Pause di atas, dunia di tengah, aksi di sepertiga bawah. Baris yang bisa terlalu lebar memakai `HFlowContainer` (chip memancing, tombol Sell/Debt) sehingga turun baris alih-alih terpotong; pada HP terkecil dengan UI 130% + teks 150% (kanvas 300 × 534 pt) halaman Market memindahkan deretan aksinya ke dalam area gulir (`MarketPanel.set_actions_scroll`) dan sheet naik menutupi warung. Test aksesibilitas menganggap tombol di halaman yang bisa digulir terjangkau bila halamannya di layar. `GameButton.set_side_padding()` diterapkan setelah tombol masuk tree agar memakai gaya variasinya (CTA/danger).

### D-127 — Preset iOS tanpa rahasia

Preset iOS berisi bundle ID, keluarga perangkat iPhone + iPad, iOS 14, ikon 1024, latar launch screen cream, dan tanpa usage description. Team ID, sertifikat, dan provisioning profile milik pemilik dan diisi di mesin macOS; `*.p12`, `*.mobileprovision`, `build/ios/`, dan `*.ipa` diabaikan git. `application/short_version` = MAJOR.MINOR.PATCH karena App Store menolak suffix `-rc`.

## Revisi Font 6.3 — Fredoka + Chewy

Atas permintaan pemilik, semua teks game memakai font yang bernuansa komedi tapi hangat, gratis, dan boleh dikomersialkan (GDD header revisi 6.3, Section 167.3, 184.12, 187.8). D-119 (font tanpa file) digantikan.

### D-128 — Dua typeface, satu peran masing-masing

Kandidat dari Google Fonts dirender berdampingan dengan gaya UI game: judul cat papan, tombol berlip, kartu dialog, dan teks kecil.

- Baloo 2 dan Playpen Sans ditolak karena line-height-nya sangat besar dan akan merusak layout HP.
- Gluten dan Sour Gummy ditolak karena teks badannya sulit dibaca dan angkanya janggal.
- Fredoka saja terlalu "rapi", nuansa komedinya kurang.

Pilihan akhirnya pasangan: **Chewy** (Apache 2.0) memberi komedi kartun pada teks besar yang dilihat sekilas, dan **Fredoka** (OFL 1.1) menjaga kehangatan dan keterbacaan teks yang dibaca lama. Peran font mengikuti potongan yang sudah ada, jadi tidak ada layar yang perlu ditata ulang:

- `regular_font()` adalah Fredoka bobot 500, yang menjadi `default_font` Theme;
- `bold_font()` adalah Fredoka bobot 600;
- `heavy_font()` adalah Chewy dengan Fredoka bold sebagai fallback.

Bobot 500 dipilih karena teks badan di HP lebih tebal dan hangat dibanding 400, tapi tetap ringan dibanding bold. Font bawaan Godot sebelumnya (Open Sans SemiBold) juga cukup tebal.

### D-129 — Font variable dengan bobot eksplisit

Fredoka dipakai sebagai satu file variable (159 KB) alih-alih empat file statis. Bobot diatur lewat `FontVariation.variation_opentype` dengan tag `wght` (2003265652), bukan `variation_embolden`. Instance bawaan file ini adalah Light (300), jadi setiap potongan wajib menyebut bobotnya. Theme tetap byte-identik antar build karena `GeneratorIo` menormalkan id `ext_resource` dan membuang uid. `ui_art_builder` naik ke versi 3. Label3D (tanda gigitan "!") diberi Chewy secara eksplisit. Label3D lain otomatis memakai `default_font` Theme.

### D-130 — Lisensi font ikut ke mana pun fontnya pergi

`assets/fonts/` berisi kedua font dan file lisensinya. `AssetPolicyScan.LICENSED_FONTS` (diturunkan dari `UiTokens.FONT_*_FILE`) hanya mengizinkan kedua font itu, dan hanya bila file lisensinya ada. Font lain tetap ditolak. Ketiga preset export memaketkan `assets/fonts/*.txt`. Layar Privacy menampilkan teks lisensi lengkap di halaman yang tombolnya kini bernama LICENSES (sebelumnya ENGINE LICENSES). Teks lisensi yang di-hard-wrap 75 kolom disambung per paragraf (`PrivacyOverlay._reflow`) supaya tidak patah-patah di layar HP. Test baru mengunci empat hal: semua karakter teks game ada di Fredoka dan di Chewy+fallback (build Web tidak punya font sistem), theme memakai file dan bobot yang benar, teks lisensi tampil di game, dan preset memaketkan lisensi.


## Revisi Ikon 6.4 — Ikon stiker penuh warna

Atas permintaan pemilik, ikon tombol yang masih berupa siluet satu warna dan terlihat seperti placeholder digambar ulang (GDD header revisi 6.4, Section 174.10, 184.11). D-119 (bagian ikon) diperluas.

### D-131 — Stiker, bukan siluet

Ikon kini ilustrasi kecil berwarna dengan outline cocoa tebal, karena gaya ini paling serasi dengan UI berlip dan dunia diorama dan tetap terbaca di atas tombol krem maupun terracotta. Setiap ikon disusun dari "part". `IconPainter._compile()` memberi tiap part secara otomatis:

- outline siluet;
- garis tipis di tempat part menumpuk part lain;
- bibir gelap, yaitu part dikurangi dirinya sendiri yang digeser ke atas;
- kilau, yaitu part yang diciutkan dikurangi dirinya yang digeser ke kanan bawah.

Desain per ikon hanya berisi bentuk dan warna. Alternatif ikon monokrom yang lebih rapi ditolak karena tetap terasa "UI sistem" dan tidak menjawab keluhan placeholder.

### D-132 — Geometri sekali, gambar berkali-kali

Operasi `Geometry2D` (offset, clip, merge) berjalan sekali per ikon, ±50 ms untuk 31 ikon, di grid yang diperbesar 32× agar kurva dan sambungan bulat tetap halus. Hasilnya di-cache bersama indeks triangulasinya. Saat menggambar hanya ada `canvas_item_add_triangle_array` dan polyline anti-alias tipis di tepi tiap poligon. Triangulasi tidak diulang saat menggambar karena poligon kecil sempat gagal ditriangulasi pada ukuran 24 px.

Clipper tidak bisa menggambar lubang. Celah yang lebih sempit dari dua kali outline akan tertutup dan terisi cocoa, seperti yang sempat terjadi di antara batang not musik. `_outers()` mencatat setiap lubang yang dibuang, dan test mewajibkan daftar itu kosong.

### D-133 — Ikon membawa warnanya sendiri

Warna ikon tombol di theme menjadi putih, yang bertindak sebagai pengali netral. Warna disabled adalah putih dengan alpha 0,45, yang membuat `IconPainter` menggambar versi pudar dan kurang jenuh, bukan versi tembus pandang yang memperlihatkan outline di balik isi. `UiIcon.tint` dan `MoveIcon.tint` kini juga pengali (default putih). Badge chip HUD menjadi pastel dari warna lamanya. Penanda langkah asli hasil Charm di Suwit pindah dari warna tangan ke cahaya teal di belakang tangan.

## Revisi Ponsel 6.5 — Ponsel cerita menjadi aplikasi chat

Atas permintaan pemilik ("biar kayak chat di WhatsApp"), ponsel cerita yang sebelumnya berupa teks polos di layar teal gelap diganti `ChatPhone` (GDD header revisi 6.5, Section 168.3).

### D-134 — Tata letak familiar, identitas sendiri

Yang diambil dari aplikasi chat populer adalah tata letaknya, karena pemain membacanya tanpa berpikir:

- header dengan avatar dan status;
- bubble berekor, kiri untuk lawan bicara dan kanan untuk diri sendiri;
- jam dan centang dua;
- wallpaper doodle, chip tanggal, kolom ketik, dan layar panggilan.

Nama, logo, ikon, dan warna merek aplikasi sungguhan sengaja tidak dipakai karena game ini komersial. Header memakai teal dari palet danau, bubble keluar memakai hijau muda yang hangat, dan wallpaper memakai krem diorama.

### D-135 — Memetakan langkah cerita ke chat tanpa mengubah naskah

Timeline tidak diubah. Langkah `phone` menjadi kartu akun di tengah chat (teks dipecah di ": " terakhir menjadi label dan nominal). Langkah `note` menjadi pesan dari akun bisnis CepatCash; ini cocok dengan kebiasaan pinjol di Indonesia yang menagih lewat chat. Langkah `chat` membuka thread orang itu, dan langkah `call` membuka layar panggilan. Isi dari kontak lain membuat ponsel berganti thread, misalnya pelunasan yang dimulai di chat CepatCash lalu pindah ke chat Rini. Jam selalu 3:17, sesuai kartu judul intro ("SUNDAY — 3:17 PM") dan tagline game tentang Minggu sore.

### D-136 — Daftar pesan tumbuh dari bawah

`Messages` adalah `VBoxContainer` yang berlabuh ke bawah area chat dan tumbuh ke atas. Area chat memotong isinya, jadi pesan lama bergulir ke balik header seperti di aplikasi chat sungguhan dan tidak pernah mendorong ponsel keluar layar. Lebar bubble dihitung dari lebar teks, maksimal 80% area chat. Pesan pendek menaruh jam di baris yang sama, dan pesan panjang menaruhnya di bawah. Lebar diukur langsung dengan font karena label di luar tree belum punya theme. Semua kontrol ponsel `MOUSE_FILTER_IGNORE`, sehingga ketukan tetap memajukan cerita.

## Revisi Bahasa 6.6 — English dan Bahasa Indonesia

Atas permintaan pemilik, game mendapat Bahasa Indonesia. Di mode English, nama lokal diganti nama Inggris (GDD header revisi 6.6, Section 133).

### D-137 — English sumber, Indonesia terjemahan lengkap

`ui_text.tres` tetap menjadi tabel sumber yang memuat setiap kunci. `ui_text_id.tres` memakai format `TextTable` yang sama. `TextDb` mencari di tabel bahasa aktif lalu jatuh ke English. Alias (nilai yang berupa kunci lain) hanya ada di English dan tetap diikuti ke baris terjemahan.

Teks yang sumber English-nya ada di resource data (nama ikan, label spesies, nama upgrade, nama sampah, dialog `fish_*.tres`) tidak dipindahkan. Resource tetap menyimpan English, dan getter `get_display_name()` / `TextDb.text_or()` mengambil terjemahannya dari kunci `fish.<id>.name`, `upgrade.<id>.name`, `trash.<id>.name`, dan `fishline.<sequence>.<n>`. Dengan begitu validator data dan test GDD tidak perlu berubah.

### D-138 — Nama per bahasa

Mode English memakai nama Inggris untuk tempat dan permainan. Suwit menjadi "Rock Paper Scissors", nama yang dikenal semua pemain berbahasa Inggris. Nama lengkap ini muat di roda (label menyusut), di tab Cara Bermain (tab bisa digeser), dan di banner (boleh dua baris).

Mode Indonesia mempertahankan nama lokal dari GDD: Warung Bu Yati, Danau Cempaka, Tinju Empang, Panco Maut, Joget Koplo, Suwit. Nama ikan, upgrade, dan sampah dilokalkan dengan rasa lokal yang sama lucunya, misalnya Lele Jagoan, Sersan Gabus, Jamu Pegal Linu, Kopi Tubruk, Cincin Batu Akik, dan Sandal Jepit Sebelah.

Suara karakter dijaga lewat sapaan:

- Lele preman memanggil "Bos".
- Nila anak gym memanggil "bro".
- Ikan Mas yang sombong ber-"Anda".
- Sersan Gabus berteriak.
- Nisa memanggil "Ayah", dan Darto memanggil Bu Yati "Ibu".

Pun "outstanding" pada pesan CepatCash diganti pun yang setara, "Tunggakan Anda masih menunggak".

### D-139 — Bahasa mengikuti perangkat, test tidak

Setting `language` bernilai `auto` secara default. `DisplaySettings.resolve_language()` membaca `OS.get_locale_language()`: `id` atau kode lama `in` menjadi Indonesia, bahasa lain menjadi English. Runner test mengunci `system_language_override = "en"` sehingga hasil test tidak bergantung pada mesin. `SceneRouter` menerapkan bahasa sebelum layar boot menulis teks pertamanya.

Save lama tanpa `language` diisi default lewat `SaveSchema.LATER_SETTINGS` tanpa catatan perbaikan. Sebelumnya, kunci yang hilang dianggap kerusakan: save ditulis ulang dan backup `pre_repair` dibuat untuk setiap pemain yang memperbarui game.

### D-140 — Ganti bahasa di tengah layar

UI dibangun saat `_ready`, sehingga layar yang sudah tampil tidak otomatis berganti bahasa. Saat bahasa diganti dari Main Menu, `SettingsOverlay.language_changed` membuat menu dimuat ulang. Di menu Pause tidak ada pendengar sinyal itu, jadi sebuah catatan kecil menjelaskan bahwa teks berganti di layar berikutnya. Scene gameplay tidak dimuat ulang, karena memuat ulang duel berarti kabur dari kekalahan.

## Revisi Lokasi 6.7 — Tempat memancing berjenjang

Atas permintaan pemilik, game mendapat 4 tempat memancing baru beserta ikan dan duelnya, tanpa milestone (GDD Section 198).

### D-141 — Tempat adalah data

Setiap tempat adalah `LocationData` di `data/locations/<id>.tres`. Semua perbedaan gameplay (pengali tunggu, strike, big one, berat, drift reel, pasang surut, ombak, segmen Wheel, set, ambience) adalah angka di resource itu, dan kode memancing hanya membacanya. Nilai default resource sama dengan aturan Danau Cempaka, sehingga `EncounterRoller`, `ReelSimulation`, dan `WheelController` menghasilkan RNG yang identik dengan versi sebelumnya di Danau Cempaka (Wheel yang semua segmennya sama besar tetap memakai jalur RNG lama).

### D-142 — Tempat terbuka lewat event, dipakai lewat perlengkapan

`StoryDirector.complete_event` membuka tempat yang `unlock_event`-nya cocok, baik event ditonton maupun dilewati. Membuka tempat tidak otomatis memindahkan Darto: perlengkapan harus dibeli dulu. Dua langkah ini membuat uang tetap punya tujuan selain utang, dan pemain yang masih nyaman di danau tidak dipaksa pindah. `SaveSchema.can_fish_at` adalah satu-satunya aturan "boleh memancing di sini", dipakai oleh `GameState`, normalisasi save, dan peta.

### D-143 — Wheel milik tempat asal ikan

Wheel memakai segmen tempat asal ikan (`ContentIds.location_of_fish`), bukan tempat Darto berdiri. Hasilnya sama dalam permainan normal, tetapi debug `--mm-duel` dan test bisa memanggil ikan mana pun dan tetap mendapat duel yang benar.

### D-144 — Duel baru berbagi dasar

`DuelControllerBase` memegang langkah 120 Hz, intro, hasil paksa (`--mm-result`), dan bentuk hasil. Keempat controller hanya berisi aturan. `SpotDuelScene` memegang pause, tutorial, play time, bot, dan `DuelExit`; `SpotDuelHud` memegang banner, Pause, titik skor, dan tombol aksi yang memakai action input yang sudah ada (`dance_lane_1..4`, `arm_mash`, `box_dodge_left/right`). Tidak ada action input baru, jadi remap kontrol lama langsung berlaku.

Kekuatan ikan di duel baru diambil dari satu stat baru, `FishData.duel_skill` (0–100). Ikan lama juga punya nilai ini, karena Wheel tempat lain bisa saja dipanggil debug untuk ikan lama.

### D-145 — Satu tarikan per lintasan, satu ritme untuk memanjat

Tarik Tambang menghitung satu tarikan per lintasan marker melewati zona hijau, dan Panjat Pinang menghukum ketukan yang lebih cepat dari 0,17 detik dengan meteran licin. Keduanya mencegah "mash" (GDD Section 52 sudah membedakan mash yang disengaja dari yang tidak). Di HP, tombol sisi yang benar diberi warna CTA, tetapi tombol sisi lainnya tetap bisa ditekan karena salah sisi adalah bagian dari permainan.

### D-146 — Set tempat menukar set danau

Adegan memancing dan hasil duel tetap dibangun di atas set danau. Di tempat lain, `SpotSet.swap_in` mengganti node set itu dengan set tempat yang membawa marker yang sama (`DartoSpot`, `FloatSpot`, `BucketSpot`, `CameraFocus`, `ResultFocus`, `WheelFocus`). Marker berada di posisi layar yang sama, jadi seluruh logika kamera, pelampung, tarikan ikan, dan ember tidak perlu tahu tempatnya. Di Dermaga Mawar, Darto berdiri di dek setinggi 0,3 m; titik mendarat ikan mengikuti tinggi `DartoSpot`.

### D-147 — Peta hanya muncul jika ada pilihan

Chip peta disembunyikan sampai tempat kedua terbuka, dan saat pertama muncul diberi petunjuk sekali (`travel_seen`). Pindah tempat menyimpan game lalu memuat ulang adegan memancing, sehingga tidak ada state memancing setengah jalan yang terbawa ke tempat lain. Pindah hanya bisa saat Darto diam.

### D-148 — Save version 6 di file lama

Nama file tetap `save_v5.json`. Mengganti nama file berarti save pemain lama tidak ditemukan, padahal migrasi `migrate_5_to_6` sudah cukup. `legends_defeated` dimulai dari jumlah kemenangan atas Don Arowana, supaya Records tidak tiba-tiba menulis nol untuk pemain yang sudah mengalahkannya.

Migrasi hanya melengkapi blok yang memang ada (Bucket, Fish Book, statistik, tutorial, setting). Blok yang hilang atau rusak dibiarkan apa adanya, sehingga validasi tetap menolak save yang rusak. Tanpa aturan ini, file `{"version": 5}` diterima sebagai game baru dan progres pemain hilang diam-diam.

Migrasi biasa hanya membuat backup `pre_migration`. Backup `pre_repair` kini hanya dibuat bila normalisasi benar-benar memperbaiki sesuatu, jadi update game tidak meninggalkan dua salinan yang sama di folder save.

## Revisi Nama 6.8 — Catch and Brawl

Atas permintaan pemilik, game berganti nama menjadi **Catch and Brawl** (GDD header revisi 6.8).

### D-149 — Satu nama untuk semua bahasa

Nama game sama di mode English dan Bahasa Indonesia. Aturan Section 133.2 tentang nama lokal di mode Indonesia berlaku untuk tempat dan permainan di dalam game, bukan untuk merek game.

### D-150 — Logo satu baris yang menyesuaikan lebar

Logo lama punya dua tingkat: judul besar dan subjudul di pita miring. "Catch and Brawl" dipakai utuh di baris besar. Versi "CATCH" dengan pita "AND BRAWL" sudah dicoba, tetapi kata BRAWL menjadi terlalu kecil. Pita kini disembunyikan bila subjudulnya kosong.

Judul tidak dibungkus otomatis. Label yang membungkus di dalam kontainer logo yang menyusut ke isinya pecah per suku kata ("CAT / CH"). Sebagai gantinya, ukuran font diturunkan sampai judul muat lebar layar, termasuk pada teks 150%. Layar boot memakai kontainer selebar layar, jadi di sana judul boleh membungkus.

### D-151 — Application ID baru sebelum rilis pertama

`com.mancingmania.gelutedition` diganti `com.catchandbrawl.game` di Android dan iOS. Game belum pernah dirilis ke toko, jadi penggantian ini aman. Setelah rilis pertama, ID tidak boleh diganti lagi.

### D-152 — Save ikut pindah ke folder bernama baru

Di desktop, `user://` dinamai sesuai nama proyek, jadi folder save ikut berpindah ke `app_userdata/Catch and Brawl`. Saat `SaveManager` siap, ia mencari folder bernama lama di sebelahnya. Bila folder baru belum punya save dan folder lama punya, semua file `save_v5*` disalin sekali. Folder lama tidak diubah atau dihapus, dan folder yang sudah punya save tidak pernah ditimpa. Di Android dan iOS, `user://` ada di sandbox aplikasi, jadi impor ini tidak berpengaruh di sana.

Nama file GDD dan folder repository tetap memakai nama lama, karena banyak rujukan dan workspace mengarah ke sana.

## Revisi Android 6.11 — Stabil di HP Android

Sumber: `ANDROID_STABILITY_AND_RELEASE_GUIDE.md` di root repository. Aturan proyek (GDD, test runner) tetap menang bila berbeda; satu-satunya perbedaan adalah runner test, yang tetap memakai `--script res://tests/run_all.gd` karena suite dimuat setelah autoload siap.

### D-153 — MSAA mati di HP, dicek sebelum preset

`DisplaySettings.msaa_for()` memeriksa perangkat dulu (`mobile`, `android`, `ios`, `web_android`, `web_ios`) dan baru membaca preset di desktop. `project.godot` juga memuat `msaa_3d.mobile=0`. D-096 di atas sudah tidak berlaku untuk HP: MEDIUM dan HIGH memakai MSAA hanya di desktop. Preset LOW tetap 75% resolusi 3D; tanpa MSAA, buffer internal itu aman.

### D-154 — Ekor 16 sampel di `SfxRenderer`

Ekor ditulis di satu tempat: `SfxRenderer.to_stream()`, `write_tail_pad()`, dan `make_stream()`. `MusicRenderer` memakai dua fungsi terakhir agar encode bertahapnya tidak berubah. `loop_end` dan `get_samples()` tetap tanpa ekor, jadi jam lagu Joget dan test lama tidak bergeser.

### D-155 — Back lewat jalur cancel yang sudah ada

`InputManager.handle_back_request()` mengirim `ui_cancel` ke viewport dengan `push_input()` dan memeriksa apakah ada yang menanganinya. Overlay, dialog, dan baris dialog sudah menangani Esc, jadi Back otomatis menutup yang paling atas tanpa daftar layer baru. Bila tidak ada yang menangani, scene dengan `handle_back()` (Main Menu, Credits) menjawab; selain itu Back menekan action Pause yang sudah dibaca setiap scene gameplay. Sinyal `go_back_requested` disambung deferred agar tidak berjalan di tengah pemrosesan event jendela.

### D-156 — `.bak` disalin, bukan dipindah

Save lama disalin ke `.bak` (bukan di-rename), sehingga selalu ada save utama di disk meskipun game mati di antara dua langkah. `.bak` hanya ditulis bila save lama masih terbaca, jadi file rusak tidak pernah menimpa cadangan yang bagus. New Game tidak membuat `.bak` dari game lama, dan `delete_save()` ikut menghapusnya karena isinya data pemain.

### D-157 — `armeabi-v7a` dan preset APK uji

GDD 186 mengizinkan arsitektur tambahan bila ada alasan QA dan masuk budget. Alasannya: HP Android Go dan HP lama yang menjalankan Android 32-bit. Ukuran AAB belum diukur karena belum ada export Android di mesin ini; dicek saat export pertama. Preset `Android APK (test)` tanpa Gradle dan ditandatangani debug key editor, sehingga tidak ada data keystore di repository.

### D-158 — Lifecycle tidak diubah

Panduan meminta save saat aplikasi ke background. Danau dan Market sudah menyimpan saat `NOTIFICATION_APPLICATION_PAUSED`, dan semua scene gameplay membuka Pause saat fokus hilang. Duel sengaja tidak menyimpan di tengah pertarungan (GDD 176.5: Continue memulihkan progres tetap, bukan duel yang sedang berjalan), dan scene lain sudah menyimpan saat event-nya terjadi. Jadi tidak ada handler pusat baru.
