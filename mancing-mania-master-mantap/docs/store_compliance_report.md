# Laporan Kepatuhan Toko — 1.0.0-rc.1

GDD Section 186.11, 187, 188. Diperiksa 14 November 2026. Bagian yang hanya bisa dijawab di Play Console atau dasbor itch.io ditandai **tugas pemilik**.

## Pemeriksaan persyaratan (Section 186.11)

| Item | Hasil | Sumber |
|---|---|---|
| Tanggal pemeriksaan | 14 November 2026 | — |
| Target API Google Play | Android 16 / API 36 untuk app baru dan setiap update, berlaku sejak 31 Agustus 2026. Preset memakai `target_sdk=36`. Belum ada tanggal resmi untuk API 37. Periksa ulang di Play Console saat submission. | developer.android.com/google/play/requirements/target-sdk; support.google.com/googleplay/android-developer/answer/11926878 |
| Aset pratinjau Google Play | Ikon 512×512 PNG, feature graphic 1024×500 tanpa alpha, minimal 2 screenshot; project menyediakan 5 screenshot portrait 1080×1920 (Section 186.5) | GDD 186.5 |
| Data Safety | wajib diisi untuk setiap app; jawaban yang dimaksud di bawah | GDD 187.4 |
| Rating konten | kuesioner IARC di Play Console, jawaban berdasarkan isi nyata (di bawah) | GDD 188 |
| Batas HTML5 itch.io | total ekstrak ≤ 500 MB, file tunggal ≤ 200 MB, jumlah file ≤ 1.000 (sumber komunitas tidak seragam soal jumlah file; paket kita hanya 9 file) | GDD 186.9; forum itch.io |
| Versi Godot | 4.7.2 stable | `godot --version` |
| Versi template export | 4.7.2.stable (Web dan Android tersedia) | `%APPDATA%/Godot/export_templates/4.7.2.stable` |

## Paket Web / itch.io

| | Nilai | Batas |
|---|---|---|
| File di ZIP | 9 | ≤ 1.000 |
| Ukuran ZIP | 11,2 MB | — |
| Ukuran setelah ekstrak | 43,6 MB | ≤ 500 MB (anggaran internal Section 190.12 jauh lebih ketat) |
| File terbesar | `index.wasm` 39,5 MB | ≤ 200 MB |
| `index.html` di root ZIP | ya | wajib |
| Nama file | ASCII, huruf kecil, relatif | UTF-8, case-correct |
| Thread | tidak (single-threaded) | menghindari kebutuhan COOP/COEP |

Smoke test Chromium (Chrome headless, WebGL 2 lewat SwiftShader): halaman memuat, Main Menu tampil, NEW GAME membuka prolog, tidak ada exception di console. Firefox dan Safari belum diuji (**tugas pemilik**, Section 195.11).

## Identitas dan listing (Section 186)

| | |
|---|---|
| Judul | Mancing Mania: Gelut Edition |
| Application ID | `com.mancingmania.gelutedition` |
| Label launcher | Mancing Mania: Gelut Edition (Section 186.4). Launcher ponsel bisa memotong label panjang; cek di perangkat. |
| Versi | 1.0.0-rc.1, versionCode 9901 |
| Orientasi Android | portrait |
| Arsitektur | arm64-v8a |
| Permission | tidak ada |

Teks listing Google Play dan itch.io dipakai apa adanya dari Section 186.7 dan 186.8 (pendek, panjang, tag). Tidak ada klaim yang tidak ada di game: semua fitur yang disebut sudah ada di build ini, termasuk Free Fishing setelah cerita dan tanpa iklan/IAP.

Data publisher (`publisher_display_name`, `publisher_support_email`, `privacy_policy_https_url`) **belum diisi** — tidak boleh dikarang (Section 186.10). Isi `release/publisher_metadata.json` dari contoh `release/publisher_metadata.example.json`. `tools/release/release_tool.gd --validate` sengaja gagal sampai ini dan email di kebijakan privasi diisi.

## Privasi dan Data Safety (Section 187)

Diverifikasi terhadap kode:

- Tidak ada kelas jaringan di kode runtime (`HTTPRequest`, `HTTPClient`, socket, WebSocket, WebRTC, `JavaScriptBridge`, `OS.shell_open`) dan tidak ada URL — dikunci oleh `release.test_runtime_code_has_no_network_access`.
- Tidak ada SDK iklan, analitik, crash reporting, akun, atau login. Tidak ada plugin atau GDExtension.
- Preset Android tanpa permission apa pun, termasuk INTERNET — dikunci oleh `release.test_export_presets_follow_the_release_contract`.
- Save, setting, statistik, Fish Book, dan cerita disimpan lokal (`user://`); di Web lewat storage browser. Settings di Web menampilkan peringatan bahwa menghapus data situs menghapus save.
- Layar **Settings → PRIVACY AND LICENSES**: ringkasan lima baris Section 187.7, kebijakan lengkap Section 187.6, dan lisensi engine, semuanya offline.

Jawaban Data Safety yang dimaksud (dicek ulang saat submission, **tugas pemilik**): app tidak mengumpulkan data; app tidak membagikan data; tidak ada akun sehingga tidak perlu mekanisme hapus akun; tidak ada data iklan, keuangan, lokasi, atau informasi pribadi.

Tersisa sebelum rilis publik: email dukungan di `PRIVACY_POLICY.md`, `release/privacy_policy.html`, dan teks dalam game `privacy.policy.contact.body`; URL HTTPS publik untuk kebijakan privasi.

## Rating konten (Section 188)

Jawaban kuesioner berdasarkan isi build ini:

| Kategori | Jawaban |
|---|---|
| Kekerasan | Ya, ringan dan kartun: ikan bertinju dengan Darto, panco, pose KO berlebihan. Tanpa darah, luka realistis, senjata, atau kekerasan antar manusia. |
| Judi | Referensi naratif ke kecanduan judi online Darto di masa lalu dan akibatnya. Tidak ada taruhan, kasino, slot, mata uang taruhan, loot box, atau uang sungguhan. Wheel of Fate hanya memilih satu dari empat minigame tanpa biaya dan tanpa hadiah ekonomi. |
| Bahasa | Ejekan ringan, tanpa kata kasar. |
| Seksual | Tidak ada. Nisa anak-anak dan tidak pernah disensualisasi. |
| Obat/alkohol/rokok | Tidak ada. Herbal Tonic dan Black Coffee adalah item biasa. |
| Horor | Tidak ada. |
| Interaksi pengguna | Tidak ada chat, UGC, profil, atau multiplayer. |
| Pembelian | Tidak ada IAP, iklan, atau mata uang berbayar. |
| Lokasi / data sensitif | Tidak ada. |

Target audiens 13+ (Section 188.4). Rating akhir ditentukan IARC dan bisa berbeda per wilayah.

## Lisensi (Section 187.8)

Tidak ada aset, font, musik, atau kode pihak ketiga selain Godot Engine. `LICENSES.md` memuat lisensi MIT Godot dan daftar 102 komponen pihak ketiga yang dibawa template export; teks lengkapnya juga tampil di layar ENGINE LICENSES di dalam game.
