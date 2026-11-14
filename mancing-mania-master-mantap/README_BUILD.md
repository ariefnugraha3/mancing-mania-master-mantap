# Build dan Rilis

Panduan export Web (itch.io) dan Android (Google Play) sesuai GDD Section 135, 186, dan 196. Semua perintah dijalankan dari folder project ini. `godot` berarti executable Godot 4.7.2 (edisi standar) di mesin Anda.

## Prasyarat umum

- Godot 4.7.2 stable dan **export templates 4.7.2** (Editor → Manage Export Templates). Versi template harus sama persis dengan versi editor.
- Jalankan test dulu: `godot --headless --path . --import` lalu `godot --headless --path . --script res://tests/run_all.gd` harus exit code 0.
- Folder `build/` berisi hasil export dan diabaikan git. File `build/.gdignore` mencegah Godot mengimpor isinya.

## Web / itch.io

```text
godot --headless --path . --export-release "Web" build/web/index.html
```

Preset `Web` (di `export_presets.cfg`):

- Renderer Compatibility (WebGL 2).
- `variant/thread_support=false`: build single-threaded, tidak butuh header COOP/COEP, jadi berjalan di itch.io tanpa pengaturan tambahan (Section 135).
- Folder `tests/`, `tools/`, `docs/`, `release/`, `generated/references/`, dan `generated/manifests/` tidak ikut paket. `data/story/*.json` ikut lewat include filter.

Membuat ZIP untuk itch.io (`index.html` harus di root ZIP):

```text
cd build/web
zip -9 ../itch/mancing-mania-gelut-edition-web-<versi>.zip *
```

Atau dengan Python (Windows tanpa `zip`):

```text
python -c "import zipfile,os; z=zipfile.ZipFile('build/itch/mancing-mania-gelut-edition-web-<versi>.zip','w',zipfile.ZIP_DEFLATED); [z.write(os.path.join('build/web',f),f) for f in os.listdir('build/web')]; z.close()"
```

Pengaturan halaman itch.io (Section 135, 186.8): Kind of project **HTML**, centang *This file will be played in the browser*, viewport **1280×720**, centang *Fullscreen button*, boleh *Automatically start on page load* dimatikan. Judul, ringkasan, deskripsi, dan tag ada di `docs/store_compliance_report.md`.

Menguji lokal:

```text
cd build/web
python -m http.server 8000
```

lalu buka `http://localhost:8000`. Membuka `index.html` langsung dari disk tidak bisa (browser memblokir WebAssembly dari `file://`).

## Android / Google Play

Preset `Android` sudah ada: App Bundle (`build/android/MancingManiaGelut.aab`), application ID `com.mancingmania.gelutedition`, min SDK 24, target SDK 36, hanya `arm64-v8a`, portrait, tanpa permission.

Yang harus disiapkan pemilik di mesin build (sekali saja):

1. **Android SDK** (platform 36, build-tools terbaru, platform-tools, command-line tools) dan **JDK 17 atau lebih baru**.
2. Di Godot: **Editor → Editor Settings → Export → Android**: isi *Android SDK Path* (mis. `C:\Users\<nama>\AppData\Local\Android\Sdk`) dan *Java SDK Path* ke JDK 17+.
3. **Project → Install Android Build Template** (membuat folder `android/`, diabaikan git). Gradle build wajib untuk AAB.
4. **Keystore rilis** milik pemilik, disimpan di luar repository (Section 191.7). Buat sekali:

   ```text
   keytool -genkeypair -v -keystore mancing-mania-release.keystore -alias mancingmania -keyalg RSA -keysize 2048 -validity 10000
   ```

   Jangan pernah commit keystore atau password. Berikan ke Godot lewat environment variable saat export:

   ```text
   GODOT_ANDROID_KEYSTORE_RELEASE_PATH=<path ke keystore>
   GODOT_ANDROID_KEYSTORE_RELEASE_USER=mancingmania
   GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=<password>
   ```

5. Ikon adaptive: salin `build/store/google_play/adaptive_foreground_432.png` dan `adaptive_background_432.png` (hasil `store_art_generator.gd`) ke lokasi di dalam project (mis. `generated/ui/`), lalu isi `launcher_icons/adaptive_foreground_432x432` dan `adaptive_background_432x432` di preset.

Lalu:

```text
godot --headless --path . --export-release "Android" build/android/MancingManiaGelut.aab
```

Sebelum submit, periksa ulang target API yang diwajibkan Google Play pada tanggal submission (Section 186.3, 186.11) dan naikkan `gradle_build/target_sdk` bila perlu.

## Versi

Versi pemain mengikuti Semantic Versioning di `application/config/version` (`project.godot`). Android memakai `version/name` yang sama dan `version/code = MAJOR*10000 + MINOR*100 + PATCH` (Section 186.2): `1.0.0` → `10000`. Release candidate `1.0.0-rc.1` memakai `9901` agar rilis final tetap bisa memakai kode yang lebih tinggi. Test `release.test_version_is_semantic` memeriksa keduanya sama.

## Store art

Gambar toko dibuat dari scene game asli (Section 186.5):

```text
godot --path . --resolution 590x1049 --script res://tools/generators/store_art_generator.gd -- --mode=portrait
godot --path . --resolution 1024x500 --script res://tools/generators/store_art_generator.gd -- --mode=feature
```

Hasilnya di `build/store/google_play/`. Screenshot ponsel 1080×1920 dirender pada jendela 9:16 terbesar yang muat di layar lalu diperbesar; untuk listing final, ambil ulang di perangkat atau emulator 1080×1920.

## Validasi rilis dan manifest

```text
godot --headless --path . --script res://tools/release/release_tool.gd -- --validate
godot --headless --path . --script res://tools/release/release_tool.gd -- --manifest=release/build_manifest.json
```

`--validate` gagal selama data publisher (`release/publisher_metadata.json`, salinan dari `publisher_metadata.example.json`), email dukungan di kebijakan privasi, atau paket export belum ada (Section 186.10, 187.9). File `publisher_metadata.json` diabaikan git.

`--manifest` mencatat SHA-256 setiap artefak beserta versi, engine, commit, dan checksum manifest generator (Section 196).

## Build ulang dari nol (Section 196.9)

```text
git clone <repo> && cd mancing-mania-master-mantap
godot --headless --path . --import
godot --headless --path . --script res://tools/generators/generate_all_assets.gd
godot --path . --script res://tools/generators/reference_sheet_generator.gd
godot --headless --path . --import
godot --headless --path . --script res://tests/run_all.gd
godot --headless --path . --export-release "Web" build/web/index.html
```

Generator deterministik: menjalankannya dua kali menghasilkan `generator_manifest.json` yang identik byte demi byte.
