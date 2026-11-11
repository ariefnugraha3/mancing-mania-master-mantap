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
- Exit code `0` berarti semua lulus, `1` berarti ada yang gagal atau tidak ada test yang berjalan, `2` berarti watchdog 180 detik menghentikan run yang macet.
- Di CI atau script, bungkus perintah dengan batas waktu. Script yang error sebelum memanggil `quit()` membuat proses Godot tidak pernah berhenti.

Semua test bekerja di `user://test_tmp/` dan tidak pernah menyentuh save pemain.

## Suite

| Suite | File | Cakupan |
|---|---|---|
| `data` | `tests/suites/test_data.gd` | BOOT-001..004, tabel ikan/sampah/upgrade/balance sesuai GDD, InputMap, tabel teks |
| `state` | `tests/suites/test_game_state.gd` | API GameState, SAVE-012 (4.000 transaksi acak tanpa melanggar invariant) |
| `save` | `tests/suites/test_save.gd` | SAVE-001..009, migrasi, import/export, penulisan terputus, DEV DIRTY |
| `rng` | `tests/suites/test_rng.gd` | determinisme seed, distribusi 100.000 encounter |
| `audio` | `tests/suites/test_audio.gd` | sintesis SFX tanpa NaN/clipping, bus, volume mengikuti setting |
| `services` | `tests/suites/test_services.gd` | PlatformService, InputManager, StoryDirector, DebugService, SceneRouter |
| `assets` | `tests/suites/test_assets.gd` | kebijakan tanpa aset internet, manifest generator, tema hasil generate |
| `boot` | `tests/suites/test_boot_flow.gd` | scene asli: Boot → Main Menu, New Game, Continue, konfirmasi dua langkah, pemulihan save rusak |

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

- `--mm-press=<path node>` menekan tombol di scene aktif. Boleh diulang; dijalankan berurutan.
- `--mm-overlay` membuka Debug Overlay.
- `--mm-shot=<path png>` menyimpan screenshot lalu keluar.

Perintah ini memakai save asli di `user://`. Menekan `NewGameButton` akan membuat save sungguhan.

## Peringatan yang boleh diabaikan

`WARNING: 3 ObjectDB instances were leaked at exit` muncul di akhir suite `boot`. Suite itu membuang scene Main Menu saat dialog masih menunggu jawaban, sehingga coroutine yang tertunda masih hidup ketika proses berakhir. Ini hanya terjadi di test.
