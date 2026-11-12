# Changelog

Format mengikuti Semantic Versioning (GDD Section 186.2). Tag milestone mengikuti GDD Section 191.3.

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
