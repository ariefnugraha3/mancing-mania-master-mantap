# Teks Bahasa Indonesia — Catch and Brawl

Semua teks berbahasa Indonesia yang bisa dilihat pemain di dalam game, disusun menurut tempat teks itu muncul. Teks diambil langsung dari `data/dialogue/ui_text_id.tres`, tabel terjemahan yang dipakai game saat bahasa diatur ke INDONESIA (atau OTOMATIS di perangkat berbahasa Indonesia).

Cara membaca:

- **Transkrip cerita dan dialog** ditulis berurutan seperti yang dilihat pemain. Nama tebal adalah pembicara. Keterangan miring dalam kurung siku menunjukkan bentuk tampilannya (chat HP, pesan, kartu).
- **Tabel antarmuka** mencantumkan kunci teks (`kunci`), supaya teks mudah dicari dan diubah di `ui_text_id.tres`.
- `{nama}` adalah isian yang diganti game saat tampil, misalnya `{amount}` menjadi jumlah rupiah, `{fish}` menjadi nama ikan, dan `{catfish_losses}` menjadi berapa kali Darto kalah duel melawan Lele Jagoan.
- `<br>` menandai pindah baris di dalam satu teks.

Jumlah teks di tabel Indonesia: **1418**.

## Daftar isi

1. [Adegan cerita](#1-adegan-cerita)
2. [Obrolan di warung](#2-obrolan-di-warung)
3. [Pesan CepatCash di HP](#3-pesan-cepatcash-di-hp)
4. [Kedatangan di tempat baru](#4-kedatangan-di-tempat-baru)
5. [Ikan: profil dan dialog](#5-ikan-profil-dan-dialog)
6. [Reaksi Darto setelah duel](#6-reaksi-darto-setelah-duel)
7. [Kredit penutup](#7-kredit-penutup)
8. [Warung Bu Yati](#8-warung-bu-yati)
9. [Antarmuka lainnya](#9-antarmuka-lainnya)

## 1. Adegan cerita

Adegan cerita diputar di layar tersendiri dengan latar 3D, kotak dialog di bawah, dan HP Darto (aplikasi chat) yang muncul di tengah layar. Pemain mengetuk untuk lanjut, atau menahan layar untuk melewati seluruh adegan. Urutan di bawah adalah urutan yang dialami pemain.

### 1.1 Prolog

- **Kapan:** Saat memilih MAIN BARU di Menu Utama, sebelum pertama kali memancing.
- **Tampil di:** Adegan cerita: rumah Darto, lalu jalan ke danau.
- **ID adegan:** `story_prologue_zero`

- *[HP: kartu akun]* SALDO BANK: Rp 18.430
- *[HP: kartu akun]* TOTAL UTANG: Rp 1.800.000
- *[Pesan CepatCash]* **CEPATCASH — PENGINGAT PEMBAYARAN** — Tunggakan Anda masih menunggak.<br>Kekecewaan kami juga ikut menunggak.
- **DARTO:** ...Wajar sih.
- **RINI:** Aku berangkat.
- **DARTO:** Iya.
- **RINI:** Kamu buka itu lagi?
- **DARTO:** Nggak.
- **DARTO:** Udah kuhapus semua.
- **RINI:** Bagus.
- **RINI:** Kalau cuma menghapus itu sih gampang.
- **DARTO:** Aku tahu.
- **RINI:** Ada nasi di rice cooker.
- **DARTO:** Oke.
- **RINI:** Rice cooker-nya jangan dijual lagi.
- **DARTO:** Itu cuma sekali.
- **RINI:** Makanya aku bilang lagi.
- **DARTO:** Baiklah.
- **DARTO:** Nggak ada jalan pintas.
- *[Kartu judul]* **CATCH AND BRAWL** — MINGGU — 15.17

### 1.2 Ikan pertama

- **Kapan:** Setelah ikan pertama berhasil ditarik ke darat di Danau Cempaka, sebelum Roda Nasib.
- **Tampil di:** Kotak dialog di bagian bawah layar memancing.
- **ID adegan:** `story_first_fish`

- **LELE JAGOAN:** Turunkan aku.
- **DARTO:** ...Hah?
- **LELE JAGOAN:** Kau tuli? Aku bilang turunkan aku!
- **DARTO:** Ikan kan nggak bisa ngomong.
- **LELE JAGOAN:** Dan pengangguran biasanya nggak debat sama makan malamnya.
- **DARTO:** Gak sopan banget.
- **LELE JAGOAN:** Ayo maju.

### 1.3 Kunjungan pertama ke warung

- **Kapan:** Saat pertama kali masuk Warung Bu Yati.
- **Tampil di:** Kotak dialog di bagian bawah layar Warung.
- **ID adegan:** `story_first_market`

- **BU YATI:** Ikannya seger?
- **DARTO:** Banget.
- **BU YATI:** Masih gerak?
- **DARTO:** Secara emosional, iya.
- **BU YATI:** Taruh di timbangan.

*Setelah penjualan pertama di warung (kotak dialog):*

- **DARTO:** Lebih banyak dari yang saya kira.
- **BU YATI:** Ya jangan banyak berharap. Gak bagus.

*Setelah cicilan utang pertama (kotak dialog):*

- **DARTO:** Satu beres.
- **BU YATI:** Tinggal satu juta tujuh ratus sembilan puluh ribu lagi.
- **DARTO:** ...Nggak usah disebut lengkap gitu, Bu.
- **BU YATI:** Kamu kelihatan terlalu santai.

### 1.4 Utang terbayar Rp 100.000

- **Kapan:** Saat keluar warung, setelah total utang yang dibayar mencapai Rp 100.000.
- **Tampil di:** Adegan cerita: Warung Bu Yati.
- **ID adegan:** `story_debt_100k`

- *[HP: kartu akun]* DIBAYAR: Rp 100.000
- **DARTO:** Seratus ribu.
- **BU YATI:** Itu sebuah angka.
- **DARTO:** Angka yang lumayan.
- **BU YATI:** Lebih kecil dari satu koma delapan juta.
- **DARTO:** Kayaknya gak perlu disebutin deh.
- **BU YATI:** Saya nggak lagi bantu.
- *[Chat dari RINI]* Gimana danaunya?
- *[Chat, dikirim Darto]* Cukup untung buat balik lagi.
- *[Chat dari RINI]* Balik ke danau atau balik ke rumah?
- *[Chat, dikirim Darto]* Dua-duanya.
- *[Chat dari RINI]* Jawaban bagus.

### 1.5 Utang terbayar Rp 300.000

- **Kapan:** Saat keluar warung, setelah total utang yang dibayar mencapai Rp 300.000.
- **Tampil di:** Adegan cerita: Warung Bu Yati.
- **ID adegan:** `story_debt_300k`

- *[Chat dari RINI]* Aku lihat pembayarannya.
- *[Chat, dikirim Darto]* Pembayaran bagus atau pembayaran jelek?
- *[Chat dari RINI]* Pembayaran itu umumnya bagus, Darto.
- *[Chat, dikirim Darto]* Cuma ngecek kategorinya.
- *[Chat dari RINI]* Lanjutkan.

### 1.6 Tempat baru: Kali Kenanga

- **Kapan:** Saat keluar warung pada kunjungan berikutnya setelah adegan Rp 300.000.
- **Tampil di:** Adegan cerita: Warung Bu Yati.
- **ID adegan:** `story_unlock_kenanga`

- **BU YATI:** Bapak mobil boks putih telepon lagi.
- **DARTO:** Mau lele lagi?
- **BU YATI:** Baung. Ikan kali. Danaumu nggak ada.
- **DARTO:** Ada kali lewat jembatan tua.
- **BU YATI:** Kali Kenanga. Arusnya kuat. Harus pakai kail arus. Beli saja.
- **DARTO:** Dari Ibu, pastinya.
- **BU YATI:** Tentu saja dari saya. Dan ikannya kamu jual ke saya.
- **DARTO:** Di jembatan ada pembeli juga.
- **BU YATI:** Yang timbangannya miring itu? Silakan. Rugi setengah.
- **DARTO:** ...Yaudah iya, saya jual ke Ibu.
- **BU YATI:** Bagus. Ikan dari mana pun, ujungnya ke sini.
- *[Kartu unlock]* **TEMPAT BARU: KALI KENANGA** — Beli Kail Arus di warung, lalu ketuk peta di tepi air. — tombol **LANJUT**

### 1.7 Utang terbayar Rp 600.000 (Buku Ikan terbuka)

- **Kapan:** Saat keluar warung, setelah total utang yang dibayar mencapai Rp 600.000.
- **Tampil di:** Adegan cerita: Warung Bu Yati.
- **ID adegan:** `story_debt_600k`

- *[Panggilan suara masuk: Nisa]*
- **NISA:** Yah?
- **DARTO:** Hai. Semua aman?
- **NISA:** Kata Ibu, Ayah sekarang mancing.
- **DARTO:** Itu salah satu cara menyebutnya.
- **NISA:** Cara lainnya?
- **DARTO:** Kerja bareng ikan yang agresifnya nggak wajar.
- **NISA:** Kata Ibu, ikannya ngajak berantem.
- **DARTO:** Ibu kebanyakan cerita.
- **NISA:** Ayah menang?
- **DARTO:** Sebagian.
- **NISA:** Yang paling aneh yang mana?
- **DARTO:** Ada ikan nila yang menghakimi rutinitas olahraga Ayah.
- **NISA:** Dicatat dong.
- **DARTO:** Hinaannya?
- **NISA:** Semuanya.
- **NISA:** Terus kirim fotonya kalau Ayah dapat yang emas.
- **DARTO:** Kamu tahu soal yang itu?
- **NISA:** Internet itu ada, Yah.
- **DARTO:** Benar juga. Sekolah asrama punya teknologi canggih.
- **NISA:** Canggih banget. Kami punya kursi.
- **DARTO:** Pamer.
- *[Kartu unlock]* **BUKU IKAN TERBUKA** — Catat untuk Nisa. Dan, rupanya, untuk ilmu pengetahuan. — tombol **LANJUT**

### 1.8 Tempat baru: Waduk Melati

- **Kapan:** Saat keluar warung pada kunjungan berikutnya setelah adegan Rp 600.000.
- **Tampil di:** Adegan cerita: Warung Bu Yati.
- **ID adegan:** `story_unlock_melati`

- *[Chat dari NISA]* Yah, dekat asramaku ada waduk.
- *[Chat, dikirim Darto]* Oh ya?
- *[Chat dari NISA]* Kata anak-anak ada ikan red devil di sana. Galak.
- *[Chat, dikirim Darto]* Ayah sudah ketemu ikan galak. Ayah profesional sekarang.
- *[Chat dari NISA]* Kalau ke sana, lambaikan tangan ke sekolahku.
- **BU YATI:** Waduk Melati? Kamu butuh senar panjang. Airnya dalam.
- **DARTO:** Di sana ada koperasi nelayan.
- **BU YATI:** Khusus anggota. Fotokopi tiga lembar dan nunggu dua minggu.
- **DARTO:** Kalau Ibu?
- **BU YATI:** Saya cuma tanya satu hal.
- **DARTO:** Ikannya seger?
- **BU YATI:** Nah. Kamu sudah hafal prosedurnya.
- *[Kartu unlock]* **TEMPAT BARU: WADUK MELATI** — Beli Senar Panjang di warung. Airnya dalam dan ikannya berat. — tombol **LANJUT**

### 1.9 Utang terbayar Rp 1.000.000

- **Kapan:** Saat keluar warung, setelah total utang yang dibayar mencapai Rp 1.000.000.
- **Tampil di:** Adegan cerita: Warung Bu Yati.
- **ID adegan:** `story_debt_1000k`

- *[Panggilan suara masuk: Rini]*
- **RINI:** Kamu sudah lewat setengah jalan.
- **DARTO:** Aku sadar.
- **RINI:** Biasanya kamu menghindar kalau lihat angka.
- **DARTO:** Aku lagi coba hobi baru.
- **RINI:** Angka?
- **DARTO:** Menyelesaikan sesuatu.
- **RINI:** Kalau ini sudah beres...
- **RINI:** Atap di dapur masih bocor.
- **DARTO:** Romantis.
- **RINI:** Aku serius.
- **DARTO:** Aku tahu.
- **RINI:** Maksudku setelahnya, Darto.
- **DARTO:** Iya.
- **DARTO:** Setelahnya kedengarannya enak.

### 1.10 Tempat baru: Muara Anggrek

- **Kapan:** Saat keluar warung pada kunjungan berikutnya setelah adegan Rp 1.000.000.
- **Tampil di:** Adegan cerita: Warung Bu Yati.
- **ID adegan:** `story_unlock_anggrek`

- *[Chat dari RINI]* Kata Bu Yati kamu mau ke muara.
- *[Chat, dikirim Darto]* Cepat juga beritanya.
- *[Chat dari RINI]* Bapak dulu suka cari kepiting di sana.
- *[Chat, dikirim Darto]* Aku nggak tahu itu.
- *[Chat dari RINI]* Selalu dibawa ke warung yang sama.
- *[Chat, dikirim Darto]* Warung Bu Yati?
- *[Chat dari RINI]* Waktu itu masih punya ibunya. Pakai sepatu bot. Becek.
- **BU YATI:** Bapak mertuamu jual kepiting ke kami dua puluh tahun.
- **DARTO:** Dua puluh tahun di warung yang sama?
- **BU YATI:** Timbangan kami nggak pernah curang. Dia nggak pernah jual ke tempat lain.
- **DARTO:** Pantas semuanya ujungnya ke sini.
- **BU YATI:** Sepatu botnya di rak.
- *[Kartu unlock]* **TEMPAT BARU: MUARA ANGGREK** — Beli Sepatu Bot di warung. Perhatikan air: pasang bawa ikan. — tombol **LANJUT**

### 1.11 Utang terbayar Rp 1.400.000

- **Kapan:** Saat keluar warung, setelah total utang yang dibayar mencapai Rp 1.400.000.
- **Tampil di:** Adegan cerita: Warung Bu Yati.
- **ID adegan:** `story_debt_1400k`

- **BU YATI:** Bapak yang punya rumah makan itu nanyain ikanmu lagi.
- **DARTO:** Yang mobil boks putih itu?
- **BU YATI:** Iya.
- **DARTO:** Itu bagus?
- **BU YATI:** Dia bayar.
- **DARTO:** Referensi karakter yang luar biasa.
- **BU YATI:** Dia mau pasokan rutin kalau kamu terus bawa ikan yang layak.
- **DARTO:** Rutin?
- **BU YATI:** Itu yang barusan saya bilang.
- **DARTO:** Kayak... kerja?
- **BU YATI:** Nggak usah dramatis. Bawa ikan.
- **DARTO:** Siap.
- **BU YATI:** Ikan seger.
- **DARTO:** Secara emosional?
- **BU YATI:** Bukan.

### 1.12 Tempat baru: Dermaga Mawar

- **Kapan:** Saat keluar warung pada kunjungan berikutnya setelah adegan Rp 1.400.000.
- **Tampil di:** Adegan cerita: Warung Bu Yati.
- **ID adegan:** `story_unlock_mawar`

- **BU YATI:** Pasokan rutin. Bapak mobil boks setuju.
- **DARTO:** Jadi saya punya kerjaan.
- **BU YATI:** Kamu punya kontrak. Bulan depan ada hajatan. Dia mau ikan laut.
- **DARTO:** Dermaga Mawar? Jauh itu.
- **BU YATI:** Motormu pernah lebih jauh. Mungkin.
- **DARTO:** Di dermaga ada pelelangan ikan.
- **BU YATI:** Untuk pemilik kapal. Dan juru lelangnya pingsan kalau ikannya ngajak debat.
- **DARTO:** Ikan saya selalu ngajak debat.
- **BU YATI:** Saya tahu. Makanya kamu jual ke saya.
- **DARTO:** Cuma Ibu yang nggak keberatan.
- **BU YATI:** Saya keberatan. Cuma nggak pingsan. Beli joran laut dulu saja.
- *[Kartu unlock]* **TEMPAT BARU: DERMAGA MAWAR** — Beli Joran Laut di warung. Tahan senar saat ombak datang. — tombol **LANJUT**

### 1.13 Utang terbayar Rp 1.650.000

- **Kapan:** Saat keluar warung, setelah total utang yang dibayar mencapai Rp 1.650.000.
- **Tampil di:** Adegan cerita: tepi danau.
- **ID adegan:** `story_debt_1650k`

- *[HP: kartu akun]* SISA UTANG: Rp 150.000
- **DARTO:** Hampir.
- **DARTO:** Danaunya masih kelihatan sama.
- **DARTO:** Bagus.

### 1.14 Pertama kali mengalahkan Don Arwana

- **Kapan:** Saat keluar warung, setelah pertama kali menang duel melawan Don Arwana (ikan bos).
- **Tampil di:** Adegan cerita: tepi danau.
- **ID adegan:** `story_arowana_first_win`

- **DON ARWANA:** Nikmati kemenanganmu.
- **DARTO:** Memang mau kunikmati.
- **DON ARWANA:** Danau ini ingat.
- **DARTO:** Nggak apa-apa.
- **DARTO:** Danaunya bayar tiga ratus ribu nggak?
- **DON ARWANA:** Kamu menyebalkan.
- **DARTO:** Berarti iya.

### 1.15 Utang lunas

- **Kapan:** Saat keluar warung, setelah sisa utang menjadi Rp 0.
- **Tampil di:** Adegan cerita: Warung Bu Yati.
- **ID adegan:** `story_debt_paid`

- *[HP: kartu akun]* SISA UTANG: Rp 0
- *[Pesan CepatCash]* **CEPATCASH** — TAGIHAN ANDA SUDAH LUNAS SEPENUHNYA.
- *[Pesan CepatCash]* **CEPATCASH** — Terima kasih.
- **DARTO:** ...Udah, gitu doang?
- **DARTO:** Nggak ada bos terakhir?
- **DARTO:** Bagus.
- *[Chat dari RINI]* Aku lihat.
- *[Chat, dikirim Darto]* Udah beres.
- *[Chat dari RINI]* Pulang kalau urusanmu di sana sudah selesai.
- *[Chat, dikirim Darto]* Sebentar lagi.
- *[Chat dari RINI]* Oke.

### 1.16 Epilog: piknik keluarga

- **Kapan:** Langsung setelah adegan utang lunas.
- **Tampil di:** Adegan cerita: tepi danau.
- **ID adegan:** `story_final_family`

- **NISA:** Jadi yang mana yang ninju Ayah?
- **DARTO:** Si lele.
- **RINI:** Ayah kalah {catfish_losses} kali.
- **DARTO:** Kenapa kita bikin statistik?
- **NISA:** Demi ilmu pengetahuan.
- **DARTO:** Ilmu pengetahuan sekarang suka menghakimi.
- **NISA:** Ayah nulis kalau si nila bilang postur Ayah lemah.
- **DARTO:** Catatan yang akurat itu penting.
- **RINI:** Postur kamu memang lemah.
- **DARTO:** Keluarga ini memilih kekerasan.
- **NISA:** Ayah masih mau ke sini?
- **DARTO:** Kayaknya.
- **RINI:** Ayah memang suka dibentak-bentak ikan.
- **DARTO:** Ayah suka bagian yang tenangnya.
- **NISA:** Dan duitnya.
- **DARTO:** Dan sebagian duitnya.
- **RINI:** Jangan cari ribut.
- **DARTO:** Aku nggak pernah mulai duluan.
- **DON ARWANA:** BOHONG.

### 1.17 Mode bebas terbuka

- **Kapan:** Setelah kredit penutup selesai (sesudah epilog).
- **Tampil di:** Adegan cerita: layar polos tanpa latar.
- **ID adegan:** `story_postgame_unlock`

- *[Kartu unlock]* **MODE MANCING BEBAS TERBUKA** — Utangnya sudah hilang.<br>Ikan-ikannya sayangnya masih di sini. — tombol **LANJUT**
- *[Kartu unlock]* **BUKU UTANG sekarang jadi TABUNGAN KELUARGA.** — Terus mancing, lengkapi Buku Ikan, upgrade peralatan, kejar rekor, atau cukup duduk di tepi danau sebentar. — tombol **KEMBALI KE DANAU**

## 2. Obrolan di warung

Obrolan pendek Bu Yati dan Darto di kotak dialog Warung. Muncul pada kunjungan ke-3, ke-6, ke-9, dan seterusnya, bila tidak ada adegan cerita yang menunggu. Ketiga obrolan dipakai bergiliran.

### Obrolan 1

- **BU YATI:** Ikannya seger?
- **DARTO:** Pertanyaan itu sekarang kedengarannya mengancam.

### Obrolan 2

- **DARTO:** Ibu pernah libur nggak?
- **BU YATI:** Ini hari libur saya.
- **DARTO:** Ibu kan lagi kerja.
- **BU YATI:** Diam-diam.

### Obrolan 3

- **BU YATI:** Kamu dapat sandal lagi.
- **DARTO:** Danau memberi rezeki.
- **BU YATI:** Danaunya perlu dibersihkan.

## 3. Pesan CepatCash di HP

Notifikasi aplikasi pinjaman CepatCash. Tampil sebagai banner di layar memancing, paling sering sekali setiap 18–35 menit bermain, dan berhenti setelah utang lunas. Kelima pesan dipakai bergiliran. Pada pesan ke-1, ke-3, ke-5, dan seterusnya, balasan Darto ditambahkan di bawah isi pesan ("Darto: …").

| # | Judul | Isi |
|---|---|---|
| 1 | PENGINGAT PEMBAYARAN | Tunggakan Anda masih menunggak. |
| 2 | PEMBERITAHUAN AKUN | Kami menghargai pembayaran terakhir Anda.<br>Kami akan lebih menghargai sisanya. |
| 3 | PEMBARUAN SALDO | Kemajuan terdeteksi.<br>Antusiasme masih dibatasi prosedur. |
| 4 | PENGINGAT RAMAH | Ini adalah versi ramah dari pengingatnya. |
| 5 | STATUS PEMBAYARAN | Masih belum nol.<br>Sudah kami cek dua kali. |

Balasan Darto (bergiliran):

1. Informatif sekali.
2. Makasih, komputer kecil penuh stres.
3. Pelan-pelan lunas.
4. Aku tahu.

## 4. Kedatangan di tempat baru

Gumaman Darto di kotak dialog layar memancing, saat pertama kali tiba di tempat baru lewat peta perjalanan.

### Kali Kenanga

- **DARTO:** Kali Kenanga. Arusnya deras hari ini.
- **DARTO:** Pembeli di jembatan itu. Timbangannya miring, senyumnya lebar.
- **DARTO:** Nggak, makasih. Semua ke Bu Yati.

### Waduk Melati

- **DARTO:** Waduk Melati. Sekolah Nisa ada di sebelah sana.
- **DARTO:** Kantor koperasi ada antrean. Di hari Minggu.
- **DARTO:** Mancing aja. Formulirnya bisa nunggu selamanya.

### Muara Anggrek

- **DARTO:** Muara Anggrek. Baunya garam dan lumpur.
- **DARTO:** Bapak mertua dulu menyusuri lumpur ini bawa keranjang kepiting.
- **DARTO:** Pasang, surut. Harus kuperhatikan.

### Dermaga Mawar

- **DARTO:** Dermaga Mawar. Itu laut. Semuanya.
- **DARTO:** Pelelangan di sebelah sana. Juru lelangnya masih kelihatan pucat.
- **DARTO:** Ikan dari mana pun, tetap ke Bu Yati.

## 5. Ikan: profil dan dialog

Setiap ikan punya profil (nama, jenis, julukan, deskripsi), percakapan pertemuan pertama, dan empat kumpulan kalimat. Semua dialog ikan tampil di kotak dialog di bagian bawah layar. Percakapan pertemuan pertama diputar saat ikan itu ditarik ke darat untuk pertama kalinya. Sesudahnya, game memilih satu kalimat dari kumpulan yang sesuai.

### Lele Jagoan

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Lele Jagoan
- **Jenis (di Buku Ikan):** LELE
- **Julukan (banner saat ikan ditarik ke darat):** PEMBUAT ONAR SETEMPAT
- **Deskripsi (Buku Ikan):** Lele berkumis tebal dengan tingkah preman kampung dan profesionalisme seorang konsultan pajak. Lebih suka danau daripada ember. Bisa dimengerti.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **LELE JAGOAN:** Turunkan aku.
- **DARTO:** ...Hah?
- **LELE JAGOAN:** Kau tuli? Aku bilang turunkan aku!
- **DARTO:** Ikan kan nggak bisa ngomong.
- **LELE JAGOAN:** Dan pengangguran biasanya nggak debat sama makan malamnya.
- **LELE JAGOAN:** Ayo maju.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Bukan urusan pribadi, Bos. Bisnis ya bisnis.
- Kita bisa selesaikan baik-baik. Yaitu pakai kekerasan.
- Kamu lagi? Ya sudah. Angkat tanganmu.
- Sore ini aku sudah ada acara. Sekarang aku harus meninjumu.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Adil. Ember itu pantas mendapatkan aku.
- Pukulan bagus. Jangan dibawa perasaan.
- Bilang ke siapapun yang beli aku, aku kalah secara profesional.
- Aku kagum sama usahamu. Sama embernya nggak.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Bilang ke embermu: aku nolak.
- Usahanya bagus. Hasilnya parah.
- Bukan urusan pribadi. Aku lebih suka danau.
- Balik lagi kalau langkah kakimu sudah berhenti minta maaf.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Kebanyakan tegang, Bos!
- Senarmu menyerah duluan sebelum aku.
- Anggap saja itu peringatan.

### Nila Anak Gym

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Nila Anak Gym
- **Jenis (di Buku Ikan):** NILA
- **Julukan (banner saat ikan ditarik ke darat):** PENGGEMAR PROTEIN
- **Deskripsi (Buku Ikan):** Menganggap setiap tarikan, pukulan, dan keputusan hidup yang buruk sebagai bagian dari program latihan. Tidak pernah dimintai saran kebugaran. Tetap saja memberikannya.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **NILA ANAK GYM:** KAMU BENERAN BISA NARIK?
- **DARTO:** Aku masih narik sampai lima detik yang lalu.
- **NILA ANAK GYM:** Form joran kamu itu jelek banget.
- **DARTO:** Itu joran pancing.
- **NILA ANAK GYM:** ALASAN!! ITU NOL PROTEIN.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Set pemanasan beres. Sekarang kita duel.
- Aku hitung tarikanmu. Volumenya mengecewakan.
- Mantap. Latihan beban datang sendiri.
- Minum dulu. Habis itu siap-siap kalah.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Tekniknya solid. Gaya hidupnya meragukan.
- Balasan tadi formnya bagus. Respek.
- Oke. Ternyata hari ini leg day.
- Embernya harus ada proteinnya.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- HARI PEMULIHAN!
- Teknikmu ambruk duluan sebelum ototku.
- Latihan lebih keras. Tarik lebih rapi.
- Ini kucatat sebagai kardio.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Kekuatan genggaman! Latih lagi!
- Senarnya gagal menyelesaikan set!
- Beban bertahap, bro! Bukan beban hidup!

### Gurami Mencurigakan

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Gurami Mencurigakan
- **Jenis (di Buku Ikan):** GURAMI
- **Julukan (banner saat ikan ditarik ke darat):** KONONNYA HADIR
- **Deskripsi (Buku Ikan):** Mengaku tidak tinggal di Danau Cempaka, padahal berkali-kali tertangkap di Danau Cempaka. Sering minta catatannya dihapus. Catatannya tidak dihapus.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **GURAMI MENCURIGAKAN:** Kamu tidak melihat apa-apa.
- **DARTO:** Aku jelas-jelas narik kamu dari danau.
- **GURAMI MENCURIGAKAN:** Danau ini tidak kenal aku.
- **DARTO:** Danau itu tempat aku nemu kamu.
- **GURAMI MENCURIGAKAN:** Konon katanya.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Pertemuan ini tidak ada di jadwal.
- Kita bisa selesaikan ini tanpa berkas-berkas.
- Aku punya teman di perairan yang lebih dalam.
- Apa pun yang terjadi nanti, kamu tidak pernah dengar namaku.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Sayang sekali. Jangan dicatat ya.
- Aku dan ember ini tidak pernah bertemu.
- Tolong dicatat bahwa transaksi ini masih disengketakan.
- Baik. Tapi aku tidak pernah ada di sini.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Tidak ada saksi. Sempurna.
- Urusan kita selesai.
- Sebaiknya kamu lupakan wajahku.
- Danau ini punya pengacara yang sangat bagus.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Barang bukti dimusnahkan.
- Senar lepas. Jejak lepas. Prinsipnya sama.
- Kamu tidak bisa membuktikan itu aku.

### Ikan Mas Emas

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Ikan Mas Emas
- **Jenis (di Buku Ikan):** IKAN MAS
- **Julukan (banner saat ikan ditarik ke darat):** MEWAH (MENURUT DIRINYA)
- **Deskripsi (Buku Ikan):** Keemasan, kelihatan mahal, dan sangat tersinggung oleh wadah biasa. Menaksir harganya sendiri beberapa kali dalam satu obrolan. Warung memakai hitungan yang berbeda.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **IKAN MAS EMAS:** Hati-hati dengan sisik saya. Ini mahal.
- **DARTO:** Semahal apa?
- **IKAN MAS EMAS:** Lebih mahal dari motor Anda.
- **DARTO:** Standarnya nggak tinggi-tinggi amat.
- **IKAN MAS EMAS:** Saya benci Anda.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Anda boleh mengagumi saya sebentar sebelum kalah.
- Jangan sampai sisik saya kusut.
- Tadinya sore saya ini sore premium.
- Lancang sekali senar pancing itu.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Ini memalukan secara ekonomi.
- Taruh sesuatu yang empuk di ember itu.
- Saya minta transportasi kelas premium.
- Anda menang. Tapi pakaian Anda tetap memprihatinkan.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Sudah saya duga. Kemewahan kembali ke air.
- Kekayaan bersih dan rasio menang Anda sama-sama konsisten.
- Lambaikan tangan kalau saya lewat di depan motor Anda.
- Ada hal-hal yang memang tidak terjangkau.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Senar murahan. Sudah ketebak.
- Itu bukan manajemen tegangan kelas premium.
- Pertimbangkan peralatan yang bermartabat.

### Sersan Gabus

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Sersan Gabus
- **Jenis (di Buku Ikan):** GABUS
- **Julukan (banner saat ikan ditarik ke darat):** INSTRUKTUR PERAIRAN TEMPUR
- **Deskripsi (Buku Ikan):** Yakin bahwa memancing adalah soal disiplin. Yakin bahwa semua hal adalah soal disiplin. Pengaturan volume suaranya masih dalam penyelidikan.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **SERSAN GABUS:** PEMANCING!
- **DARTO:** Kenapa teriak-teriak?
- **SERSAN GABUS:** TARIKANMU KURANG MEYAKINKAN!
- **DARTO:** Aku kan sudah nangkep kamu.
- **SERSAN GABUS:** UNTUK SEMENTARA!

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- SIKAP SEMPURNA! PANDANGAN KE DEPAN! SIAP!
- ITU YANG KAMU SEBUT MENDARATKAN? ULANG!
- DISIPLIN DIMULAI SAAT KENYAMANAN BERAKHIR!
- KAMU MEMASUKI PERAIRAN TEMPUR!

**Setelah kamu menang duel (layar hasil). Satu dari:**

- PENAMPILAN BISA DITERIMA! NYARIS!
- KEKALAHAN DITERIMA! LANJUTKAN!
- BALASAN BAGUS! SANDALNYA PARAH!
- EMBER INI SEKARANG POS JAGAKU!

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- KEMBALI LATIHAN!
- MISI GAGAL, PEMANCING!
- DANAU TETAP MENGUASAI POSISI INI!
- DISIPLIN: MILIKKU. MAKAN MALAM: BUKAN MILIKMU.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- SENAR GAGAL BERTAHAN!
- MANAJEMEN TEGANGAN: TIDAK MEMUASKAN!
- SUSUN BARISAN DAN LEMPAR LAGI!

### Don Arwana

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Don Arwana
- **Jenis (di Buku Ikan):** ARWANA ASIA
- **Julukan (banner saat ikan ditarik ke darat):** DANAU INI INGAT
- **Deskripsi (Buku Ikan):** Legenda tua yang langka dari Danau Cempaka. Tenang, mahal, dan anehnya tahu banyak soal kehidupan pribadi Darto. Mengalahkannya memang hebat. Tapi itu tidak wajib untuk membereskan hidupmu.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **DON ARWANA:** Darto.
- **DARTO:** ...Dari mana kamu tahu namaku?
- **DON ARWANA:** Danau ini bercerita.
- **DARTO:** Itu sangat menyeramkan.
- **DON ARWANA:** Memang seperti itu.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Kita bertemu lagi. Danau ini punya selera humor.
- Kesabaran membawamu ke sini. Mari kita lihat apa yang bisa dilakukan keahlian.
- Kamu jadi gigih. Aku menghormati kegigihan.
- Jangan kira kelangkaan itu keberuntungan, Darto.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Kemenangan yang bersih. Jangan jadi sombong.
- Kamu sudah berkembang. Diam-diam. Itu lebih baik.
- Ambil uangmu. Danau ini akan selamat dari penghinaan ini.
- Konsisten itu sifat yang menyebalkan. Pertahankan.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Bukan hari ini, Darto.
- Kamu hampir. Tapi hampir itu masih di dalam air.
- Danau menyimpan apa yang tidak bisa kamu selesaikan.
- Kembalilah saat kesabaranmu lebih berat dari penyesalanmu.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Kamu menarik terlalu keras. Hidup belum mengajarimu apa-apa?
- Sabar, Darto. Senar pun tahu batasnya.
- Danau ini tidak pernah kalah oleh ketidaksabaran.

**Setelah pertama kali mengalahkan Don Arwana** (layar hasil, menggantikan kalimat biasa):

- **DON ARWANA:** Nikmati kemenanganmu.
- **DARTO:** Memang mau kunikmati.
- **DON ARWANA:** Danau ini ingat.
- **DARTO:** Nggak apa-apa.
- **DARTO:** Danaunya bayar tiga ratus ribu nggak?
- **DON ARWANA:** Kamu menyebalkan.
- **DARTO:** Berarti iya.

### Baung Satpam

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Baung Satpam
- **Jenis (di Buku Ikan):** BAUNG
- **Julukan (banner saat ikan ditarik ke darat):** SATPAM JEMBATAN
- **Deskripsi (Buku Ikan):** Menjaga jembatan tua dengan peluit yang sebenarnya tidak bisa ia tiup. Menanyakan surat izin ke semua orang. Belum pernah mengeluarkan satu pun.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **BAUNG SATPAM:** Berhenti. Siapa di situ?
- **DARTO:** Orang yang lagi megang kamu.
- **BAUNG SATPAM:** Nama dan keperluan.
- **DARTO:** Darto. Mancing. Jelas, kan.
- **BAUNG SATPAM:** Keperluan ditolak. Siap-siap.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Permisi. Izin mancingnya mana?
- Bagian kali ini di bawah pengawasan saya.
- Mohon mundur dari air. Sesuai prosedur.
- Bapak ikut saya. Ke arena.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Dicatat. Saya akan bikin laporan tentang diri saya sendiri.
- Silakan lewat. Ke dalam ember.
- Waktu jaga saya selesai. Tolong ada yang gantikan saya di jembatan.
- Tekniknya bagus. Izinnya tetap nggak ada.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Area aman terkendali.
- Silakan kembali di jam kunjungan.
- Ini zona bebas ember.
- Terima kasih atas kerja samanya.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Tegangan tanpa izin terdeteksi!
- Senar disita.
- Evakuasi ke bagian dalam!

### Tawes Tukang Gosip

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Tawes Tukang Gosip
- **Jenis (di Buku Ikan):** TAWES
- **Julukan (banner saat ikan ditarik ke darat):** PUSAT INFORMASI KAMPUNG
- **Deskripsi (Buku Ikan):** Tahu siapa utang ke siapa, siapa yang jual rice cooker, dan siapa yang mancing bukannya kerja. Sebagian besar malah benar.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **TAWES TUKANG GOSIP:** Ooh, beneran soal rice cooker itu?
- **DARTO:** Kok ikan bisa tahu soal itu?
- **TAWES TUKANG GOSIP:** Semua orang tahu. Aku yang mastiin.
- **DARTO:** Mantap. Ikan punya jaringan sosial.
- **TAWES TUKANG GOSIP:** Lawan aku, nanti kurahasiakan. Mungkin.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Lho! Kamu kan yang jual rice cooker itu!
- Tunggu sampai satu kali tahu soal ini.
- Psst. Aku tahu banyak hal. Lawan aku, nanti kulupakan.
- Semua orang ngomongin kamu. Terutama aku.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Ya sudah. Tapi aku bakal bilang ke semua orang kamu curang.
- Ini nggak pernah terjadi. Nanti kuceritakan seolah terjadi.
- Ooh, ember. Gosip di dalam sini mantap.
- Lawan yang bagus. Potongan rambut yang parah.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Tunggu sampai Bu Yati dengar.
- Kalah sama tawes. Berita ini bakal menyebar.
- Ada sumber yang bilang kamu bakal kalah lagi.
- Dadaaah. Tenang, nanti kusebarkan gosipnya.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Kabar terkini: senar putus!
- Salam buat istrimu, ya.
- Ini masuk grup chat.

### Belut Licin

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Belut Licin
- **Jenis (di Buku Ikan):** BELUT
- **Julukan (banner saat ikan ditarik ke darat):** AHLI MELOLOSKAN DIRI
- **Deskripsi (Buku Ikan):** Terlalu licin untuk dipegang dan terlalu sopan untuk kurang ajar. Minta maaf setiap kali lolos, yang artinya setiap saat.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **BELUT LICIN:** Oh! Maaf. Saya ada di tangan Bapak, ya?
- **DARTO:** Iya. Nyaris.
- **BELUT LICIN:** Maaf sekali. Sebentar lagi saya pergi.
- **DARTO:** Kamu nggak boleh ke mana-mana.
- **BELUT LICIN:** Kalau begitu, maaf soal duel ini.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Permisi, numpang lewat.
- Maaf, maaf, sebentar lagi saya pergi.
- Saya minta maaf duluan soal yang terjadi habis ini.
- Mohon maaf. Urusannya bakal licin.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Oh. Saya kurang licin. Maaf.
- Saya mohon maaf sudah tertangkap.
- Maaf ya, embernya jadi berlendir.
- Permainan yang bagus. Mohon maaf sekali.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Maaf! Permisi! Dadah!
- Saya benar-benar minta maaf soal ini.
- Maafkan kaburnya saya.
- Jangan dendam. Licin aja.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Maaf! Kepeleset!
- Permisi, saya pamit.
- Maaf sekali. Licin sekali.

### Hampala Pembalap Liar

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Hampala Pembalap Liar
- **Jenis (di Buku Ikan):** HAMPALA
- **Julukan (banner saat ikan ditarik ke darat):** PEMBALAP TANPA SIM
- **Deskripsi (Buku Ikan):** Ngebut melawan apa saja yang bergerak, terutama motor di jembatan. Punya pendapat soal motor Darto. Tidak ada yang baik.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **HAMPALA PEMBALAP LIAR:** Motor yang bagus. Barang museum, ya?
- **DARTO:** Umurnya dua puluh tahun dan masih jalan.
- **HAMPALA PEMBALAP LIAR:** Nyaris. Aku dengar dari jembatan.
- **DARTO:** Kamu barusan menghina motorku?
- **HAMPALA PEMBALAP LIAR:** Balapan sama aku, nanti tahu.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- BREM BREM! Siapa yang lelet? Kamu yang lelet!
- Motormu suaranya kayak orang batuk.
- Lampu hijau! Gas gas gas!
- Aku nggak kenal rem.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Masuk pit. Wajib, katanya.
- Finis tipis. Aku masuk foto. Di dalam ember.
- Respek. Refleksmu pakai nitro.
- Oke. Balapan berikutnya aku bawa sirip yang lebih bagus.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Makan gelembungku!
- Rekor putaran. Lagi.
- Kelamaan, Om!
- Sampai jumpa di garis finis. Aku sudah di sana.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Oper gigi! Dadah!
- Senarmu nggak kuat ngejar!
- Gas pol!

### Belida Sang Pendekar

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Belida Sang Pendekar
- **Jenis (di Buku Ikan):** BELIDA
- **Julukan (banner saat ikan ditarik ke darat):** GURU PERGURUAN KALI KENANGA
- **Deskripsi (Buku Ikan):** Legenda tua berbentuk pisau yang mengajar silat ke ikan-ikan muda di kali. Belum pernah kalah duel, dan tidak menghitung yang kalah.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **BELIDA SANG PENDEKAR:** Kamu menarikku dari latihan pagi.
- **DARTO:** Ini jam empat sore.
- **BELIDA SANG PENDEKAR:** Latihan tidak melihat jam.
- **DARTO:** Kamu... guru silat?
- **BELIDA SANG PENDEKAR:** Pasang kuda-kuda. Kelas dimulai.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Berdiri yang benar. Kakimu sedang membohongimu.
- Seorang murid datang. Mari kita lihat apa yang ia tahu.
- Kali mengajariku sabar. Aku akan mengajarimu rendah hati.
- Beri hormat dulu, Darto. Baru jatuh.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Bagus. Muridnya ingat pelajaran.
- Aku kalah. Catat. Nanti kubantah.
- Gerakanmu jelek. Tapi berhasil. Itu cukup.
- Pergilah. Ajari ember itu sopan santun.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Ulangi. Lebih pelan. Dengan hormat.
- Kamu menyerang bayanganku. Aku tidak di sana.
- Kali ini murid yang lebih baik daripada kamu.
- Kembalilah kalau kuda-kudamu berhenti minta maaf.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Tenaga bukan teknik.
- Tarikan kuat, pikiran lemah.
- Senarnya putus. Fokusmu putus duluan.

### Red Devil Tukang Palak

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Red Devil Tukang Palak
- **Jenis (di Buku Ikan):** RED DEVIL
- **Julukan (banner saat ikan ditarik ke darat):** PEMUNGUT PUNGLI SWADAYA
- **Deskripsi (Buku Ikan):** Datang tanpa diundang, menghabiskan makan siang semua penghuni, lalu menarik uang keamanan untuk airnya. Belum pernah ada yang bayar. Ia terus menagih.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **RED DEVIL TUKANG PALAK:** Eits, eits. Sepuluh ribu buat tempatnya.
- **DARTO:** Ini waduk umum.
- **RED DEVIL TUKANG PALAK:** Umum, iya. Aman? Itu bayar lagi.
- **DARTO:** Aku sudah punya penagih utang.
- **RED DEVIL TUKANG PALAK:** Berarti kamu sudah paham caranya.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Tempat ini ada biayanya. Uang keamanan.
- Muka baru. Tarif baru.
- Bayar atau berantem.
- Nggak ada yang mancing di sini tanpa bayar aku.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Ya sudah. Kunjungan pertama gratis.
- Kamu bakal bayar ini. Secara harfiah, semoga.
- Bilang ke ember, biayanya dihapus.
- Ini kekalahan jenis invasif.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Senang berbisnis denganmu.
- Biaya diterima. Dalam bentuk harga diri.
- Balik lagi bawa uang pas.
- Waduk aku, aturan aku.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Denda telat!
- Senarmu nunggak iuran!
- Lain kali, bawa uang tunai.

### Patin Juru Stempel

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Patin Juru Stempel
- **Jenis (di Buku Ikan):** PATIN
- **Julukan (banner saat ikan ditarik ke darat):** BAGIAN ADMINISTRASI KOPERASI
- **Deskripsi (Buku Ikan):** Mengurus berkas koperasi waduk dengan dedikasi total. Minta tiga rangkap untuk segala hal. Belum pernah menyelesaikan satu antrean pun.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **PATIN JURU STEMPEL:** Punya izin mancing dari koperasi?
- **DARTO:** Aku nggak tahu ada yang begituan.
- **PATIN JURU STEMPEL:** Ada. Prosesnya dua minggu.
- **DARTO:** Boleh aku jual ikan ke koperasi aja?
- **PATIN JURU STEMPEL:** Khusus anggota. Isi formulir ini. Lalu lawan saya.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Silakan ambil nomor antrean.
- Duel ini butuh formulir yang sudah distempel.
- Fotokopi KTP tiga lembar, plus materai.
- Permohonan duel Anda disetujui. Pas-pasan.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Disetujui. Distempel. Dikalahkan.
- Berkas Anda dipindahkan ke bagian ember.
- Tanda tangan di sini. Dan di sini. Dan di ember.
- Proses selesai. Saya tidak suka.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Permohonan ditolak. Kurang stempel.
- Silakan kembali di hari kerja.
- Sistemnya lagi gangguan. Anda juga.
- Berikutnya!

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Formulir tidak lengkap!
- Permohonan Anda diteruskan. Ke jauh.
- Jam kantor sudah habis.

### Jelawat Influencer

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Jelawat Influencer
- **Jenis (di Buku Ikan):** JELAWAT
- **Julukan (banner saat ikan ditarik ke darat):** KONTEN KREATOR (37 PENGIKUT)
- **Deskripsi (Buku Ikan):** Merekam setiap duel untuk tiga puluh tujuh pengikutnya. Sudah dua kali menyuruh Darto mengulang adegan masuk. Pencahayaannya jelek.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **JELAWAT INFLUENCER:** Bentar! Udah live? Halo guys!
- **DARTO:** Kamu ngomong sama siapa?
- **JELAWAT INFLUENCER:** Pengikutku. Lambaikan tangan.
- **DARTO:** Aku nggak mau melambai ke waduk.
- **JELAWAT INFLUENCER:** Nggak sopan. Ini masuk thumbnail.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Halo guys! Hari ini kita lawan pemancing!
- Bentar, bentar, aku cari angle terbaik dulu.
- Jangan lupa like dan subscribe!
- Ini bakal jadi konten.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Cut! Boleh diulang?
- Kalah malah lebih banyak yang nonton.
- Embernya estetik banget, sih.
- Akun pemancing ini ada di deskripsi.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Dan selesai, guys!
- Potong! Jadiin klip!
- Makasih sudah masuk kontenku!
- Pengikut ke-38 segera datang.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Plot twist!
- Siaran langsung dari dasar waduk!
- Bersambung, guys!

### Betutu Mager

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Betutu Mager
- **Jenis (di Buku Ikan):** BETUTU
- **Julukan (banner saat ikan ditarik ke darat):** PEREBAHAN PROFESIONAL
- **Deskripsi (Buku Ikan):** Mahal, langka, dan sama sekali tidak tertarik bergerak. Menyambar kail cuma karena posisinya lebih dekat daripada camilan yang ia mau.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **BETUTU MAGER:** Mmh. Taruh lagi. Aku lagi istirahat.
- **DARTO:** Kamu yang makan kailku.
- **BETUTU MAGER:** Itu benda yang paling dekat dari mulutku.
- **DARTO:** Harganya mahal tapi melek aja susah.
- **BETUTU MAGER:** Dua-duanya bisa benar. Ayo duel. Pelan-pelan.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Aduh. Harus banget?
- Lima menit lagi.
- Aku lawan kamu sambil rebahan. Itu gayaku.
- Bangunkan aku kalau sudah selesai.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Ya sudah. Embernya kelihatan nyaman juga.
- Terlalu capek untuk kesal.
- Gendong aku. Pelan-pelan.
- Nggak apa-apa. Semuanya nggak apa-apa. Zzz.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Tadi itu butuh tenaga. Aku mau tidur lagi.
- Zzz... hah? Aku menang?
- Malas pun bisa kalahkan capek.
- Jangan bangunkan aku buat tanding ulang.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Nggak. Terlalu repot.
- Aku keluar. Secara harfiah.
- Jam tidur. Dadah.

### Jenderal Toman

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Jenderal Toman
- **Jenis (di Buku Ikan):** TOMAN
- **Julukan (banner saat ikan ditarik ke darat):** PANGLIMA PERAIRAN DALAM
- **Deskripsi (Buku Ikan):** Gabus raksasa yang melatih Sersan Gabus dan tidak menyesal sedikit pun. Mengatur waduk seperti asrama tentara. Belum pernah meninggikan suara. Tidak pernah perlu.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **JENDERAL TOMAN:** Jadi. Kamu yang mengalahkan sersanku.
- **DARTO:** Dia banyak teriak.
- **JENDERAL TOMAN:** Dia dilatih untuk itu. Aku tidak.
- **DARTO:** Kok malah lebih seram.
- **JENDERAL TOMAN:** Bagus. Takut adalah pelajaran pertama.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Istirahat di tempat. Tidak akan lama.
- Sersanku bercerita tentangmu. Tidak baik.
- Kamu memasuki wilayah komandoku. Lapor.
- Strategi, Darto. Bukan tenaga.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Eksekusi yang baik. Bubar jalan.
- Silakan beri tahu sersan. Dia akan lari keliling.
- Mundur taktis ke ember. Dicatat.
- Kamu bertarung dengan disiplin. Aku setuju.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Misi selesai.
- Kembalilah kalau sudah punya rencana.
- Perairan dalam bertahan.
- Keberanianmu dicatat. Teknikmu tidak.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Lepas kontak.
- Senarmu keluar barisan.
- Penarikan selesai.

### Bandeng Tanpa Duri

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Bandeng Tanpa Duri
- **Jenis (di Buku Ikan):** BANDENG
- **Julukan (banner saat ikan ditarik ke darat):** BERSERTIFIKAT TANPA DURI (BUATAN SENDIRI)
- **Deskripsi (Buku Ikan):** Mengaku tanpa duri, jadi katanya paling gampang dijual. Durinya paling banyak se-muara. Bohong soal hal lain juga.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **BANDENG TANPA DURI:** Sebelum kamu tanya: nggak ada duri. Satu pun nggak.
- **DARTO:** Dari sini aku bisa lihat durinya.
- **BANDENG TANPA DURI:** Itu hiasan.
- **DARTO:** Bu Yati bakal nyabutin satu-satu dari giginya.
- **BANDENG TANPA DURI:** Kalau gitu dia harus menang dulu. Kamu juga.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Kabar baik: aku nggak ada durinya!
- Percaya deh. Aku yang paling jujur.
- Aku nggak pernah kalah. Ini duel pertamaku.
- Sebenarnya aku hiu.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Aku sengaja ngalah. Itu benar. Mungkin.
- Bilang ke Bu Yati aku nggak ada durinya. Dia bakal percaya.
- Aku bahkan nggak di ember. Jangan dilihat.
- Aduh. Itu satu-satunya duriku.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Aku selalu menang. Yang ini benar.
- Aku nggak pernah di sini.
- Dadah! Sekarang aku lumba-lumba.
- Kamu kalah sama ikan tanpa duri. Pikirkan itu.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Aku tanpa duri! Langsung lolos!
- Itu bukan aku. Itu bandeng lain.
- Bohong deh, aku masih di kail. Dadah!

### Buntal Pemarah

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Buntal Pemarah
- **Jenis (di Buku Ikan):** BUNTAL
- **Julukan (banner saat ikan ditarik ke darat):** SUMBU PENDEK, BADAN BULAT
- **Deskripsi (Buku Ikan):** Cepat marah dan lebih cepat lagi membulat. Bersikeras bahwa ia tidak menggembung. Ia sedang menggembung.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **BUNTAL PEMARAH:** Lihat apa kamu?
- **DARTO:** Badanmu makin besar.
- **BUNTAL PEMARAH:** NGGAK. Ini ukuran normalku.
- **DARTO:** Kamu segede bola.
- **BUNTAL PEMARAH:** Cukup. Sekarang aku marah.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Jangan. Sentuh. Duriku.
- Kamu bikin aku kembung. Berhenti.
- Aku BUKAN bulat. Ini otot.
- Satu kata lagi, ukuranku jadi dua kali lipat.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Hmph. Aku mengempis karena dendam.
- Ya sudah. Tapi embernya terlalu kecil untuk amarahku.
- Ugh. Sekarang aku bulat DAN kalah.
- Jangan lihat aku. Aku masih kembung.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- HA! Takutlah pada bola!
- Itu yang terjadi kalau aku kesal.
- Aku masih marah. Pergi sana.
- Bagus. Sekarang aku bisa mengempis dengan tenang.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- TERLALU BULAT UNTUK DIPEGANG!
- Aku menggelinding pergi sebagai protes!
- Jangan ikuti aku. Aku berduri.

### Glodok Pelari

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Glodok Pelari
- **Jenis (di Buku Ikan):** GLODOK
- **Julukan (banner saat ikan ditarik ke darat):** IKAN TERCEPAT DI LUMPUR
- **Deskripsi (Buku Ikan):** Berlari di lumpur lebih cepat dari makhluk bersirip mana pun. Latihan setiap air surut. Punya rekor pribadi dan selalu menyebutnya.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **GLODOK PELARI:** Hati-hati. Kaki ini sudah diasuransikan.
- **DARTO:** Ikan nggak punya kaki.
- **GLODOK PELARI:** Sirip. Sirip lari. Sama aja.
- **DARTO:** Kamu ikan yang lari di lumpur.
- **GLODOK PELARI:** Dan kamu orang yang kalah lomba. Bersedia.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Kamu menangkapku pas putaran pemanasan.
- Aku bisa jalan di darat. Kamu bisa berenang? Kayaknya nggak.
- Bersedia.
- Rekor pribadiku di bawah tiga detik. Tanya rekor apa.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Rekor terburuk baru. Dicatat.
- Aku jalan sendiri ke ember, makasih.
- Kecepatanmu bagus. Kamu cocok di lumpur.
- Aku lagi pendinginan. Itu alasanku.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Rekor pribadi!
- Sampai jumpa di garis finis. Aku sudah lama di sini.
- Air surut, kecepatan naik.
- Larimu kayak orang dikejar utang.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Lari!
- Aku cabut! Jalan kaki!
- Curi start! Punyaku!

### Kakap Sosialita

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Kakap Sosialita
- **Jenis (di Buku Ikan):** KAKAP PUTIH
- **Julukan (banner saat ikan ditarik ke darat):** SOSIALITA MUARA
- **Deskripsi (Buku Ikan):** Hadir di setiap arisan di muara dan menilai pakaian semua orang. Memanggil semua orang sayang, dan itu tidak pernah pujian.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **KAKAP SOSIALITA:** Permisi. Kamu tahu harga aku berapa?
- **DARTO:** Lebih mahal dari motorku, kayaknya.
- **KAKAP SOSIALITA:** Sayang, semuanya lebih mahal dari motormu.
- **DARTO:** Ikan mas emas juga bilang begitu.
- **KAKAP SOSIALITA:** Berarti dia punya selera. Ayo cepat selesaikan.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Sayang, kamu datang pakai baju itu?
- Aku ada arisan. Cepat sedikit.
- Kamu tahu aku siapa? Nggak? Kasihan.
- Berantem itu tren musim lalu. Ya sudah.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Sayang, ember itu bukan estetikaku.
- Bilang ke semua orang aku kalah dengan anggun.
- Ugh. Habis ini aku butuh spa.
- Oke. Tapi pengacaraku akan dengar soal ini.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Muah! Jangan telepon aku.
- Lucu. Kamu sudah berusaha.
- Aku telat brunch. Dah, sayang.
- Kekalahan cocok buatmu, sayang.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Ciao!
- Senarmu murahan sekali, sayang.
- Aku punya tempat yang lebih baik.

### Sembilang Tua

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Sembilang Tua
- **Jenis (di Buku Ikan):** SEMBILANG
- **Julukan (banner saat ikan ditarik ke darat):** PENUNGGU AKAR BAKAU
- **Deskripsi (Buku Ikan):** Makhluk tertua di muara, termasuk pohon bakaunya. Sudah mengeluhkan ikan-ikan muda, air pasang, dan harga segala sesuatu sejak sebelum Darto lahir.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **SEMBILANG TUA:** Hm. Matamu mirip dia.
- **DARTO:** Mata siapa?
- **SEMBILANG TUA:** Pria yang dulu mencari kepiting di sini. Dulu sekali. Orang baik.
- **DARTO:** Bapak mertuaku dulu mancing di sini.
- **SEMBILANG TUA:** Kalau begitu bertarunglah dengan baik. Demi dia.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Zaman dulu, pemancing minta izin dulu.
- Aku sudah lihat pasang yang lebih tua dari kamu.
- Hati-hati. Patilku lebih tua dari alasan-alasanmu.
- Pohon bakau ingat aku waktu muda. Samar-samar.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Hmph. Kamu mengingatkanku pada pria yang dulu mancing di sini.
- Duel yang bagus, anak muda.
- Bawa aku. Pinggangku juga sudah pegal.
- Muara bakal membicarakan ini puluhan tahun.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Anak zaman sekarang.
- Kembalilah kalau sudah paham pasang surut.
- Akar bertahan. Aku juga.
- Aku sudah kalah duel sebelum kamu lahir. Bukan hari ini.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Pasang membawaku pulang.
- Terlalu buru-buru. Seperti semuanya.
- Sabar itu cara lama.

### Tongkol Ojol

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Tongkol Ojol
- **Jenis (di Buku Ikan):** TONGKOL
- **Julukan (banner saat ikan ditarik ke darat):** SELALU OTW
- **Deskripsi (Buku Ikan):** Selalu mengantar sesuatu ke suatu tempat dengan buru-buru. Ratingnya bintang lima dan jadwalnya padat sekali. Mau duel di sela-sela orderan.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **TONGKOL OJOL:** Maaf, Bapak pemesan saya?
- **DARTO:** Bukan. Aku pemancing.
- **TONGKOL OJOL:** Kalau gitu lepasin, saya ada orderan.
- **DARTO:** Memangnya tongkol bisa ngantar apa?
- **TONGKOL OJOL:** Kekalahan. Kilat. Ayo.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Ada orderan sepuluh menit lagi. Ayo cepat.
- OTW! Maksudku, sudah di sini!
- Bintang lima kalau kamu cepat kalah.
- Aku lagi dikejar waktu, Om.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Orderan dibatalkan.
- Mohon beri penilaian untuk kinerja saya.
- Ya sudah. Ember jadi titik antar terakhir.
- Rating hancur. Makasih, Om.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Pesanan sampai!
- Bintang lima buat aku!
- Harus jalan, ada orderan lagi!
- Tip opsional. Kalah nggak.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Telat nih!
- Lewat jalan tikus di laut dalam!
- Orderan berikutnya nunggu!

### Layur Penyair

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Layur Penyair
- **Jenis (di Buku Ikan):** LAYUR
- **Julukan (banner saat ikan ditarik ke darat):** PENYAIR AIR PASANG MALAM
- **Deskripsi (Buku Ikan):** Panjang, keperakan, dan dramatis soal apa saja. Membacakan puisi tentang bulan, laut, dan bayangannya sendiri. Kebanyakan bayangannya sendiri.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **LAYUR PENYAIR:** Siapa yang mengusik penyair di tengah bait?
- **DARTO:** Orang yang punya utang dan joran.
- **LAYUR PENYAIR:** Betapa tragis. Betapa indah.
- **DARTO:** Kebanyakan cuma tragis.
- **LAYUR PENYAIR:** Mari kita bertarung, dan menjadikannya seni.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Wahai pemancing, kau telah mengail seorang penyair.
- Bulan menangis. Kau pun akan begitu.
- Pandanglah perakku. Lalu putus asalah.
- Setiap duel adalah puisi. Yang ini tragedi.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Akhir yang sedih. Jenis favoritku.
- Ember. Betapa sederhana nan tragis.
- Catat ini. Buat berirama.
- Aku jatuh, laksana pasang senja.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Dan demikianlah, sang penyair berenang pergi.
- Kekalahanmu adalah baitku.
- Laut bertepuk tangan. Pelan-pelan.
- Tamat.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Senar ini, seperti cinta, telah putus.
- Aku kembali ke air yang gelap.
- Selamat tinggal, pemancing tanpa rima.

### Barakuda Rentenir

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Barakuda Rentenir
- **Jenis (di Buku Ikan):** BARAKUDA
- **Julukan (banner saat ikan ditarik ke darat):** PINJAMAN KILAT, GIGI LEBIH KILAT
- **Deskripsi (Buku Ikan):** Menawarkan pinjaman instan kepada siapa saja yang terlihat lelah. Menyebut bunganya fleksibel. Darto selalu menolak, setiap kali.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **BARAKUDA RENTENIR:** Kamu kelihatan capek. Perlu pinjaman kecil?
- **DARTO:** Nggak.
- **BARAKUDA RENTENIR:** Langsung cair. Tanpa banyak tanya.
- **DARTO:** Nggak ada jalan pintas. Aku sudah selesai sama yang begitu.
- **BARAKUDA RENTENIR:** Kalau begitu kita pakai cara yang susah.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Butuh uang cepat? Bisa kubantu. Tanda tangan di sini.
- Bunga rendah. Moral lebih rendah.
- Utangmu lambat. Bisa kubikin cepat.
- Semua orang akhirnya bayar ke aku.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Kamu bakal balik. Semua selalu balik.
- Ya sudah. Ember nggak pakai bunga.
- Jalan pintas itu bagian yang gampang, ya?
- Respek. Kamu baca tulisan kecilnya.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Bunga bertambah.
- Bayar pakai harga diri.
- Tawaranku masih berlaku. Selamanya.
- Uang kilat, pemancing lambat.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Telat bayar!
- Senarmu gagal bayar!
- Nanti kutagih.

### Kerapu Juragan

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Kerapu Juragan
- **Jenis (di Buku Ikan):** KERAPU
- **Julukan (banner saat ikan ditarik ke darat):** PUNYA TIGA KAPAL (KATANYA)
- **Deskripsi (Buku Ikan):** Punya tiga kapal, satu gudang, dan suara yang sangat keras. Membuat juru lelang TPI pingsan karena menawar harganya sendiri. Dapat harga bagus.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **KERAPU JURAGAN:** Hati-hati dengan barang dagangan.
- **DARTO:** Kamu barang dagangannya.
- **KERAPU JURAGAN:** Tepat. Dan aku mahal.
- **DARTO:** Bu Yati yang menentukan itu.
- **KERAPU JURAGAN:** Kalau gitu ayo bernegosiasi. Pakai tinju.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Kamu tahu siapa pemilik dermaga ini? Aku. Sebagian.
- Kubayar kamu buat lempar aku balik. Nggak? Ya sudah.
- Bisnis dulu. Baru kekerasan.
- Kapal-kapalku menonton.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Kesepakatan bagus. Buat kamu.
- Bilang ke Bu Yati aku minta harga pantas.
- Ya sudah. Embernya nanti kubeli.
- Kamu jago nawar, pemancing.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Transaksi selesai.
- Nggak ada yang bisa ngalahin juragan di dermaganya sendiri.
- Kerja buat aku aja. Gaji awal: nggak ada.
- Anak buahku bakal dengar soal ini. Keras-keras.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Aku membeli kebebasanku!
- Kembali ke kapal!
- Senarmu kemurahan.

### Kapten Layaran

- **Nama (di banner tangkapan, kotak dialog, Roda Nasib, Buku Ikan, nota):** Kapten Layaran
- **Jenis (di Buku Ikan):** IKAN LAYARAN
- **Julukan (banner saat ikan ditarik ke darat):** LEGENDA LAUT LEPAS
- **Deskripsi (Buku Ikan):** Makhluk tercepat di laut dan cerita tertua di dermaga. Kata para pelaut, siapa pun yang mengalahkannya tak akan butuh jalan pintas lagi. Para pelaut memang banyak omong.

**Pertemuan pertama** (saat ikan ini pertama kali ditarik ke darat):

- **KAPTEN LAYARAN:** Jadi. Pemancing dari danau itu.
- **DARTO:** Sekarang semua ikan kenal aku?
- **KAPTEN LAYARAN:** Air saling bercerita. Danau, kali, laut.
- **DARTO:** Berarti kamu tahu aku hampir selesai.
- **KAPTEN LAYARAN:** Kalau begitu tunjukkan bagaimana kamu menyelesaikan sesuatu.

**Saat ikan ditarik ke darat (sebelum Roda Nasib, setelah pertemuan pertama). Satu dari:**

- Laut bercerita tentangmu, Darto.
- Kamu sudah jauh dari danau kecil itu.
- Kembangkan layarmu. Anginnya bagus.
- Hanya yang sabar yang sampai ke laut lepas.

**Setelah kamu menang duel (layar hasil). Satu dari:**

- Pelayaran yang bagus, pemancing.
- Laut akan mengingat pasang ini.
- Pulanglah. Keluargamu menunggu.
- Kamu tidak mengambil jalan pintas. Bagus.

**Setelah ikan menang duel dan kabur (layar hasil). Satu dari:**

- Laut itu luas. Coba lagi.
- Belum, Darto. Tapi sebentar lagi.
- Kapten yang baik tahu kapan harus putar balik.
- Pasang akan membawamu kembali.

**Saat senar putus waktu menggulung (layar memancing). Satu dari:**

- Laut lepas memanggil.
- Tahan senarnya, bukan amarahnya.
- Selamat tinggal, untuk sekarang.

## 6. Reaksi Darto setelah duel

Satu kalimat Darto di kotak dialog, tepat setelah kalimat ikan.

**Setelah menang duel (layar hasil):**

- Masuk ember. Tolong jangan dimasukkan ke hati.
- Nggak nyangka ini sekarang dihitung kerja.
- Bagus. Bu Yati bakal nanya-nanya lagi.
- Satu ikan lebih dekat. Itu cukup.

**Setelah kalah duel (layar hasil):**

- Ya jelas dia bisa berantem. Ya jelas dia bisa menang.
- Orang rumah nggak perlu tahu soal tadi.
- Ya sudah. Berikutnya.
- Aku ke sini niatnya santai. Kesalahan besar.

**Setelah senar putus waktu menggulung (layar memancing):**

- Kekencengan. Salahku.
- Pelan-pelan, Darto. Itu ikan, bukan debt collector.
- Karier senar itu lebih pendek dari dugaanku.

## 7. Kredit penutup

Teks kredit yang bergulir setelah epilog, dan juga dari tombol KREDIT di Menu Utama. Tulisan TAHAN UNTUK LEWATI ada di bawah layar.

| Jenis | Teks | Kunci |
|---|---|---|
| Judul | CATCH AND BRAWL | `credits.01` |
| Subjudul | Game yang sangat serius tentang ikan-ikan yang sangat tidak serius. | `credits.02` |
| Peran | DESAIN GAME | `credits.03` |
| Nama | Arief Nugraha | `credits.04` |
| Peran | PEMROGRAMAN | `credits.05` |
| Nama | Arief Nugraha | `credits.06` |
| Peran | SISTEM 3D & UI PROSEDURAL | `credits.07` |
| Nama | Arief Nugraha | `credits.08` |
| Peran | SISTEM AUDIO PROSEDURAL | `credits.09` |
| Nama | Arief Nugraha | `credits.10` |
| Peran | PENULISAN | `credits.11` |
| Nama | Arief Nugraha | `credits.12` |
| Peran | PENJAMINAN MUTU | `credits.13` |
| Nama | Arief Nugraha | `credits.14` |
| Peran | TERIMA KASIH KHUSUS | `credits.15` |
| Nama | Semua orang yang pernah menghabiskan Minggu sore di tepi danau. | `credits.16` |
| Penutup | Terima kasih sudah menghabiskan Minggu sore di Danau Cempaka. | `credits.17` |
| Penutup | Tolong jangan berdebat dengan ikan. | `credits.18` |

| Teks | Kunci |
|---|---|
| TAHAN UNTUK LEWATI | `credits.skip` |

## 8. Warung Bu Yati

Layar Warung, dibuka dengan tombol WARUNG di layar memancing. Isinya buku bertab di bagian bawah, Bu Yati di latar 3D, dan kotak dialog untuk percakapan.

### Judul

Judul di atas layar Warung.

| Teks | Kunci |
|---|---|
| WARUNG BU YATI | `market.header.title` |

### Tab

Tab di atas halaman buku Warung. TABUNGAN menggantikan UTANG setelah utang lunas.

| Teks | Kunci |
|---|---|
| JUAL | `market.tab.sell` |
| UPGRADE | `market.tab.upgrades` |
| UTANG | `market.tab.debt` |
| BUKU IKAN | `market.tab.fish_book` |
| REKOR | `market.tab.records` |
| TABUNGAN | `market.tab.savings` |

### Tombol keluar

Tombol di bawah layar Warung.

| Teks | Kunci |
|---|---|
| KELUAR WARUNG | `market.leave` |

### Petunjuk kunjungan pertama

Petunjuk berkedip saat kunjungan pertama: jual, buka tab utang, bayar, lalu upgrade.

| Teks | Kunci |
|---|---|
| JUAL TANGKAPANMU | `market.hint.sell` |
| BUKA TAB UTANG | `market.hint.debt_tab` |
| BAYAR Rp 10.000 | `market.hint.pay` |
| UPGRADE BISA NANTI — ATAU SEKARANG. TERSERAH. | `market.hint.upgrades` |

### Tab JUAL

Isi ember dan tombol jual.

| Teks | Kunci |
|---|---|
| EMBERMU | `market.sell.title` |
| Tidak ada yang bisa dijual. Danaunya di sebelah sana. | `market.sell.empty` |
| {count}x {name} | `market.sell.row` |
| masing-masing {value} | `market.sell.each` |
| {base} x BOS {multiplier} = {value} | `market.sell.boss` |
| TOTAL | `market.sell.total` |
| JUAL SEMUA | `market.sell.sell_all` |
| JUAL IKAN | `market.sell.sell_fish` |
| JUAL SAMPAH | `market.sell.sell_trash` |

### Nota

Popup NOTA setelah menjual.

| Teks | Kunci |
|---|---|
| NOTA | `market.receipt.title` |
| Uang sekarang: {cash} | `market.receipt.cash` |

### Tab UTANG

Buku utang, tombol bayar, dan pengatur jumlah (ATUR JUMLAH).

| Teks | Kunci |
|---|---|
| BUKU UTANG | `market.debt.title` |
| Awal | `market.debt.original` |
| Dibayar | `market.debt.paid` |
| Sisa | `market.debt.remaining` |
| BAYAR {amount} | `market.debt.pay_amount` |
| BAYAR SEMAMPUNYA | `market.debt.pay_all` |
| ATUR JUMLAH | `market.debt.pay_custom` |
| Tanpa bunga. Tanpa biaya. Tanpa tenggat. | `market.debt.terms` |
| Utangnya lunas. Semuanya. | `market.debt.cleared` |
| Kamu bisa bayar sampai {amount} sekarang. | `market.debt.available` |
| -10RB | `market.debt.step_minus_10k` |
| -1RB | `market.debt.step_minus_1k` |
| +1RB | `market.debt.step_plus_1k` |
| +10RB | `market.debt.step_plus_10k` |

### Tab TABUNGAN

Menggantikan tab UTANG setelah utang lunas.

| Teks | Kunci |
|---|---|
| TABUNGAN KELUARGA | `market.savings.title` |
| Tersimpan | `market.savings.total` |
| TABUNG {amount} | `market.savings.deposit` |
| TABUNG SEMUA | `market.savings.deposit_all` |
| Tidak ada hadiah. Cuma angka yang terus bertambah. | `market.savings.terms` |

### Tab UPGRADE

Kartu tiap barang upgrade.

| Teks | Kunci |
|---|---|
| UPGRADE | `market.upgrade.title` |
| LV.{level} / {max} | `market.upgrade.level` |
| Sekarang: {effect} | `market.upgrade.current` |
| Berikutnya: {effect} | `market.upgrade.next` |
| UPGRADE  {price} | `market.upgrade.buy` |
| LEVEL MAKS | `market.upgrade.max` |

### Perlengkapan jalan

Bagian perlengkapan di tab UPGRADE: barang yang membuka tempat mancing baru.

| Teks | Kunci |
|---|---|
| PERLENGKAPAN JALAN | `market.gear.title` |
| BELI  {price} | `market.gear.buy` |
| SUDAH PUNYA | `market.gear.owned` |
| Terbuka bersama {location}. | `market.gear.locked` |

### Tab BUKU IKAN

Terbuka setelah adegan Rp 600.000. Isinya kartu tiap ikan.

| Teks | Kunci |
|---|---|
| BUKU IKAN | `market.book.title` |
| Belum terbuka. Nanti ada yang memintanya. | `market.book.locked` |
| ??? | `market.book.unknown` |
| Belum dikalahkan. | `market.book.undiscovered` |
| Terberat {weight} kg   Ketemu {encounters}   Menang {wins}   Kalah {losses} | `market.book.stats` |
| Duel favorit: {duel} | `market.book.favourite` |
| Duel favorit: belum ada | `market.book.favourite_none` |
| LEGENDA | `market.book.legend` |
| Tempat yang belum kamu datangi. | `market.book.spot_locked` |

### Tab REKOR

Judul halaman rekor (isinya di bagian Rekor).

| Teks | Kunci |
|---|---|
| REKOR | `market.records.title` |

## 9. Antarmuka lainnya

### 9.1 Layar pembuka

Layar pertama saat game dibuka, sebelum Menu Utama: judul dan status pemuatan yang bergantian. Judul dan isi error hanya muncul bila data game rusak.

| Teks | Kunci |
|---|---|
| CATCH AND BRAWL | `boot.title_line_1` |
| Mengecek cuaca... | `boot.status.platform` |
| Mengecek kotak pancing... | `boot.status.data` |
| Membuka buku catatan... | `boot.status.save` |
| Menyetel radio... | `boot.status.audio` |
| Berangkat ke Danau Cempaka... | `boot.status.done` |
| PENGECEKAN DATA GAME GAGAL | `boot.error.title` |
| Build ini berisi data game yang tidak valid dan tidak bisa dijalankan. | `boot.error.body` |

### 9.2 Menu Utama

Menu Utama: tombol-tombol utama, nomor versi, dua dialog konfirmasi MAIN BARU (muncul bila sudah ada save), dan dialog keluar game (tombol Back Android di Menu Utama).

| Teks | Kunci |
|---|---|
| CATCH AND BRAWL | `menu.title_line_1` |
| LANJUTKAN | `menu.continue` |
| MAIN BARU | `menu.new_game` |
| CARA BERMAIN | `menu.how_to_play` |
| PENGATURAN | `menu.settings` |
| KREDIT | `menu.credits` |
| v{version} | `menu.version` |
| MULAI PERMAINAN BARU? | `menu.new_game_confirm_1.title` |
| Memulai permainan baru akan menimpa save yang sekarang. | `menu.new_game_confirm_1.body` |
| TIMPA SAVE | `menu.new_game_confirm_1.confirm` |
| YAKIN? | `menu.new_game_confirm_2.title` |
| Progresmu yang sekarang akan hilang selamanya. | `menu.new_game_confirm_2.body` |
| MULAI BARU | `menu.new_game_confirm_2.confirm` |
| PERTAHANKAN SAVE | `menu.new_game_confirm.cancel` |
| KELUAR DARI GAME? | `menu.quit_confirm.title` |
| Progresmu sudah tersimpan. | `menu.quit_confirm.body` |
| LANJUT MAIN | `menu.quit_confirm.stay` |
| KELUAR | `menu.quit_confirm.quit` |

### 9.3 Teks umum

Tombol dan label yang dipakai di banyak popup dan layar.

| Teks | Kunci |
|---|---|
| MEMUAT... | `common.loading` |
| OK | `common.ok` |
| BATAL | `common.cancel` |
| TUTUP | `common.close` |

### 9.4 Pengaturan

Pengaturan, dibuka dari Menu Utama (PENGATURAN) atau dari menu Jeda. Judul bagian, nama setelan, nilai pilihan, catatan, dan dialog HAPUS SAVE.

| Teks | Kunci |
|---|---|
| PENGATURAN | `settings.title` |
| AUDIO | `settings.section.audio` |
| UTAMA | `settings.audio.master_volume` |
| MUSIK | `settings.audio.music_volume` |
| EFEK SUARA | `settings.audio.sfx_volume` |
| SUARA SEKITAR | `settings.audio.ambience_volume` |
| ANTARMUKA | `settings.audio.ui_volume` |
| SAVE | `settings.section.save` |
| HAPUS SAVE | `settings.reset_save` |
| Belum ada save yang bisa dihapus. | `settings.no_save` |
| HAPUS SAVE | `settings.reset_confirm.title` |
| Hapus semua progres? | `settings.reset_confirm_1.body` |
| Ini tidak bisa dibatalkan. Beneran mau dihapus? | `settings.reset_confirm_2.body` |
| HAPUS | `settings.reset_confirm.confirm` |
| RITME | `settings.section.rhythm` |
| DENYUT KETUKAN: NYALA | `settings.rhythm.beat_pulse_on` |
| DENYUT KETUKAN: MATI | `settings.rhythm.beat_pulse_off` |
| Offset input | `settings.rhythm.rhythm_input_offset_ms` |
| Offset visual | `settings.rhythm.rhythm_visual_offset_ms` |
| {ms} ms | `settings.rhythm.ms` |
| KALIBRASI RITME | `settings.rhythm.calibrate` |
| TAMPILAN | `settings.section.visual` |
| AKSESIBILITAS | `settings.section.accessibility` |
| KONTROL | `settings.section.controls` |
| KONTROL KEYBOARD | `settings.controls.open` |
| Grafis | `settings.option.quality_preset` |
| Layar penuh | `settings.option.fullscreen_web` |
| Skala UI | `settings.option.ui_scale` |
| Skala teks | `settings.option.text_scale` |
| HUD kontras tinggi | `settings.option.high_contrast_hud` |
| Guncangan HUD | `settings.option.hud_shake` |
| Kurangi gerakan | `settings.option.reduced_motion` |
| Kurangi kilatan | `settings.option.reduced_flash` |
| Input panco | `settings.option.arm_input_mode` |
| Tangan dominan | `settings.option.mobile_handedness` |
| Kecepatan dialog | `settings.option.dialogue_speed` |
| Tahan untuk lewati | `settings.option.skip_hold_sec` |
| NYALA | `settings.value.on` |
| MATI | `settings.value.off` |
| DIKURANGI | `settings.value.reduced` |
| TEKAN CEPAT | `settings.value.mash` |
| BANTU TAHAN | `settings.value.hold_assist` |
| TANGAN KANAN | `settings.value.right` |
| TANGAN KIRI | `settings.value.left` |
| INSTAN | `settings.value.instant` |
| CEPAT | `settings.value.fast` |
| NORMAL | `settings.value.normal` |
| SANTAI | `settings.value.relaxed` |
| RENDAH | `settings.value.low` |
| SEDANG | `settings.value.medium` |
| TINGGI | `settings.value.high` |
| {sec} DTK | `settings.value.seconds` |
| BAHASA | `settings.section.language` |
| Bahasa | `settings.option.language` |
| OTOMATIS | `settings.value.auto` |
| ENGLISH | `settings.value.en` |
| INDONESIA | `settings.value.id` |
| Teks yang sudah tampil akan berganti setelah kamu keluar dari layar ini. | `settings.language_note` |
| PRIVASI | `settings.section.privacy` |
| PRIVASI DAN LISENSI | `settings.privacy.open` |
| Versi web ini menyimpan save-mu di penyimpanan browser ini. Menghapus data situs atau penyimpanan browser akan menghapusnya. | `settings.web_storage_note` |

### 9.5 Pengaturan → Kontrol keyboard

Popup daftar tombol keyboard. Hanya ada di PC dan versi web (tidak muncul di HP). Nama aksi, petunjuk, dan dialog bila tombol bentrok.

| Teks | Kunci |
|---|---|
| KONTROL | `controls.title` |
| Mancing: Spasi atau Klik<br>Warung: E<br>Ember: B<br>Jeda: Esc<br>Tinju Empang: A D J K<br>Panco Maut: Spasi<br>Joget Koplo: S D J K<br>Suwit: 1 2 3 C<br>Silat Kali: S D J K<br>Tarik Tambang: Spasi<br>Adu Gasing: Spasi<br>Panjat Pinang: A D | `controls.body` |
| Pilih aksi, lalu tekan tombol barunya. Esc untuk batal. | `controls.hint` |
| KEMBALIKAN DEFAULT | `controls.reset` |
| TEKAN SEBUAH TOMBOL... | `controls.press_key` |
| BELUM DIATUR | `controls.unbound` |
| MOUSE {button} | `controls.mouse_button` |
| TOMBOL SUDAH DIPAKAI | `controls.conflict.title` |
| {key} dipakai untuk {action}. Tukar kedua tombol? | `controls.conflict.body` |
| TUKAR | `controls.conflict.swap` |
| Lempar / tarik | `controls.action.fish_cast` |
| Gulung | `controls.action.fish_reel` |
| Buka Warung | `controls.action.open_market` |
| Buka Ember | `controls.action.open_bucket` |
| Jeda | `controls.action.pause` |
| Tinju: hindar kiri | `controls.action.box_dodge_left` |
| Tinju: hindar kanan | `controls.action.box_dodge_right` |
| Tinju: jab | `controls.action.box_jab` |
| Tinju: cross | `controls.action.box_cross` |
| Panco: dorong | `controls.action.arm_mash` |
| Joget: jalur 1 | `controls.action.dance_lane_1` |
| Joget: jalur 2 | `controls.action.dance_lane_2` |
| Joget: jalur 3 | `controls.action.dance_lane_3` |
| Joget: jalur 4 | `controls.action.dance_lane_4` |
| Suwit: batu | `controls.action.suwit_rock` |
| Suwit: gunting | `controls.action.suwit_scissors` |
| Suwit: kertas | `controls.action.suwit_paper` |
| Suwit: cincin | `controls.action.suwit_charm` |
| Konfirmasi | `controls.action.ui_confirm` |
| Kembali | `controls.action.ui_cancel` |

### 9.6 Pengaturan → Kalibrasi ritme

Popup kalibrasi ritme untuk Joget Koplo dan Silat: ketuk mengikuti ketukan, lalu game menyarankan offset.

| Teks | Kunci |
|---|---|
| KALIBRASI RITME | `calibration.title` |
| Ketuk tombol apa saja atau layar di setiap bunyi klik. Dua ketukan pertama cuma pemanasan. | `calibration.body` |
| Menyiapkan bunyi klik... | `calibration.preparing` |
| IKUTI KETUKANNYA | `calibration.tap` |
| {count} / {total} | `calibration.count` |
| Ketukannya kurang. Coba lagi? | `calibration.too_few` |
| Offset yang disarankan: {ms} ms | `calibration.result` |
| Terima, coba lagi, atau atur sendiri di Pengaturan. | `calibration.result_body` |
| TERIMA | `calibration.accept` |
| COBA LAGI | `calibration.retry` |

### 9.7 Pengaturan → Privasi dan lisensi

Popup PRIVASI: ringkasan, kebijakan privasi lengkap (tombol BACA KEBIJAKAN PRIVASI LENGKAP), dan halaman lisensi.

| Teks | Kunci |
|---|---|
| PRIVASI | `privacy.title` |
| TIDAK PERLU AKUN | `privacy.summary.1` |
| TANPA IKLAN | `privacy.summary.2` |
| TANPA ANALITIK | `privacy.summary.3` |
| GAME TIDAK MENGUMPULKAN DATA PRIBADI | `privacy.summary.4` |
| DATA SAVE TETAP DI PERANGKAT/BROWSER INI | `privacy.summary.5` |
| BACA KEBIJAKAN PRIVASI LENGKAP | `privacy.read_full` |
| LISENSI | `privacy.licenses` |
| Catch and Brawl dirancang untuk dimainkan tanpa membuat akun dan tanpa mengirim data permainan ke pengembang. | `privacy.policy.intro` |
| Pengumpulan data | `privacy.policy.collection.title` |
| Game ini tidak mengumpulkan, menjual, atau membagikan informasi pribadi. Game ini tidak memakai SDK iklan, SDK analitik, SDK pelacakan, layanan lokasi, akses kamera, akses mikrofon, kontak, atau login media sosial. | `privacy.policy.collection.body` |
| Data save lokal | `privacy.policy.local.title` |
| Progres permainan, pengaturan, rekor, progres Buku Ikan, dan progres cerita disimpan secara lokal di perangkatmu atau, untuk versi web, di penyimpanan browser. Informasi ini tidak dikirim oleh game ke server pengembang. | `privacy.policy.local.body` |
| Versi web | `privacy.policy.web.title` |
| Versi web di-hosting oleh platform distribusi pihak ketiga. Platform tersebut bisa memproses informasi teknis sesuai kebijakan privasinya sendiri saat mengirimkan file game. Catch and Brawl tidak menambahkan sistem analitik, iklan, atau pelacakan sendiri. | `privacy.policy.web.body` |
| Ekspor dan impor save | `privacy.policy.export.title` |
| Jika build web menyediakan ekspor save manual, file save hanya dibuat saat kamu memintanya. Impor membaca file yang kamu pilih secara lokal untuk memulihkan progres permainan. | `privacy.policy.export.body` |
| Anak-anak dan informasi pribadi | `privacy.policy.children.title` |
| Game ini tidak meminta pemain memberikan informasi pribadi dan tidak menyediakan fitur chat, konten buatan pengguna, atau akun. | `privacy.policy.children.body` |
| Perubahan kebijakan ini | `privacy.policy.changes.title` |
| Jika versi mendatang menambahkan fitur yang mengubah cara data ditangani, kebijakan ini akan diperbarui sebelum versi tersebut dirilis. | `privacy.policy.changes.body` |
| Kontak | `privacy.policy.contact.title` |
| Untuk pertanyaan privasi atau dukungan, hubungi: [PUBLISHER SUPPORT EMAIL] | `privacy.policy.contact.body` |
| Dibuat dengan Godot Engine. Godot adalah perangkat lunak gratis dan open source dengan lisensi MIT: | `privacy.licenses.intro` |
| Godot menyertakan komponen pihak ketiga dengan lisensinya masing-masing: {list}. | `privacy.licenses.components` |
| Teks memakai font Fredoka karya Milena Brandão dan Hafontia (Copyright 2016 The Fredoka Project Authors) dengan SIL Open Font License 1.1, serta Chewy karya Font Diner (Copyright (c) 2010 by Font Diner, Inc DBA Sideshow) dengan Apache License 2.0. Teks lengkap kedua lisensi ada di bawah: | `privacy.licenses.fonts` |

### 9.8 Cara Bermain

Popup CARA BERMAIN dari Menu Utama: satu tab per mode, isi tab di bawahnya.

| Teks | Kunci |
|---|---|
| CARA BERMAIN | `howto.title` |
| MANCING | `howto.tab.fishing` |
| TINJU EMPANG | `howto.tab.boxing` |
| PANCO MAUT | `howto.tab.arm_wrestle` |
| JOGET KOPLO | `howto.tab.dance` |
| SUWIT | `howto.tab.suwit` |
| WARUNG | `howto.tab.market` |
| LEMPAR kail, lalu tunggu sambaran yang asli.<br>Gigitan kecil cuma peringatan.<br>Saat pelampung tenggelam, TARIK sebelum waktu reaksinya habis.<br>Saat menggulung, TAHAN GULUNG untuk menaikkan penanda dan LEPAS untuk menurunkannya.<br>Jaga penanda tetap di zona hijau supaya ikannya berhasil ditarik.<br>Kalau tegangan senar mencapai batas, ikannya kabur. | `howto.body.fishing` |
| Baca arah serangan yang diisyaratkan ikan.<br>HINDAR ke arah yang ditunjuk, lalu balas dengan JAB atau CROSS.<br>Hindaran yang benar di detik terakhir jadi HINDARAN SEMPURNA dan membuka balasan yang lebih kuat.<br>Asal pencet tombol tidak sebagus memperhatikan. | `howto.body.boxing` |
| Tekan GAS berulang-ulang untuk mendorong posisi ke arahmu.<br>Menekan menghabiskan stamina.<br>Berhenti sebentar untuk memulihkannya.<br>Stamina rendah berarti dorongan lebih lemah, bukan langsung kalah. | `howto.body.arm_wrestle` |
| Tekan keempat jalur saat not sampai di garis target.<br>Timing SEMPURNA dapat skor paling tinggi.<br>Meleset memutus combo-mu.<br>Kopi Tubruk hanya mengubah kecepatan gerak not, tidak pernah mengubah ketukannya. | `howto.body.dance` |
| Siapa duluan menang dua kali, dia juaranya.<br>Seri tidak dihitung.<br>Ikan memberi isyarat, tapi sebagian ikan lebih suka bohong.<br>Cincin Batu Akik memperlihatkan langkah asli ikan sebentar. | `howto.body.suwit` |
| Jual tangkapan untuk dapat uang.<br>Pakai uang untuk upgrade peralatan atau bayar utang.<br>Bayar utang memajukan cerita.<br>Upgrade duluan bisa bikin mancing berikutnya lebih gampang.<br>Tidak ada urutan yang salah. | `howto.body.market` |
| SILAT KALI | `howto.tab.silat` |
| TARIK TAMBANG | `howto.tab.tambang` |
| ADU GASING | `howto.tab.gasing` |
| PANJAT PINANG | `howto.tab.pinang` |
| PERJALANAN | `howto.tab.travel` |
| Ikan memperagakan rangkaian jurus.<br>Ulangi dengan urutan yang sama memakai empat panah.<br>Kalau benar, kamu membalas.<br>Salah jurus atau kehabisan waktu, kamu yang kena.<br>Tiga balasan memenangkan duel. | `howto.body.silat` |
| Penanda berayun di sepanjang bar.<br>Ketuk TARIK saat penanda di zona hijau.<br>Menarik di luar zona bikin kamu terpeleset.<br>Ikan terus menarik sepanjang waktu.<br>Tarik tali melewati garismu untuk menang. | `howto.body.tambang` |
| Ketuk sekali untuk membidik dan sekali untuk tenaga.<br>Lemparan lurus dan kuat berputar paling lama.<br>Saat gasing beradu, ketuk ketika lingkaran menutup.<br>Ketukan yang pas menghantam lebih keras.<br>Gasing yang terakhir berputar menang. | `howto.body.gasing` |
| Ketuk KIRI dan KANAN bergantian untuk memanjat.<br>Sisi yang sama dua kali bikin merosot.<br>Terlalu cepat bikin tiangnya licin.<br>Jaga ritme tetap stabil.<br>Siapa duluan sampai puncak, dia menang. | `howto.body.pinang` |
| Tempat baru terbuka seiring utang terbayar.<br>Beli perlengkapan tiap tempat di warung, lalu ketuk peta di tepi air.<br>Setiap tempat punya ikan dan duel sendiri.<br>Penjualan selalu di warung. | `howto.body.travel` |

### 9.9 Menu Jeda

Menu Jeda: tombol jeda (ikon ||) di pojok kanan atas saat memancing, di warung, dan saat duel. Muncul juga otomatis bila aplikasi ditinggal (catatan fokus hilang). Dialog KELUAR TANPA MENYIMPAN muncul bila penyimpanan terakhir gagal.

| Teks | Kunci |
|---|---|
| JEDA | `pause.title` |
| LANJUT | `pause.resume` |
| KONTROL | `pause.controls` |
| MUSIK: NYALA | `pause.music_on` |
| MUSIK: MATI | `pause.music_off` |
| SUARA: NYALA | `pause.sound_on` |
| SUARA: MATI | `pause.sound_off` |
| PENGATURAN | `pause.settings` |
| KE MENU UTAMA | `pause.quit` |
| JEDA - KLIK UNTUK LANJUT | `pause.focus_lost` |
| KELUAR TANPA MENYIMPAN? | `pause.quit_unsaved.title` |
| Progres terbarumu gagal disimpan. Keluar sekarang bisa membuatnya hilang. | `pause.quit_unsaved.body` |
| TETAP KELUAR | `pause.quit_unsaved.confirm` |

### 9.10 Memancing

Layar memancing: tombol aksi besar di bawah, petunjuk di atas layar, chip HUD, banner hasil (umpan hilang, senar putus, sampah, ikan besar), dan petunjuk ember dan peta.

| Teks | Kunci |
|---|---|
| TEKAN SPASI ATAU KLIK UNTUK MELEMPAR | `fishing.prompt.cast_keyboard` |
| KETUK LEMPAR | `fishing.prompt.cast_touch` |
| TUNGGU PELAMPUNGNYA... | `fishing.prompt.wait` |
| GIGITAN KECIL BUKAN SAMBARAN ASLI | `fishing.prompt.nibble` |
| ADA SESUATU DI BAWAH SANA... | `fishing.prompt.warning` |
| TARIK! | `fishing.prompt.strike` |
| TAHAN UNTUK MENGGULUNG | `fishing.prompt.reel_keyboard` |
| TAHAN GULUNG | `fishing.prompt.reel_touch` |
| LEPAS UNTUK MENGENDURKAN | `fishing.prompt.release` |
| JAGA PENANDA DI ZONA HIJAU | `fishing.prompt.zone` |
| SENAR TEGANG! | `fishing.prompt.stress` |
| IKAN DAPAT | `fishing.prompt.landed` |
| KECEPETAN. BELUM ADA APA-APA. | `fishing.prompt.false_strike` |
| LEMPAR | `fishing.action.cast` |
| TARIK | `fishing.action.strike` |
| TAHAN GULUNG | `fishing.action.reel` |
| TUNGGU... | `fishing.action.wait` |
| UMPAN HILANG | `fishing.result.missed.title` |
| Umpannya dimakan, ikannya pergi. Masih banyak yang lain. | `fishing.result.missed.body` |
| SENAR PUTUS | `fishing.result.line_break.title` |
| Ikannya lolos. | `fishing.result.line_break.body` |
| Langsung masuk ember. | `fishing.result.trash.body` |
| IKAN BESAR! | `fishing.result.big_one` |
| {weight} kg | `fishing.result.weight` |
| Belum ada duel di build ini. Langsung masuk ember. | `fishing.result.no_duel` |
| EMBERMU TIDAK ADA BATASNYA. ANGGAP SAJA REZEKI. | `fishing.bucket.tutorial` |
| EMBER {count} | `fishing.hud.bucket` |
| WARUNG | `fishing.hud.market` |
| TARIKAN | `fishing.hud.landing` |
| TEGANGAN | `fishing.hud.stress` |
| PASANG | `fishing.tide.high` |
| SURUT | `fishing.tide.low` |
| Ada tempat baru! Ketuk peta untuk pindah. | `fishing.hint.travel` |

### 9.11 Intip ember

Popup isi ember, dibuka dengan mengetuk chip EMBER di layar memancing.

| Teks | Kunci |
|---|---|
| EMBER | `bucket.title` |
| Belum ada apa-apa. Danaunya tidak buru-buru. | `bucket.empty` |
| {count}x {name} | `bucket.row` |
| Perkiraan harga jual: {value} | `bucket.estimate` |

### 9.12 Lokasi mancing

Nama tempat, sifat airnya, dan perlengkapan yang membukanya. Muncul di peta perjalanan, HUD memancing, Buku Ikan, dan tab perlengkapan di Warung.

| Teks | Kunci |
|---|---|
| Danau Cempaka | `location.cempaka.name` |
| Air tenang. Tempat semuanya dimulai. | `location.cempaka.trait` |
| Kali Kenanga | `location.kenanga.name` |
| Arus deras: penanda gulung terus turun. | `location.kenanga.trait` |
| Kail Arus | `location.kenanga.gear` |
| Kail berat yang tetap tertanam di air deras. Membuka Kali Kenanga. | `location.kenanga.gear_desc` |
| Waduk Melati | `location.melati.name` |
| Air dalam: tunggu lebih lama, ikan lebih besar. | `location.melati.trait` |
| Senar Panjang | `location.melati.gear` |
| Menjangkau air dalam. Membuka Waduk Melati. | `location.melati.gear_desc` |
| Muara Anggrek | `location.anggrek.name` |
| Pasang surut: pasang bawa ikan, surut bawa sampah. | `location.anggrek.trait` |
| Sepatu Bot | `location.anggrek.gear` |
| Menjaga kamu tetap berdiri di lumpur muara. Membuka Muara Anggrek. | `location.anggrek.gear_desc` |
| Dermaga Mawar | `location.mawar.name` |
| Ombak: senar menegang setiap ombak datang. | `location.mawar.trait` |
| Joran Laut | `location.mawar.gear` |
| Cukup kuat untuk ikan laut dan air garam. Membuka Dermaga Mawar. | `location.mawar.gear_desc` |

### 9.13 Peta perjalanan

Popup MAU KE MANA?, dibuka dengan tombol peta di layar memancing.

| Teks | Kunci |
|---|---|
| MAU KE MANA? | `travel.title` |
| KAMU DI SINI | `travel.here` |
| BERANGKAT | `travel.go` |
| Terbuka setelah {amount} utang terbayar. | `travel.locked_debt` |
| Terbuka di kunjunganmu berikutnya ke warung. | `travel.locked_event` |
| Beli {gear} di warung dulu. | `travel.need_gear` |
| Buku Ikan: {count} / {total} | `travel.fish_count` |
| ??? | `travel.locked_name` |

### 9.14 Barang upgrade

Nama dan efek barang di tab UPGRADE Warung (baris "Sekarang:" dan "Berikutnya:").

| Teks | Kunci |
|---|---|
| Belum ada bonus | `upgrade.effect.none` |
| Waktu tunggu gigitan {percent}% dari biasanya | `upgrade.effect.bait` |
| Zona hijau +{width} lebih lebar | `upgrade.effect.rod` |
| HP tinju {hp}, stamina panco {stamina}% | `upgrade.effect.tonic` |
| Not joget melaju {percent}% dari kecepatan biasa | `upgrade.effect.coffee` |
| {charges} intipan Suwit per duel | `upgrade.effect.charm` |
| Umpan Pelet Super | `upgrade.bait.name` |
| Joran Serat Karbon | `upgrade.rod.name` |
| Jamu Pegal Linu | `upgrade.tonic.name` |
| Kopi Tubruk | `upgrade.coffee.name` |
| Cincin Batu Akik | `upgrade.charm.name` |

### 9.15 Sampah

Nama sampah yang bisa tersangkut di kail. Muncul di banner tangkapan, ember, dan daftar jual.

| Teks | Kunci |
|---|---|
| Kaleng Karatan | `trash.trash_can.name` |
| Sandal Jepit Sebelah | `trash.trash_sandal.name` |
| Ban Purba | `trash.trash_tyre.name` |

### 9.16 Rekor

Tab REKOR di Warung: daftar statistik permainan.

| Teks | Kunci |
|---|---|
| Total Lemparan | `records.total_casts` |
| Tarikan Berhasil | `records.successful_strikes` |
| Senar Putus | `records.lines_broken` |
| Sampah Didapat | `records.trash_caught` |
| Ikan Didapat | `records.fish_landed` |
| Duel Menang | `records.duel_wins` |
| Duel Kalah | `records.duel_losses` |
| Menang Tinju Empang | `records.boxing_wins` |
| Menang Panco Maut | `records.arm_wrestle_wins` |
| Menang Joget Koplo | `records.dance_wins` |
| Menang Suwit | `records.suwit_wins` |
| Don Arwana Dikalahkan | `records.don_arowana_defeated` |
| Ikan Terbesar | `records.largest_fish` |
| Total Penjualan Ikan | `records.lifetime_sales` |
| Total Utang Dibayar | `records.lifetime_debt_paid` |
| Total Waktu Main | `records.play_time` |
| Belum ada | `records.largest_none` |
| {weight} kg ({name}) | `records.largest_value` |
| Menang Silat Kali | `records.silat_wins` |
| Menang Tarik Tambang | `records.tambang_wins` |
| Menang Adu Gasing | `records.gasing_wins` |
| Menang Panjat Pinang | `records.pinang_wins` |
| Legenda Dikalahkan | `records.legends_defeated` |
| Tempat Dikunjungi | `records.spots_visited` |

### 9.17 Roda Nasib

Layar Roda Nasib yang muncul setelah ikan ditarik ke darat dan menentukan jenis duel.

| Teks | Kunci |
|---|---|
| RODA NASIB | `wheel.title` |
| TAHAN UNTUK LEWATI | `wheel.skip_hold` |
| {duel}! | `wheel.result` |

### 9.18 Nama duel dan kartu hasil duel

Nama tiap duel (di Roda Nasib, Buku Ikan, dan Cara Bermain) dan kartu hasil di akhir duel (KAMU MENANG / IKANNYA KABUR).

| Teks | Kunci |
|---|---|
| Tinju Empang | `duel.boxing` |
| Panco Maut | `duel.arm_wrestle` |
| Joget Koplo | `duel.dance` |
| Suwit | `duel.suwit` |
| KAMU MENANG | `duel.result.win.title` |
| {fish} MASUK EMBER | `duel.result.win.body` |
| IKANNYA KABUR | `duel.result.loss.title` |
| LANJUT | `duel.result.continue` |
| TINJU EMPANG | `duel.boxing.upper` |
| PANCO MAUT | `duel.arm_wrestle.upper` |
| JOGET KOPLO | `duel.dance.upper` |
| SUWIT | `duel.suwit.upper` |
| Silat Kali | `duel.silat` |
| Tarik Tambang | `duel.tambang` |
| Adu Gasing | `duel.gasing` |
| Panjat Pinang | `duel.pinang` |
| SILAT KALI | `duel.silat.upper` |
| TARIK TAMBANG | `duel.tambang.upper` |
| ADU GASING | `duel.gasing.upper` |
| PANJAT PINANG | `duel.pinang.upper` |

### 9.19 Duel: Tinju Empang

Layar duel tinju: banner pembuka di bawah nama ikan, tombol sentuh, HUD, petunjuk serangan, tutorial pertama, dan babak penentuan.

| Teks | Kunci |
|---|---|
| DARTO | `boxing.hud.player` |
| {seconds} | `boxing.hud.timer` |
| 1 PUKULAN | `boxing.hud.sudden_death` |
| TINJU EMPANG | `boxing.intro.subtitle` |
| HINDAR KIRI | `boxing.prompt.dodge_left` |
| HINDAR KANAN | `boxing.prompt.dodge_right` |
| BALAS! | `boxing.prompt.counter` |
| HINDARAN SEMPURNA! | `boxing.prompt.perfect` |
| BABAK PENENTUAN | `boxing.sudden_death.title` |
| Pukulan bersih berikutnya yang menang. | `boxing.sudden_death.body` |
| HINDAR | `boxing.button.dodge_left` |
| HINDAR | `boxing.button.dodge_right` |
| JAB | `boxing.button.jab` |
| CROSS | `boxing.button.cross` |
| {left} / {right}  HINDAR        {jab}  JAB        {cross}  CROSS | `boxing.keys` |
| BACA ARAH SERANGAN IKAN, LALU HINDAR KE ARAH ITU | `boxing.tutorial.read` |
| SEKARANG BALAS DENGAN JAB ATAU CROSS | `boxing.tutorial.counter` |

### 9.20 Duel: Panco Maut

Layar duel panco: banner pembuka, tombol, HUD, tutorial, cengkeraman mendadak, dan tanding ulang.

| Teks | Kunci |
|---|---|
| TENAGA {percent}% | `arm.hud.power` |
| CENGKERAM | `arm.hud.sudden_grip` |
| ! IKANNYA MENGEJANG ! | `arm.hud.burst_warning` |
| !! LEDAKAN !! | `arm.hud.burst` |
| GAS! | `arm.button.mash` |
| {key}  GAS | `arm.keys` |
| PANCO MAUT | `arm.intro.subtitle` |
| TEKAN GAS BERULANG UNTUK MENDORONG TANGAN KE ARAHMU | `arm.tutorial.mash` |
| STAMINA RENDAH BIKIN DORONGAN LEMAH. BERHENTI SEBENTAR UNTUK PULIH. | `arm.tutorial.rest` |
| CENGKERAMAN PENENTUAN | `arm.sudden_grip.title` |
| Terlalu tipis. Siapa duluan unggul, dia yang menang. | `arm.sudden_grip.body` |
| TANDING ULANG | `arm.rematch.title` |
| Don Arwana tidak menerima hasil seri. Sepuluh detik. | `arm.rematch.body` |
| TAHAN! | `arm.button.hold` |
| TAHAN UNTUK MENDORONG TANGAN KE ARAHMU | `arm.tutorial.hold` |

### 9.21 Duel: Joget Koplo

Layar duel joget (ritme): banner pembuka, penilaian tiap not, tutorial, dan babak tambahan bila seri.

| Teks | Kunci |
|---|---|
| SIAP-SIAP | `dance.get_ready` |
| Menyetel kendang... {percent}% | `dance.loading` |
| JOGET KOPLO | `dance.intro.subtitle` |
| TEKAN KEEMPAT JALUR SAAT NOT SAMPAI DI GARIS | `dance.tutorial.hit` |
| {combo} COMBO | `dance.hud.combo` |
| SEMPURNA | `dance.judgment.perfect` |
| MANTAP | `dance.judgment.great` |
| OKE | `dance.judgment.good` |
| MELESET | `dance.judgment.miss` |
| SEKALI LAGI | `dance.encore.title` |
| Seri persis. Empat not lagi. | `dance.encore.body` |

### 9.22 Duel: Suwit

Layar duel suwit (gajah-orang-semut): banner pembuka, pilihan, hasil tiap ronde, intipan jimat, dan tutorial.

| Teks | Kunci |
|---|---|
| BATU | `suwit.move.rock` |
| GUNTING | `suwit.move.scissors` |
| KERTAS | `suwit.move.paper` |
| CINCIN ({count}) | `suwit.charm` |
| TANPA CINCIN | `suwit.charm_none` |
| IKANNYA MENUNJUKKAN... | `suwit.tell` |
| LANGKAH ASLI: {move} | `suwit.real_move` |
| PILIHAN PANIK! | `suwit.panic_pick` |
| RONDE INI MILIKMU | `suwit.outcome.win` |
| RONDE INI MILIK IKAN | `suwit.outcome.loss` |
| SERI. ULANG. | `suwit.outcome.draw` |
| SUWIT. SIAPA DULUAN MENANG DUA. | `suwit.intro.subtitle` |
| PERHATIKAN ISYARATNYA. ADA IKAN YANG BOHONG. | `suwit.tutorial` |
| {rock} BATU    {scissors} GUNTING    {paper} KERTAS    {charm} CINCIN | `suwit.keys` |
| IKAN | `suwit.hud.fish` |

### 9.23 Duel: Silat Kali (Kali Kenanga)

Duel khas Kali Kenanga: perhatikan jurus ikan, lalu tirukan.

| Teks | Kunci |
|---|---|
| SILAT KALI. TIGA BALASAN. | `silat.intro.subtitle` |
| PERHATIKAN JURUSNYA, LALU ULANGI | `silat.tutorial` |
| PERHATIKAN | `silat.watch` |
| GILIRANMU | `silat.your_turn` |
| BALAS! | `silat.counter` |
| SALAH JURUS | `silat.wrong` |
| KELAMAAN | `silat.slow` |
| KIRI | `silat.move.left` |
| BAWAH | `silat.move.down` |
| ATAS | `silat.move.up` |
| KANAN | `silat.move.right` |
| {left} {down} {up} {right}  JURUS | `silat.keys` |

### 9.24 Duel: Tarik Tambang (Waduk Melati)

Duel khas Waduk Melati.

| Teks | Kunci |
|---|---|
| TARIK TAMBANG | `tambang.intro.subtitle` |
| KETUK TARIK DI ZONA HIJAU | `tambang.tutorial` |
| TARIK | `tambang.button` |
| TARIK! | `tambang.pull` |
| TERPELESET! | `tambang.slip` |
| {key}  TARIK | `tambang.keys` |
| ! IKANNYA PASANG KUDA-KUDA ! | `tambang.heave_warning` |
| !! TARIK !! | `tambang.heave` |

### 9.25 Duel: Adu Gasing (Muara Anggrek)

Duel khas Muara Anggrek.

| Teks | Kunci |
|---|---|
| ADU GASING | `gasing.intro.subtitle` |
| KETUK UNTUK BIDIK, KETUK LAGI UNTUK TENAGA | `gasing.tutorial` |
| BIDIK | `gasing.aim` |
| TENAGA | `gasing.power` |
| BERADU! | `gasing.clash` |
| HANTAMAN SEMPURNA! | `gasing.perfect` |
| HANTAMAN BAGUS | `gasing.good` |
| LEMPAR | `gasing.button.throw` |
| HANTAM | `gasing.button.hit` |
| {key}  KETUK | `gasing.keys` |
| PUTARAN {value} | `gasing.spin` |
| IKANNYA MENGHANTAM | `gasing.miss` |
| KECEPATAN | `gasing.early` |

### 9.26 Duel: Panjat Pinang (Dermaga Mawar)

Duel khas Dermaga Mawar.

| Teks | Kunci |
|---|---|
| PANJAT PINANG. SIAPA CEPAT SAMPAI PUNCAK. | `pinang.intro.subtitle` |
| KIRI, KANAN, KIRI, KANAN. STABIL. | `pinang.tutorial` |
| KIRI | `pinang.button.left` |
| KANAN | `pinang.button.right` |
| MEROSOT! | `pinang.slip` |
| LICIN! PELAN-PELAN. | `pinang.grease` |
| {left} / {right}  PANJAT | `pinang.keys` |
| LICIN | `pinang.grease_label` |

### 9.27 Layar hasil

Layar hasil setelah duel.

| Teks | Kunci |
|---|---|
| {fish} MASUK EMBER | `result.detail.win` |

### 9.28 Pesan error penyimpanan

Dialog yang muncul bila save rusak, berasal dari versi lain, atau gagal disimpan.

| Teks | Kunci |
|---|---|
| SAVE TIDAK BISA DIBACA | `error.save_corrupt.title` |
| Save-mu sepertinya rusak. Cadangannya sudah disimpan bila memungkinkan. | `error.save_corrupt.body` |
| COBA LAGI | `error.save_corrupt.retry` |
| MULAI BARU | `error.save_corrupt.new_game` |
| VERSI SAVE TIDAK DIDUKUNG | `error.save_unsupported.title` |
| Save ini dibuat oleh versi game yang tidak cocok. | `error.save_unsupported.body` |
| GAGAL MENYIMPAN | `error.save_failed.title` |
| Progres terbarumu mungkin belum tersimpan. Biarkan game tetap terbuka, lalu coba lagi. | `error.save_failed.body` |
| SIMPAN ULANG | `error.save_failed.retry` |
| LANJUT TANPA MENYIMPAN | `error.save_failed.continue` |

### 9.29 Kotak dialog

Petunjuk di pojok kanan bawah kotak dialog (di layar memancing, Warung, dan layar hasil).

| Teks | Kunci |
|---|---|
| KETUK UNTUK LANJUT | `dialogue.advance` |

### 9.30 Nama pembicara

Nama di label kotak dialog dan di aplikasi chat HP pada adegan cerita.

| Teks | Kunci |
|---|---|
| DARTO | `speaker.darto` |
| RINI | `speaker.rini` |
| NISA | `speaker.nisa` |
| BU YATI | `speaker.bu_yati` |

### 9.31 Adegan cerita: antarmuka

Teks tetap di adegan cerita: petunjuk lanjut, tahan untuk lewati, tombol kartu unlock, dan tampilan aplikasi chat di HP Darto. Kunci story.notice.* hanya dipakai bila adegan cerita tidak tersedia di build (tidak terjadi di versi rilis).

| Teks | Kunci |
|---|---|
| KETUK UNTUK LANJUT | `story.continue` |
| TAHAN UNTUK LEWATI | `story.skip_hold` |
| LANJUT | `story.unlock.continue` |
| Panggilan suara | `story.phone.call` |
| Rini | `story.phone.rini` |
| Nisa | `story.phone.nisa` |
| CepatCash | `story.phone.cepatcash` |
| Pesan | `story.phone.messages` |
| online | `story.phone.online` |
| Akun bisnis | `story.phone.business` |
| HARI INI | `story.phone.today` |
| 15.17 | `story.phone.clock` |
| 15.17 | `story.phone.time` |
| Ketik pesan | `story.phone.input` |
| BARU: BUKU IKAN | `story.notice.story_debt_600k.title` |
| Nisa minta dicatat. Usahakan catatannya akurat. | `story.notice.story_debt_600k.body` |

