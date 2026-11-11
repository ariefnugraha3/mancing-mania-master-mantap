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
