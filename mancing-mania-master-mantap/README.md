# Mancing Mania: Gelut Edition

Game memancing cozy berlatar Danau Cempaka. Setiap ikan yang berhasil ditarik menantang Darto dalam duel absurd: tinju, panco, joget koplo, atau suwit.

Spesifikasi lengkap ada di `../mancing-mania-gelut-edition-gdd-v6-final-authoritative-specification.md`. Dokumen itu adalah sumber kebenaran; README ini hanya menjelaskan cara bekerja dengan project.

## Status

| Milestone | Isi | Status |
|---|---|---|
| 1 | Foundation: data, save, input, audio dasar, debug, Boot, Main Menu | selesai (`0.1.0`) |
| 2 | Fishing vertical slice: danau, Darto, cast → strike → reel | selesai (`0.2.0`) |
| 3 | Market, ekonomi, upgrade, Fish Book, Records | selesai (`0.3.0`) |
| 4 | Tinju lengkap | selesai (`0.4.0`) |
| 5 | Panco lengkap | berikutnya |
| 6–10 | Dua duel lain, cerita, art/audio final, QA dan rilis | belum |

Laporan tiap milestone ada di `docs/milestone_reports/`.

## Kebutuhan

- **Godot Engine 4.7 stable atau lebih baru** (dikembangkan dengan 4.7.2), edisi standar (GDScript).
- Tidak ada addon, tidak ada dependency lain, tidak perlu internet.

## Menjalankan game

Buka folder ini di Godot lalu tekan F5, atau dari terminal:

```text
godot --path .
```

`godot` di bawah ini berarti executable Godot di mesin Anda, misalnya `Godot_v4.7.2-stable_win64_console.exe`.

## Menjalankan test

```text
godot --headless --path . --import
godot --headless --path . --script res://tests/run_all.gd
```

Perintah pertama cukup sekali setelah checkout baru atau setelah menambah script ber-`class_name`. Exit code `0` berarti semua test lulus. Detail ada di [README_TESTING.md](README_TESTING.md).

## Membuat ulang aset

Semua aset visual dan audio dibuat dari kode di repository ini. Tidak ada aset dari internet (GDD Section 184).

```text
godot --headless --path . --script res://tools/generators/generate_all_assets.gd
godot --headless --path . --import
```

Hasilnya masuk ke `generated/` dan dicatat di `generated/manifests/generator_manifest.json` beserta checksum. Varian `godot --headless --editor --path . --script ...` dari GDD juga sudah diuji dan menghasilkan file yang identik.

Lembar referensi visual (GDD Section 185) dirender terpisah karena butuh kartu grafis. Jalankan **tanpa** `--headless`, setelah generator di atas:

```text
godot --path . --script res://tools/generators/reference_sheet_generator.gd
```

Lembar referensi masuk ke `generated/references/`. Folder itu diabaikan Godot (`.gdignore`) karena isinya bahan QA, bukan konten game.

Perintah yang sama juga merender potret Fish Book ke `generated/textures/fish_book/`. Potret itu konten game: jalankan `godot --headless --path . --import` sesudahnya agar Godot mengimpornya.

Jangan mengedit file di `generated/` dengan tangan. Ubah generator di `tools/generators/`, jalankan ulang, lalu commit keduanya.

## Struktur folder

```text
autoload/     9 service global: GameState, SaveManager, SceneRouter, AudioManager,
              InputManager, PlatformService, RNGService, StoryDirector, DebugService
data/         data authoritative (.tres): ikan, sampah, upgrade, balance, audio, teks
scenes/       scene per layar (boot, menu, fishing, market, boxing, lalu duel lain, ...)
scripts/      gameplay/ (data, validasi, skema save, fishing/, market/, boxing/, duel/), actors/,
              ui/ (termasuk ui/market/ untuk halaman ledger), audio/, utilities/
shaders/      shader buatan project (air danau, goyangan dedaunan, siluet Fish Book)
tools/        generators/ (pembuat aset) dan validation/ (pemeriksa kebijakan aset)
generated/    output generator; boleh di-commit, bisa dibuat ulang kapan saja
tests/        test headless
docs/         keputusan implementasi dan laporan milestone
```

## Aturan kerja singkat

- Angka balancing hanya ada di `data/` dan dikunci oleh test. Mengubahnya berarti merevisi GDD.
- Semua teks yang dilihat pemain berbahasa Inggris dan disimpan di `data/dialogue/ui_text.tres`.
- Gameplay membaca action dari InputMap lewat `InputManager`, bukan keycode.
- Satu milestone per sesi kerja; milestone berikutnya baru dimulai setelah exit gate lulus (GDD Section 181).
- Keputusan untuk hal yang tidak diatur GDD dicatat di `docs/implementation_decisions.md`.

## Tool debug (hanya debug build)

- `F10` membuka Debug Overlay. Di Android: ketuk label versi 5 kali dalam 3 detik.
- Overlay bisa memaksa tangkapan berikutnya (lele, arwana, sampah), memendekkan waktu tunggu gigitan, dan menampilkan nilai internal reel.
- Dari command line: bot yang memainkan duel, paksa arah serangan tinju, paksa hasil duel, dan langsung masuk ring melawan ikan tertentu.
- Mengubah cash/hutang lewat overlay menandai state sebagai `DEV DIRTY STATE`; autosave diblokir sampai Anda menekan `SAVE DEBUG STATE`. Halaman Market ikut diperbarui saat nilainya diubah dari overlay.
- Screenshot UI dari terminal dijelaskan di [README_TESTING.md](README_TESTING.md).

## Belum tersedia

Export preset Web/Android, panduan signing Android, dan pengemasan itch.io dikerjakan di Milestone 10 dan akan didokumentasikan di `README_BUILD.md`.
