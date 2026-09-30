# GAME DESIGN DOCUMENT

# MANCING MANIA: GELUT EDITION

### Definitive Game Design Document — Version 6.0 (Final Authoritative Production, Release & Maintenance Specification — Godot Edition)

**Alternate Working Title:** *Baku Hantam Empang*  
**Genre:** Cozy Fishing / Casual Arcade / Comedy / Minigame Collection / Light Narrative Progression  
**Engine:** Godot Engine 4.7 atau versi stable terbaru yang lebih baru  
**Primary Scripting Language:** Typed GDScript  
**Renderer Baseline:** Godot Compatibility Renderer  
**Distribution Platform:** Android native (Google Play Store) + Web (itch.io)  
**Android Package:** Signed release `.aab` (Android App Bundle)  
**Web Package:** Godot Web export, `index.html` di root paket itch.io  
**Visual Style:** Stylized 3D Low-Poly modern dengan detail menengah, clean silhouettes, warm lighting  
**Primary Mood:** Cozy, Warm, Sunday Afternoon, Nostalgic, Absurdly Funny  
**Setting:** Indonesia  
**In-Game Language:** English only  
**GDD Language:** Bahasa Indonesia  
**Language Policy:** Game release v1.0 tetap English-only; Bahasa Indonesia hanya digunakan di dokumen desain/development  
**Camera:** Mostly fixed/cinematic third-person composition depending on scene  
**Business Model:** Single-player premium/free game without IAP, gacha, loot boxes, energy systems, ad SDK, or microtransactions
**Network Model:** Offline-first single-player; no multiplayer/network gameplay
**Audio Policy:** 100% code-generated procedural audio; no external audio media files in v1.0
**Production Spec Status:** Final authoritative v1.0 specification; Sections 163–197 are binding production, release, and maintenance contracts

---

# 0. HIGH CONCEPT

*Mancing Mania: Gelut Edition* adalah game tentang seorang pria pengangguran bernama **Darto** yang sedang berusaha memperbaiki kehidupannya setelah kehilangan hampir seluruh hartanya akibat kecanduan judi online.

Darto sudah berhenti berjudi.

Masalahnya:

hutangnya belum ikut berhenti.

Dengan istrinya yang bekerja di pabrik dan anak mereka yang tinggal di boarding school, Darto merasa harus kembali memberikan sesuatu untuk keluarganya.

Tanpa modal besar, tanpa pekerjaan tetap, dan hanya bermodalkan sebuah joran tua, ember plastik, motor tua, serta pengetahuan memancing yang seadanya, Darto mencoba mencari penghasilan dengan menangkap dan menjual ikan dari sebuah danau kecil di pinggiran kota.

Masalah kedua muncul.

Ikan-ikan di danau tersebut ternyata tidak mau ditangkap begitu saja.

Setelah berhasil dipancing ke permukaan, ikan akan menantang Darto dalam salah satu dari empat duel absurd:

- Tinju.
- Panco.
- Joget koplo.
- Suwit.

Menangkan duel, dan ikan masuk ember.

Kalah, dan ikan akan mengejek Darto sebelum melompat kembali ke danau.

Ikan yang berhasil ditangkap dapat dijual di warung pasar kecil di pinggir danau.

Uangnya dapat digunakan untuk:

1. Membayar hutang.
2. Membeli upgrade.
3. Membantu Darto perlahan-lahan membangun kehidupan yang lebih baik.

Di balik komedi absurd mengenai ikan yang bisa bertinju terdapat cerita sederhana mengenai:

**tanggung jawab, keluarga, kegagalan, pemulihan, dan usaha mencari rezeki yang jujur.**

Namun game ini **bukan drama gelap**.

Keseluruhan pengalaman tetap:

**cozy, warm, funny, charming, slow-paced, dan terasa seperti Minggu sore yang panjang.**

---

# 1. GAME VISION

## 1.1 Fantasy Utama

Player harus merasakan:

> "Saya cuma ingin duduk santai memancing di pinggir danau... tapi setiap ikan yang saya tarik ke atas ternyata punya masalah pribadi dengan saya."

Fase memancing harus nyaman.

Suara air tenang.

Daun bergerak tertiup angin.

Motor Darto diparkir di bawah pohon.

Ada suara burung.

Sesekali terdengar dangdut dari kejauhan.

Kemudian:

**STRIKE!**

Ikan muncul.

Roda berputar.

Musik berubah.

Dan seekor lele berkumis tiba-tiba memakai sarung tinju.

Kontras itulah identitas utama game.

---

# 2. DESIGN PILLARS

Semua fitur baru harus mendukung minimal satu dari lima pilar berikut.

## PILLAR 1 — COZY BEFORE CHAOS

Fase memancing harus menjadi ruang bernapas.

Tidak ada musuh mengejar player.

Tidak ada countdown.

Tidak ada kebutuhan mendesak.

Player boleh berhenti dan menikmati lingkungan.

Duel adalah ledakan energi singkat di antara periode tenang tersebut.

---

## PILLAR 2 — ABSURD BUT INTERNALLY CONSISTENT

Seekor ikan bisa bertinju.

Itu absurd.

Namun setelah aturan tersebut diterima, game harus konsisten.

Ikan memiliki persona.

Ikan mempunyai kemampuan berbeda.

Setiap duel mengikuti rule yang jelas.

Humor muncul dari keseriusan dunia dalam memperlakukan sesuatu yang sebenarnya sangat konyol.

---

## PILLAR 3 — HONEST PROGRESS

Tema utama cerita adalah meninggalkan jalan pintas.

Darto kehilangan uang karena berharap mendapat uang secara instan.

Sekarang ia memperoleh uang melalui:

memancing → berusaha → menang → menjual hasil.

Tidak ada loot box.

Tidak ada gambling mechanic dengan uang player.

Wheel of Fate hanya menentukan jenis minigame dan tidak mempertaruhkan uang.

Progression selalu dapat dipahami.

---

## PILLAR 4 — SMALL LIFE, BIG PERSONALITY

Tidak ada penyelamatan dunia.

Tidak ada kerajaan.

Tidak ada perang besar.

Taruhannya sederhana:

- membayar hutang,
- menjaga hubungan dengan keluarga,
- menemukan pekerjaan yang bermartabat,
- pulang dengan perasaan sedikit lebih baik dibanding kemarin.

Hal kecil diperlakukan sebagai sesuatu yang berarti.

---

## PILLAR 5 — SUNDAY AFTERNOON

Setiap keputusan art dan audio harus melewati pertanyaan:

> "Apakah ini terasa seperti Minggu sore yang hangat di Indonesia?"

Referensi sensasi:

- matahari pukul 15:30–17:30,
- warna keemasan,
- bayangan pohon panjang,
- suara motor jauh,
- radio warung,
- suara burung,
- angin kecil,
- aroma gorengan yang hanya dapat dibayangkan player,
- plastik kursi warung,
- termos,
- spanduk yang sedikit pudar,
- danau yang tidak sempurna tetapi nyaman.

---

# 3. THEMATIC STATEMENT

Tema naratif utama:

> **Tidak ada tombol jackpot untuk memperbaiki hidup. Kadang-kadang yang bisa dilakukan hanyalah pulang, mencoba lagi besok, dan menghasilkan sedikit uang dengan jujur.**

Game tidak menghakimi Darto secara terus-menerus.

Ia memang membuat keputusan buruk.

Ia mengakuinya.

Ia berhenti.

Sekarang cerita membahas apa yang terjadi **setelah seseorang memutuskan berubah**.

---

# 4. SETTING

## 4.1 Lokasi

Game mengambil tempat di sekitar:

# DANAU CEMPAKA

Danau fiktif di pinggiran sebuah kota kecil di Indonesia.

Bukan destinasi wisata besar.

Bukan danau megah.

Danau Cempaka adalah tempat yang dikenal warga lokal.

Di sekitarnya terdapat:

- pepohonan rindang,
- rerumputan liar,
- jalan aspal kecil,
- warung sederhana,
- beberapa bangku plastik,
- lampu jalan,
- tiang listrik,
- rumah-rumah jauh di seberang air,
- kebun,
- suara masjid dari kejauhan,
- sesekali hajatan,
- beberapa pemancing NPC dekoratif yang sangat jauh,
- motor Darto.

NPC tidak harus memenuhi lokasi.

Dunia harus terasa hidup tetapi **tidak ramai**.

Negative space penting.

---

# 5. WAKTU DAN SUASANA

Mayoritas gameplay berlangsung dalam versi artistik dari:

## Minggu sore yang tidak pernah benar-benar berakhir.

Secara visual waktu bergerak sangat perlahan:

### Early Afternoon
15:15–16:00

Lebih terang.

Langit biru kekuningan.

### Golden Afternoon
16:00–17:00

Warna utama game.

Hangat.

Bayangan panjang.

### Late Afternoon
17:00–17:45

Sedikit lebih jingga.

Lampu warung mulai menyala.

Setelah beberapa sesi, lighting dapat berpindah secara halus.

Namun tidak ada sistem siang-malam realistis.

Player tidak pernah dipaksa berhenti karena malam.

---

# 6. TOKOH UTAMA

# DARTO

**Umur:** 39 tahun  
**Status:** Pengangguran  
**Peran:** Protagonis / Player Character

Darto bukan pecundang kartun.

Ia seseorang yang membuat keputusan buruk selama masa hidupnya.

Beberapa bulan tidak memiliki pekerjaan membuatnya semakin sering bermain judi online.

Awalnya jumlah kecil.

Kemudian mencoba mengejar kerugian.

Kerugian berikutnya lebih besar.

Tabungan habis.

Barang-barang rumah mulai dijual.

Kemudian ia menggunakan pinjaman online.

Akhirnya Darto menyadari bahwa tidak ada kemenangan besar yang akan mengembalikan semuanya.

Ia berhenti.

Game dimulai beberapa minggu setelah Darto terakhir berjudi.

### Kepribadian

- sedikit malas,
- gampang mengeluh,
- sebenarnya penyayang,
- malu terhadap kesalahannya,
- humor kering,
- tidak terlalu pintar berbicara,
- kompetitif dengan ikan untuk alasan yang bahkan ia sendiri tidak mengerti,
- sangat menghargai momen tenang.

### Visual

Darto tidak terlihat seperti hero.

- kaus polos agak longgar,
- celana pendek atau celana kain sederhana,
- sandal,
- topi lama,
- tas pinggang kecil,
- tubuh biasa,
- rambut sedikit berantakan.

Warna pakaian hangat dan sedikit faded.

Tidak banyak detail tekstur.

Semua low-poly.

---

# 7. KELUARGA DARTO

# RINI

**Umur:** 37  
**Peran:** Istri Darto  
**Pekerjaan:** Operator / pekerja produksi di sebuah pabrik lokal

Rini bukan karakter yang hanya berfungsi memarahi Darto.

Ia kecewa terhadap keputusan suaminya.

Namun ia juga melihat bahwa Darto benar-benar mencoba berubah.

Rini pragmatis.

Humornya sangat datar.

Ia biasanya mampu menghancurkan alasan Darto hanya dengan satu kalimat.

Contoh:

Darto:

> "Technically, I made money today."

Rini:

> "You sold a tire."

Darto:

> "A very profitable tire."

Rini:

> "Take a shower."

Hubungan mereka tidak sempurna tetapi masih memiliki kehangatan.

---

# 8. ANAK

# NISA

**Umur:** 14  
**Peran:** Anak Darto dan Rini  
**Status:** Tinggal di boarding school

Nisa tidak pulang setiap hari.

Interaksi utama melalui:

- pesan singkat,
- telepon,
- beberapa cutscene,
- kunjungan pada ending.

Nisa mengetahui ayahnya sedang mengalami masalah keuangan tetapi orang tuanya tidak menceritakan seluruh detail.

Ia menyukai cerita mengenai ikan-ikan aneh dari Danau Cempaka.

Seiring cerita berjalan, hubungan Darto dengan Nisa menjadi salah satu motivasi emosional utama.

Nisa mulai meminta:

> "Dad, send me a picture if you catch the golden one."

Darto kemudian mulai mengoleksi catatan ikan bukan hanya demi gameplay, tetapi juga karena ia ingin punya cerita untuk diceritakan kepada anaknya.

---

# 9. PEMILIK THE MARKET

# BU YATI

**Umur:** 56  
**Profesi:** Pemilik warung kecil dan pembeli hasil ikan

Bu Yati sudah mengenal Darto sejak lama.

Ia tidak terlalu tertarik dengan drama Darto.

Baginya yang penting:

> "Fish fresh?"

Darto:

> "Very."

Bu Yati:

> "Still moving?"

Darto:

> "Emotionally, yes."

Bu Yati bertindak sebagai:

- merchant,
- tutorial ekonomi,
- sumber gossip,
- comic straight-man,
- penjual upgrade,
- karakter yang perlahan menghargai konsistensi Darto.

---

# 10. ANTAGONIS NON-TRADISIONAL

Tidak ada villain manusia utama.

Konflik Darto adalah:

- hutang,
- rasa malu,
- kecenderungan mencari jalan pintas,
- ketidakpercayaan keluarganya yang perlahan harus diperbaiki,
- ikan yang kebetulan bisa bertinju.

Aplikasi pinjaman dibuat sebagai perusahaan fiktif:

# CEPATCASH

Tidak menggunakan merek perusahaan nyata.

Pesannya kadang absurd tetapi tidak mengandung ancaman kekerasan.

Contoh:

> PAYMENT REMINDER  
> Your outstanding balance remains outstanding.  
> We are also outstandingly disappointed.

Darto:

> "...Fair."

---

# 11. CERITA UTAMA

## Struktur

Narasi dibagi menjadi:

- Prologue
- Chapter 1: One Honest Fish
- Chapter 2: Small Money
- Chapter 3: The Long Way
- Chapter 4: Family Call
- Chapter 5: The Fish Everyone Talks About
- Chapter 6: Almost There
- Finale: Paid
- Epilogue: Sunday

Narasi tidak mengganggu gameplay terus-menerus.

Cutscene singkat.

Biasanya 20–60 detik.

Narasi muncul setelah milestone besar.

---

# 12. PROLOGUE — "ZERO"

## Opening Shot

Black screen.

Suara kipas angin.

Suara motor jauh.

Layar perlahan fade-in.

Darto duduk di lantai rumah.

Tidak ada musik.

Sebuah ponsel tua berada di meja.

UI ponsel menunjukkan:

**BANK BALANCE: Rp 18,430**

Kemudian:

**TOTAL DEBT: Rp 1,800,000**

Darto memandang layar.

Notifikasi CePatCash muncul.

Ia menghela napas.

Camera tidak dramatis.

Tidak ada tangisan.

Rini sedang mengenakan sepatu kerja.

### Dialogue

Rini:

> "I'm leaving."

Darto:

> "Yeah."

Rini berhenti.

> "Did you open it again?"

Darto:

> "No."

> "I deleted everything."

Rini:

> "Good."

Pause.

> "Deleting it is the easy part."

Rini pergi.

Suara pintu.

Darto menatap meja.

Di sudut ruangan ada:

- joran lama,
- ember biru,
- helm,
- kunci motor.

Ia berdiri.

Cut.

---

## MOTOR SHOT

Motor tua Darto berjalan di jalan kecil.

Tidak ada montage dramatis.

Hanya perjalanan santai.

Judul muncul:

# MANCING MANIA: GELUT EDITION

Kemudian:

**SUNDAY — 3:17 PM**

---

# 13. FIRST FISH

Player mendapatkan tutorial fishing.

Fish pertama scripted:

**Bruiser Catfish**

Setelah reel selesai:

Darto mengangkat ikan.

Hening.

Ikan membuka mata.

Menatap Darto.

Catfish:

> "Put me down."

Darto:

> "...What?"

Catfish:

> "You heard me."

Darto:

> "Fish don't talk."

Catfish:

> "And unemployed men don't usually argue with dinner."

Pause.

Catfish mengangkat sirip.

Sarung tinju muncul secara absurd.

> "Square up."

Wheel of Fate tutorial dimulai.

Untuk duel pertama, hasil Wheel dikunci menjadi:

**Tinju Empang**

Player mendapat tutorial.

Kemenangan duel pertama sangat mudah.

Jika player gagal, duel otomatis diberikan retry tutorial.

Tidak ada kemungkinan softlock di prologue.

---

# 14. CHAPTER 1 — ONE HONEST FISH

Setelah ikan pertama berhasil masuk ember, Darto pergi ke The Market.

Bu Yati membeli ikan.

Player menerima uang pertama.

Darto melihat nominalnya.

Tidak besar.

Tetapi ia tersenyum kecil.

Phone notification:

**DEBT PAYMENT AVAILABLE**

Tutorial pembayaran hutang dimulai.

Minimum tutorial payment:

Rp 10,000.

Setelah pembayaran:

**Debt Remaining: Rp 1,790,000**

Tidak ada confetti.

Hanya bunyi:

*ding.*

Darto:

> "One down."

Bu Yati:

> "One million seven hundred ninety thousand to go."

Darto:

> "...You didn't have to say the whole number."

---

# 15. NARRATIVE PROGRESSION

Progress cerita tidak berdasarkan waktu dunia nyata.

Tidak ada daily streak.

Tidak ada energy system.

Tidak ada bunga hutang bertambah.

Debt ditetapkan melalui restrukturisasi naratif menjadi:

# Rp 1,800,000

Angka tersebut tidak berubah kecuali player membayar.

Tujuannya:

memberikan motivasi tanpa menciptakan tekanan anxiety yang bertentangan dengan cozy tone.

---

# 16. DEBT MILESTONES

## Milestone 1 — Rp 100,000 Paid

Darto mulai percaya aktivitas memancing bisa menghasilkan.

Rini belum terlalu yakin.

---

## Milestone 2 — Rp 300,000 Paid

Rini menerima notifikasi pembayaran.

Ia mengirim pesan:

> "I saw the payment."

Darto:

> "Good payment or bad payment?"

Rini:

> "Payments are generally good, Darto."

---

## Milestone 3 — Rp 600,000 Paid

Nisa menelepon.

Ia bertanya tentang ikan aneh.

Fish Collection diperkenalkan secara naratif.

---

## Milestone 4 — Rp 1,000,000 Paid

Darto telah membayar lebih dari separuh.

Rini mulai berbicara mengenai masa depan, bukan hanya hutang.

---

## Milestone 5 — Rp 1,400,000 Paid

Bu Yati mengatakan ada pembeli yang menyukai hasil tangkapan Darto.

Fish sale tidak lagi terasa seperti aktivitas sementara.

---

## Milestone 6 — Rp 1,650,000 Paid

Darto hampir selesai.

Tidak ada musik kemenangan besar.

Danau terasa sama.

Ini disengaja.

Hidup tidak tiba-tiba berubah karena progress bar hampir penuh.

---

## Milestone 7 — Rp 1,800,000 Paid

Debt:

# Rp 0

Narrative finale dimulai.

---

# 17. FINALE — "PAID"

Darto menekan tombol:

**PAY REMAINING**

Saldo berkurang.

Debt menjadi:

**Rp 0**

Tidak ada efek jackpot.

Tidak ada roda.

Tidak ada ledakan.

CePatCash notification:

> YOUR BALANCE HAS BEEN FULLY SETTLED.

Kemudian:

> Thank you.

Darto menunggu.

> "...That's it?"

Ponsel tidak menjawab.

Ia tertawa kecil.

---

# 18. FINAL FAMILY SCENE

Hari Minggu berikutnya.

Motor Darto terlihat terparkir.

Namun sekarang ada dua helm.

Rini duduk di kursi plastik dekat danau.

Nisa sedang berada di rumah dari boarding school.

Mereka membawa makanan sederhana.

Darto masih memancing.

Nisa:

> "So which one punched you?"

Darto:

> "The catfish."

Rini:

> "He lost twice."

Darto:

> "Why are we keeping statistics?"

Nisa:

> "For science."

Pelampung Darto tenggelam.

Darto berdiri.

Rini:

> "Don't start a fight."

Darto:

> "I don't start them."

Di air:

Don Arowana muncul sebentar.

> "LIAR."

Cut to black.

Credits.

---

# 19. POST-GAME

Setelah credits:

# FREE FISHING MODE

Semua sistem tetap tersedia.

Player dapat:

- melengkapi Fish Book,
- membeli semua upgrade,
- mengejar statistik,
- mengalahkan Don Arowana kembali,
- mengumpulkan uang,
- terus bermain tanpa batas.

Debt Ledger berubah menjadi:

# FAMILY SAVINGS

Uang bisa disetor sebagai score progression pasca-game.

Tidak ada reward gameplay wajib.

Hanya milestone kosmetik dan statistik.

---

# 20. CORE GAMEPLAY LOOP

1. Datang ke Danau Cempaka.
2. Cast.
3. Menunggu.
4. Fish/Trash encounter.
5. Strike.
6. Reel.
7. Jika trash → langsung Bucket.
8. Jika fish → Wheel of Fate.
9. Duel.
10. Menang → Fish masuk Bucket.
11. Kalah → Fish mengejek → kembali ke air.
12. Kembali memancing.
13. Sewaktu-waktu pergi ke The Market.
14. Sell catch.
15. Pilih:
   - bayar hutang,
   - membeli upgrade,
   - menyimpan uang.
16. Kembali memancing.
17. Narrative milestone terbuka.
18. Ulangi.

---

# 21. PLAYER AGENCY DALAM EKONOMI

Player memiliki keputusan strategis sederhana:

### Bayar Hutang Sekarang

Progress cerita lebih cepat.

Tetapi kemampuan player belum meningkat.

### Upgrade Lebih Dahulu

Mengurangi kesulitan atau meningkatkan efisiensi.

Progress hutang tertunda.

Namun earning rate jangka panjang meningkat.

Tidak ada pilihan yang salah.

---

# 22. STARTING STATE

Saat gameplay bebas pertama dimulai:

Cash:

**Rp 8,430**

Sebagian dari Rp18.430 pada cutscene digunakan secara implisit untuk kebutuhan rumah/transportasi.

Debt:

**Rp 1,800,000**

Upgrade:

semua Lv0.

Bucket:

kosong.

Basic fishing equipment:

gratis/permanen.

Basic bait:

unlimited.

Dengan demikian player tidak pernah dapat kehilangan kemampuan untuk memancing.

---

# 23. FISHING PHASE

## State

`IDLE`

↓ input

`CASTING`

↓

`WAITING`

↓

`BITE_WARNING`

↓

`STRIKE_WINDOW`

↓

`REELING`

↓

`LANDED`

atau

`ESCAPED`

---

# 24. CAST

Input:

PC:

**Space / Left Click**

Mobile:

**CAST**

Durasi animasi:

1.35 detik.

Sequence:

0.00–0.30  
Darto menarik joran ke belakang.

0.30–0.72  
Forward swing.

0.48  
Pelampung dilepas dari ujung joran.

0.72–1.05  
Joran overshoot kecil.

1.05–1.35  
Joran bergetar dan settle.

Setelah pelampung masuk air, joran mengarah ke permukaan danau.

Tidak berdiri vertikal.

---

# 25. WAITING

Base bite interval:

**4.5–9.5 detik**

Dipilih random setiap cast.

Upgrade Super Pellet memodifikasi:

`waitTimeMultiplier = 1 - (0.18 × baitLevel)`

Lv0:

100%

Lv1:

82%

Lv2:

64%

Lv3:

46%

Minimum final wait:

1.75 detik.

Semua upgrade pada game menggunakan sistem **additive terhadap base stat** kecuali disebut sebaliknya.

---

# 26. NIBBLE

Sebelum gigitan asli:

0–2 false nibble.

Nibble:

- pelampung bergerak kecil,
- ripple,
- suara *plip*,
- joran bergerak sedikit.

Tidak memunculkan reaction bar.

Menekan Strike ketika nibble:

tidak dihukum berat.

Darto hanya menarik kosong.

Tambahan delay:

0.8 detik.

Tujuannya menghindari frustration.

---

# 27. REAL BITE

Sebelum bite:

bayangan ikan muncul.

Prompt:

> SOMETHING IS DOWN THERE...

Kemudian:

pelampung tenggelam.

Icon:

`!`

muncul.

Reaction bar aktif.

---

# 28. STRIKE WINDOW BY FISH

| Fish | Strike Window |
|---|---:|
| Bruiser Catfish | 0.79 sec |
| Gym-Rat Tilapia | 0.74 sec |
| Shady Gourami | 0.70 sec |
| Golden Carp | 0.65 sec |
| Snakehead Sergeant | 0.60 sec |
| Don Arowana | 0.55 sec |

Trash encounter:

0.90 detik.

Jika terlambat:

ikan kabur.

Tidak ada duel.

Tidak ada kehilangan item fisik.

Tulisan "bait lost" hanyalah flavor.

Basic bait unlimited.

---

# 29. CATCH ROLL

Setiap successful strike menentukan encounter.

Pertama:

### Trash Roll

16%.

Jika gagal trash roll:

84% menjadi fish pool.

Fish probability di dalam fish pool:

| Fish | Conditional Chance |
|---|---:|
| Bruiser Catfish | 30% |
| Gym-Rat Tilapia | 24% |
| Shady Gourami | 20% |
| Golden Carp | 14% |
| Snakehead Sergeant | 9% |
| Don Arowana | 3% |

Actual cast probability:

| Result | Per Successful Encounter |
|---|---:|
| Trash | 16.00% |
| Bruiser Catfish | 25.20% |
| Gym-Rat Tilapia | 20.16% |
| Shady Gourami | 16.80% |
| Golden Carp | 11.76% |
| Snakehead Sergeant | 7.56% |
| Don Arowana | 2.52% |

---

# 30. TRASH DISTRIBUTION

Di dalam 16% trash pool:

| Trash | Chance | Value |
|---|---:|---:|
| Lost Sandal | 45% | Rp 500 |
| Rusty Tin Can | 40% | Rp 300 |
| Ancient Tyre | 15% | Rp 1,000 |

Trash tidak memicu Wheel atau duel.

Trash langsung masuk Bucket.

---

# 31. REEL SYSTEM

Tension minigame menggunakan nilai normalized:

`0.0–1.0`

Player marker bergerak secara vertikal.

### Hold Reel

Marker velocity:

`+0.72 units/sec`

### Release

Marker velocity:

`-0.58 units/sec`

Input acceleration:

0.12 sec easing.

Tujuannya agar kontrol tidak terlalu twitchy.

---

# 32. GREEN ZONE SIZE

Base half-width:

| Fish | Half Width |
|---|---:|
| Bruiser Catfish | 0.175 |
| Gym-Rat Tilapia | 0.165 |
| Shady Gourami | 0.155 |
| Golden Carp | 0.140 |
| Snakehead Sergeant | 0.125 |
| Don Arowana | 0.110 |

Carbon Rod:

`+0.035 half-width / level`

Final width di-clamp maksimum:

`0.245`

---

# 33. GREEN ZONE MOVEMENT

Green zone memiliki target movement.

Setiap:

0.65–1.40 sec

ikan memilih target posisi baru.

Movement menggunakan spring interpolation, bukan teleport.

Aggression menentukan velocity.

| Fish | Movement Speed |
|---|---:|
| Catfish | 0.36 |
| Tilapia | 0.42 |
| Gourami | 0.48 |
| Carp | 0.54 |
| Snakehead | 0.63 |
| Arowana | 0.72 |

Don Arowana sesekali melakukan feint:

bergerak satu arah lalu berbalik.

---

# 34. LANDING PROGRESS

Range:

0–100.

Saat:

marker berada di green zone **dan player sedang HOLD REEL**:

Landing:

`+18/sec`

Jika indicator di luar green zone tetapi player tetap menggulung:

Landing:

`-3/sec`

Minimum:

0.

Saat player RELEASE:

landing tidak meningkat atau turun.

---

# 35. LINE STRESS

Range:

0–100.

Inside zone:

`-30/sec`

Outside zone + HOLD:

| Fish | Stress/sec |
|---|---:|
| Catfish | 32 |
| Tilapia | 35 |
| Gourami | 39 |
| Carp | 43 |
| Snakehead | 48 |
| Arowana | 54 |

Outside + RELEASE:

`-16/sec`

Stress >= 100:

# LINE BREAK

Ikan kabur.

---

# 36. HUD FEEDBACK

Semakin tinggi stress:

0–40:

stabil.

40–70:

HUD shake ringan.

70–90:

HUD shake sedang.

90–100:

HUD shake kuat + warning pulse.

**Camera tidak shake.**

Joran tetap memberikan animation jerk.

---

# 37. LAND SUCCESS

Landing >= 100:

slowdown 0.25 sec.

Splash besar.

Fish muncul.

Fish introduction sting.

Contoh:

> BRUISER CATFISH  
> "LOCAL TROUBLEMAKER"

Kemudian Wheel of Fate.

---

# 38. WHEEL OF FATE

8 segmen:

- Boxing
- Arm Wrestling
- Dance
- Rock Paper Scissors
- Boxing
- Arm Wrestling
- Dance
- Rock Paper Scissors

Masing-masing:

25%.

Outcome dipilih **sebelum animasi dimulai** menggunakan game RNG.

Wheel kemudian dianimasikan menuju segmen terpilih.

Dengan demikian frame rate tidak dapat memengaruhi hasil.

Duration:

3.1–4.0 sec.

Player boleh skip setelah pertama kali melihat Wheel:

hold input 0.6 sec.

Skip tetap memainkan reveal singkat.

---

# 39. FISH MASTER STATS

| Fish | Tier | Sale | Boxing HP | Attack | Telegraph | Arm Strength | Rhythm Skill | Tell Truth |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Bruiser Catfish | 1 | 18k | 70 | 12 | .82s | 42 | 62 | 78% |
| Gym-Rat Tilapia | 2 | 26k | 90 | 14 | .75s | 50 | 68 | 72% |
| Shady Gourami | 2 | 34k | 105 | 16 | .69s | 56 | 72 | 46% |
| Golden Carp | 3 | 52k | 120 | 18 | .63s | 62 | 78 | 61% |
| Snakehead Sergeant | 4 | 78k | 145 | 22 | .57s | 72 | 84 | 52% |
| Don Arowana | 5 | 240k | 190 | 26 | .51s | 84 | 90 | 34% |

Arm Strength dan Rhythm Skill menggunakan skala 0–100.

---

# 40. DON AROWANA VALUE

Rp 240,000 adalah:

**BASE SALE VALUE.**

Don Arowana selalu memiliki:

### Boss Premium ×1.25

Final sale value:

# Rp 300,000

UI Market:

`Rp 240,000 × BOSS 1.25 = Rp 300,000`

Tidak ambigu.

---

# 41. MODE 1 — TINJU EMPANG

Inspirasi:

Punch-Out style reading + counter.

Player tidak diminta spam attack.

Core pattern:

1. Fish prepares attack.
2. Telegraph.
3. Player reads direction.
4. Dodge.
5. Counter window.
6. Attack.
7. Reset.

---

# 42. BOXING CONTROLS

PC:

A = Dodge Left  
D = Dodge Right  
J = Jab  
K = Cross

Mobile:

DODGE <  
> DODGE  
JAB  
CROSS

---

# 43. PLAYER HP

Base:

100.

Herbal Tonic:

+25 HP / level.

Lv0:

100

Lv1:

125

Lv2:

150

Lv3:

175

---

# 44. PLAYER ATTACK

## Jab

Damage:

11

Startup:

0.11 sec

Recovery:

0.25 sec

## Cross

Damage:

18

Startup:

0.20 sec

Recovery:

0.44 sec

---

# 45. BLOCKED DAMAGE

Jika menyerang tanpa opening:

Fish dapat block.

Damage:

40% normal.

Jab:

4.4

Cross:

7.2

Dibulatkan internal dengan floating point; UI tidak menampilkan angka damage.

---

# 46. DODGE

Setiap fish attack memiliki:

`attackDirection`

LEFT atau RIGHT.

Direction menunjukkan **arah player harus dodge**.

Visual cue:

- body lean,
- sirip,
- arrow-like motion,
- eye flash.

Warna hanya secondary cue.

Informasi tidak bergantung pada merah/hijau.

---

# 47. PERFECT DODGE

180 ms terakhir sebelum impact.

Perfect Dodge:

- short freeze 70 ms,
- sound accent,
- counter window 0.85 sec,
- damage multiplier 2.4x.

Normal Dodge:

counter window:

0.62 sec.

Damage multiplier:

2.0x.

Wrong direction:

player terkena attack.

No input:

player terkena attack.

---

# 48. BOXING TIME LIMIT

60 sec.

Jika salah satu HP <= 0:

langsung selesai.

Jika waktu habis:

bandingkan:

`remainingHP / maxHP`

Yang memiliki persentase lebih tinggi menang.

Exact tie:

sudden-death.

Fish dan player masuk 1-hit round.

Serangan pertama yang berhasil menentukan hasil.

---

# 49. BOXING AI VARIATION

Fish tidak menyerang dalam interval yang identik.

Cooldown:

1.2–2.1 sec.

Don Arowana:

0.95–1.65 sec.

Setiap fish mempunyai 3 animation attack.

Namun rule dodge tetap terbaca.

Tidak boleh ada serangan tanpa telegraph.

---

# 50. MODE 2 — PANCO MAUT

Round:

32 sec.

Position Bar:

`-100 to +100`

-100:

Fish wins.

+100:

Player wins.

Start:

0.

---

# 51. PLAYER STAMINA

Base:

100.

Jamu:

+20% maximum stamina / level.

Lv0:

100

Lv1:

120

Lv2:

140

Lv3:

160

---

# 52. MASH INPUT

Space / MASH.

Setiap accepted press:

base impulse:

4.8.

Stamina cost:

7.

Maximum accepted rate:

10 presses/sec.

Input di atas limit diabaikan.

Ini:

- menjaga accessibility,
- mencegah autoclicker sederhana,
- mencegah player harus melakukan input yang tidak nyaman.

---

# 53. STAMINA EFFECT

Jika stamina > 60%:

100% power.

30–60%:

85% power.

10–30%:

65% power.

0–10%:

42% power.

Stamina 0 tidak mengunci player.

Input masih berfungsi tetapi lemah.

---

# 54. STAMINA RECOVERY

Setelah 0.35 sec tanpa press:

regen:

26 stamina/sec.

---

# 55. FISH ARM FORCE

AI memberikan constant pressure berdasarkan Arm Strength.

Selain itu fish melakukan burst.

Burst telegraph:

fish body tightens + UI pulse.

Duration:

0.65–1.15 sec.

Cooldown:

3.0–5.5 sec.

Semakin tinggi tier:

semakin kuat burst.

---

# 56. ARM WRESTLING TIMEOUT

Jika 32 sec berakhir:

posisi di atas 0:

player menang.

di bawah 0:

fish menang.

Jika posisi berada di:

-2 sampai +2:

# SUDDEN GRIP

Tambahan maksimal 5 sec.

Pertama mencapai magnitude 5 menang.

Jika tetap hampir nol setelah 5 sec:

compare exact value.

Jika tepat 0.000:

coin-free deterministic tiebreak:

player memenangkan ronde tutorial/non-boss.

Boss melakukan rematch round 10 sec.

---

# 57. MODE 3 — JOGET KOPLO

Empat lane:

S D J K.

Mobile:

empat lane touch.

Tidak menggunakan arrow key atau WASD.

---

# 58. MUSIC

Procedural koplo track.

Base BPM dipilih:

132–156 BPM.

Duel duration:

36–44 sec.

Chart dibuat menggunakan deterministic seeded generator.

Seed:

`saveSeed + fishId + duelCounter`

Debugging dapat mereproduksi chart.

---

# 59. NOTE JUDGMENT

PERFECT:

±55 ms.

GREAT:

±100 ms.

GOOD:

±175 ms.

MISS:

>175 ms.

---

# 60. SCORE

PERFECT:

1000.

GREAT:

700.

GOOD:

350.

MISS:

0.

Combo bonus:

setiap 10 combo:

+10%.

Maximum:

+50%.

Formula:

`score × (1 + min(floor(combo/10) × .1, .5))`

Miss:

combo reset.

---

# 61. FISH RHYTHM AI

Fish memakai chart yang sama.

Stat Rhythm menentukan judgment distribution.

Contoh tier rendah:

lebih banyak GOOD/MISS.

Tier tinggi:

lebih banyak PERFECT/GREAT.

AI result dihasilkan note-by-note menggunakan deterministic RNG.

Tidak hanya menghasilkan final random score.

Ini memungkinkan animasi ikan sesuai performanya.

---

# 62. BLACK COFFEE

Coffee tidak mengubah beat.

Coffee hanya mengubah visual note travel speed.

Formula:

`visualSpeed = baseSpeed × (1 - 0.12 × coffeeLevel)`

Lv1:

88%.

Lv2:

76%.

Lv3:

64%.

Karena `targetHitTime` tidak berubah:

semakin lambat speed, semakin awal note harus spawn.

Formula:

`spawnTime = targetHitTime - laneDistance / visualSpeed`

Scoring tidak menggunakan `delta` frame sebagai sumber waktu utama.

Authoritative song clock berasal dari playback position `AudioStreamPlayer` dan timing `AudioServer` agar judgment tetap mengacu pada audio, bukan FPS render.

Implementasi harus menjaga nilai song time tetap monotonic dan menggunakan offset kalibrasi input/audio per platform jika diperlukan.

---

# 63. RHYTHM WIN CONDITION

Setelah final note:

lebih tinggi score menang.

Exact equal score:

lebih banyak PERFECT menang.

Masih sama:

lebih tinggi max combo menang.

Masih sama:

satu four-note encore dimainkan.

---

# 64. MODE 4 — SUWIT

Format:

# FIRST TO TWO WINS

Bukan literal maksimal tiga ronde.

Draw tidak dihitung.

Round draw diulang.

---

# 65. ROUND FLOW

3 sec countdown.

Fish memilih hidden move di awal countdown.

Setelah 1.1 sec:

fish menampilkan tell.

Tell dapat:

jujur atau palsu.

Truth probability mengikuti fish stat.

---

# 66. INPUT

1:

Rock.

2:

Scissors.

3:

Paper.

C:

Agate Charm.

Mobile:

Rock / Scissors / Paper / Charm.

---

# 67. TIMEOUT

Jika player tidak memilih sebelum timer 0:

game otomatis memilih random move.

Text:

> PANIC PICK!

Ini mencegah hard fail karena player terlambat beberapa frame.

---

# 68. AGATE CHARM

Charge per duel:

Lv0:

0

Lv1:

1

Lv2:

2

Lv3:

3

Jika digunakan:

fish actual choice muncul selama:

0.8 sec.

Contoh:

> REAL MOVE: PAPER

Charm tidak mengubah choice ikan.

Hanya memberikan informasi.

Charge reset setiap duel Suwit.

Tidak dapat disimpan antar-duel.

---

# 69. FISH PERSONALITIES

## BRUISER CATFISH

Lele besar.

Kumis tebal.

Sarung tinju merah kusam.

Kepribadian:

preman lokal yang sebenarnya cukup sopan.

Example:

> "Nothing personal, fisherman."

Lose line:

> "Tell the bucket I said no."

---

## GYM-RAT TILAPIA

Nila terlalu berotot.

Headband.

Obsesi protein.

> "DO YOU EVEN REEL?"

> "That rod has terrible form."

---

## SHADY GOURAMI

Kacamata hitam.

Sangat mencurigakan.

Selalu bicara seperti mempunyai bisnis rahasia.

> "You saw nothing."

> "This lake doesn't know me."

Tell di Suwit sangat sering bohong.

---

## GOLDEN CARP

Ikan mas berwarna emas.

Kalung berlebihan.

Sangat sombong.

> "My scales are worth more than your motorcycle."

Darto:

> "That's not a high bar."

---

## SNAKEHEAD SERGEANT

Ikan gabus dengan headband militer.

Terlalu disiplin.

> "FISHERMAN!"

> "YOUR REELING LACKS CONVICTION!"

---

## DON AROWANA

Boss.

Tenang.

Elegan.

Tidak pernah terburu-buru.

Berbicara seperti bos mafia tua.

Tidak memakai terlalu banyak aksesori.

Hanya:

- chain tipis,
- scar,
- dark fin accents.

> "Darto."

Darto:

> "...How do you know my name?"

> "The lake talks."

Darto:

> "That is deeply concerning."

---

# 70. BUCKET SYSTEM

Bucket unlimited.

Tidak ada capacity limit.

Alasan desain:

capacity management akan memaksa player terlalu sering meninggalkan danau dan mengganggu cozy flow.

Isi Bucket disimpan dalam save.

Bucket berisi:

`itemId`

`quantity`

Untuk fish:

jumlah tiap spesies.

Untuk trash:

jumlah tiap jenis.

---

# 71. BUCKET HUD

Fishing HUD menampilkan ikon ember kecil.

Contoh:

`BUCKET 7`

Tidak menunjukkan nilai uang langsung.

Player dapat membuka quick peek:

desktop:

B.

mobile:

tap bucket.

Overlay menunjukkan:

3× Catfish  
1× Carp  
2× Can  
1× Sandal

Estimated sale value boleh ditampilkan.

---

# 72. THE MARKET

The Market merupakan warung terbuka kecil.

Visual:

- meja kayu,
- timbangan,
- freezer tua,
- termos,
- toples,
- kursi plastik,
- lampu gantung,
- papan harga,
- motor Bu Yati,
- kipas kecil.

Tidak menjadi supermarket modern.

---

# 73. MARKET TABS

### SELL

### UPGRADES

### DEBT

### FISH BOOK

### RECORDS

---

# 74. SELL SYSTEM

Button:

# SELL ALL

Default utama.

Player juga dapat menjual per kategori.

Tidak ada alasan gameplay untuk menahan fish kecuali personal preference.

Setelah sale:

bucket quantity berkurang.

Cash bertambah.

Sale receipt menunjukkan breakdown.

---

# 75. SALE VALUE

| Item | Value |
|---|---:|
| Bruiser Catfish | Rp 18,000 |
| Gym-Rat Tilapia | Rp 26,000 |
| Shady Gourami | Rp 34,000 |
| Golden Carp | Rp 52,000 |
| Snakehead Sergeant | Rp 78,000 |
| Don Arowana | Rp 300,000 effective |
| Lost Sandal | Rp 500 |
| Rusty Tin Can | Rp 300 |
| Ancient Tyre | Rp 1,000 |

---

# 76. UPGRADES

## SUPER PELLET BAIT

Wait time:

-18% / level.

Prices:

Lv1 Rp12,000  
Lv2 Rp30,000  
Lv3 Rp68,000

Total:

Rp110,000.

---

## CARBON FIBRE ROD

Green zone half-width:

+0.035 / level.

Store display:

approximately +27% easier targeting per level.

Prices:

18k / 44k / 96k.

---

## HERBAL TONIC

Boxing:

+25 Max HP / level.

Arm Wrestling:

+20% max stamina / level.

Prices:

15k / 38k / 82k.

---

## BLACK COFFEE

Joget note visual speed:

-12% / level.

Prices:

14k / 34k / 74k.

---

## AGATE CHARM RING

Suwit:

+1 reveal charge / duel / level.

Prices:

20k / 50k / 110k.

---

# 77. TOTAL UPGRADE COST

Super Pellet:

110k.

Rod:

158k.

Tonic:

135k.

Coffee:

122k.

Charm:

180k.

# TOTAL: Rp 705,000

Ini sengaja cukup besar dibanding hutang Rp1.8 juta sehingga player harus membuat trade-off.

---

# 78. SHOP INFORMATION RULE

Setiap item wajib menunjukkan:

- current level,
- current effect,
- next effect,
- exact price,
- max level.

Contoh:

> CARBON FIBRE ROD — LV.1  
> Current: +0.035 green-zone width  
> Next: +0.070 total  
> Upgrade: Rp 44,000

Tidak boleh hanya menggunakan deskripsi flavor.

---

# 79. DEBT SCREEN

Header:

# DEBT LEDGER

Original:

Rp1,800,000.

Paid:

RpXXX.

Remaining:

RpXXX.

Progress bar.

Buttons:

PAY 25,000  
PAY 50,000  
PAY 100,000  
PAY CUSTOM  
PAY ALL AVAILABLE

Button disable jika cash tidak cukup.

Tidak ada payment fee.

Tidak ada bunga.

Tidak ada penalty jika tidak membayar.

---

# 80. STORY VS ECONOMY

Narrative milestone hanya menggunakan:

`lifetimeDebtPaid`

Bukan saldo saat ini.

Dengan demikian player tidak kehilangan story progress.

---

# 81. FISH BOOK

Terbuka setelah Nisa meminta melihat ikan.

Setiap fish entry awalnya silhouette.

Setelah pertama kali berhasil dikalahkan:

portrait dan informasi terbuka.

Fields:

Name  
Species Joke  
Best Weight  
Times Encountered  
Times Defeated  
Times Lost  
Favourite Duel  
Description

Weight merupakan kosmetik random.

Tidak memengaruhi sale value.

---

# 82. WEIGHT

Weight range per species digunakan untuk flavor.

Contoh:

Catfish:

1.2–3.8 kg.

Arowana:

4.5–8.0 kg.

Rare:

5% chance mendapatkan `BIG ONE`.

Weight 90th percentile+.

Record tersimpan.

Tidak mengubah ekonomi agar balance sederhana.

---

# 83. RECORDS SCREEN

Stats:

Total Casts  
Successful Strikes  
Lines Broken  
Trash Caught  
Fish Landed  
Duels Won  
Duels Lost  
Boxing Wins  
Arm Wrestling Wins  
Dance Wins  
Suwit Wins  
Don Arowana Defeated  
Largest Fish  
Lifetime Fish Sales  
Lifetime Debt Paid  
Total Play Time

---

# 84. MAIN MENU

Visual:

Danau Cempaka.

Darto duduk kecil di pinggir frame.

Motor berada sedikit jauh.

Camera static.

Daun bergerak.

Menu:

CONTINUE  
NEW GAME  
HOW TO PLAY  
SETTINGS  
CREDITS

Jika save tidak ada:

CONTINUE disabled.

---

# 85. NEW GAME CONFIRMATION

Jika save ada:

> Starting a new game will replace the current save.

Dua langkah konfirmasi.

Tidak membuat player kehilangan save hanya dengan satu click.

---

# 86. RESET SAVE

Settings:

RESET SAVE.

Confirmation 1:

> Reset all progress?

Confirmation 2:

> This cannot be undone. Really reset?

---

# 87. HOW TO PLAY

Bukan wall of text.

Tab:

Fishing  
Boxing  
Arm Wrestling  
Dance  
Suwit  
Market

Setiap tab menggunakan diagram sederhana dan input icons.

---

# 88. RESULT SCREEN

## WIN

Fish animation:

KO / exhausted / embarrassed tergantung duel.

Text:

> YOU WIN

> BRUISER CATFISH ADDED TO BUCKET

Button:

CONTINUE.

Auto continue setelah 5 sec jika tidak ada input.

---

## LOSS

Fish bangun dan mengejek.

Text:

> THE FISH GOT AWAY

Fish melompat kembali.

Button:

CONTINUE.

Tidak ada kehilangan uang.

Tidak ada punishment tambahan.

---

# 89. SCENE FLOW

Boot

↓

MainMenu

↓

Story/Prologue if required

↓

Fishing

├── Market

│   ├── Sell

│   ├── Upgrade

│   ├── Debt

│   ├── FishBook

│   └── Records

↓

Fish landed

↓

Wheel

↓

Duel Scene

↓

Result

↓

Fishing

Narrative scenes dipasang sebagai overlay/interstitial berdasarkan milestone.

---

# 90. PAUSE

ESC / pause button.

Pause screen:

RESUME  
CONTROLS  
MUSIC [ON/OFF]  
SOUND [ON/OFF]  
SETTINGS  
QUIT TO MENU

Gameplay simulation berhenti.

Audio music pause.

SFX active hanya untuk UI pause.

---

# 91. CONTROL SETTINGS

Desktop input defaults:

Fishing:

Space / Click.

Market:

E.

Bucket:

B.

Pause:

Esc.

Boxing:

A D J K.

Panco:

Space.

Dance:

S D J K.

Suwit:

1 2 3 C.

---

# 92. MOBILE CONTROL PRINCIPLES

Android native menggunakan **portrait orientation** sebagai layout utama.

Web build di itch.io menggunakan layout landscape responsif sebagai default, tetapi seluruh UI wajib tetap mampu beradaptasi saat viewport menjadi sempit.

Minimum interactive target:

48 logical pixels.

Preferred:

56–72 logical pixels.

Semua `Control` memakai anchor, container, dan theme sizing Godot; posisi tombol penting tidak boleh ditulis sebagai koordinat layar absolut.

Android harus menghormati safe area perangkat, cutout/notch, serta area gesture/navigation menggunakan informasi safe area dari `DisplayServer`.

Untuk Web, UI juga harus memberi margin aman agar tidak terasa menempel pada tepi viewport atau browser chrome.

Input parity wajib:

- keyboard + mouse pada Web/Desktop,
- touchscreen pada Android,
- mouse/touch hybrid tetap diperbolehkan bila perangkat mendukung.

---
# 93. MOBILE FISHING LAYOUT

Top:

money + bucket.

Center:

3D lake.

Right side:

Tension Bar.

Bottom center:

large contextual button:

CAST

→ STRIKE

→ HOLD REEL.

Bottom-left:

MARKET.

Pause:

top-right.

---

# 94. MOBILE BOXING

Upper 62%:

fight viewport.

Bottom 38%:

four controls.

Left:

DODGE <

> DODGE.

Right:

JAB

CROSS.

Controls tidak overlap fight HUD.

---

# 95. MOBILE PANCO

Character viewport:

top 60%.

Bars:

middle.

Large:

MASH!

bottom 30%.

---

# 96. MOBILE DANCE

Four lanes menggunakan hampir seluruh vertical viewport.

Hit line:

sekitar 72% screen height.

Touch zones:

bottom.

Setiap lane memiliki:

- symbol,
- shape,
- label.

Tidak hanya warna.

---

# 97. MOBILE SUWIT

Top:

fish.

Middle:

countdown + tell.

Bottom:

ROCK / SCISSORS / PAPER.

Charm:

small secondary button di atas choice row.

---

# 98. ACCESSIBILITY

## COLOR

Tidak ada critical gameplay information yang hanya menggunakan warna.

## CAMERA SHAKE

Option:

HUD SHAKE:

ON / REDUCED / OFF.

Default:

ON.

## FLASH

Reduce Flash option.

## AUDIO

Music dan SFX terpisah.

## RHYTHM

Visual beat pulse tetap tersedia jika audio kecil.

## FONT

Minimum UI body:

16 logical pixels equivalent pada reference resolution, dengan scaling melalui Godot Theme.

---

# 99. ART DIRECTION

## STYLE

Visual utama adalah **stylized 3D low-poly modern**.

Low-poly di sini berarti bentuk disederhanakan secara sengaja, bukan grafis retro dan bukan simulasi keterbatasan konsol lama.

Target visual:

- silhouette karakter dan ikan mudah dikenali,
- prop mempunyai bentuk dan detail yang cukup untuk dibaca dari dekat,
- edge dan plane tetap terlihat artistik,
- material sederhana tetapi tidak terlihat kosong,
- lighting lembut dan hangat,
- environment mempunyai depth yang cukup,
- komposisi tetap bersih dan tidak terlalu ramai.

Yang **tidak digunakan**:

- vertex wobble,
- affine texture warping,
- pixelated internal resolution sebagai gaya wajib,
- dithering retro yang berat,
- texture jitter,
- deliberate low frame-rate animation,
- imitasi PS1/PS2/N64.

Low-poly harus terasa sebagai **pilihan seni modern**, bukan keterbatasan teknis.

---

# 100. LOW-POLY DETAIL LANGUAGE

Detail tidak ditambahkan dengan membuat semua mesh sangat padat.

Prioritas detail:

1. silhouette,
2. proporsi,
3. layer pakaian/aksesori,
4. bentuk wajah sederhana,
5. material separation,
6. vertex color/albedo variation,
7. selected texture detail,
8. environmental dressing.

Contoh Darto:

kaus bukan hanya satu kubus; harus mempunyai bahu, lipatan bentuk besar, kerah, lengan, serta separation yang jelas dengan tubuh.

Contoh ikan:

sirip, mulut, insang, mata, ekor, bentuk tubuh, dan aksesori karakter harus terbaca jelas.

Contoh motor:

ban, velg, lampu, tangki, jok, knalpot, mesin, suspensi, stang, spion, dan panel utama harus terbaca, tetapi baut kecil tidak perlu dimodel satu per satu.

Filosofi:

> **Enough detail to feel intentional; few enough polygons to keep the shape charming and performant.**

---

# 101. GEOMETRY & SCENE BUDGET

Budget merupakan guideline awal untuk target Web + Android dan harus divalidasi dengan profiler.

### Hero Characters

Darto:

8,000–14,000 triangles.

Rini / Nisa / Bu Yati:

6,000–12,000 triangles.

### Fish

Regular fish:

3,000–6,000 triangles.

Don Arowana:

5,000–8,000 triangles.

### Motorcycle

8,000–14,000 triangles.

### Props

Small prop:

50–800 triangles.

Medium prop:

500–3,000 triangles.

Hero prop:

2,000–8,000 triangles.

### Visible Environment

Preferred:

120,000–220,000 visible triangles.

Soft upper guideline:

300,000 visible triangles.

Jumlah draw call, material switch, transparency, shadow caster, dan overdraw dianggap sama pentingnya dengan jumlah triangle.

Repeated vegetation seperti grass, reeds, stone, dan small foliage harus memakai instancing / `MultiMeshInstance3D` jika jumlahnya besar.

LOD atau manual distance culling digunakan pada objek yang cukup jauh untuk membutuhkannya.

---

# 102. PROGRAMMATIC ASSET & MATERIAL PIPELINE

Section ini menggantikan pipeline imported-DCC lama. Production v1.0 memakai **zero-internet-asset pipeline** sesuai Section 184.

Semua visual production asset dibuat dari source project sendiri melalui Typed `@tool` GDScript dan Godot native resource/mesh APIs. Tidak ada download model, texture, UI icon, font, animation, atau stock visual dari internet.

Pipeline resmi:

**GDScript generator source → Godot native mesh/material/image/animation resources → generated `.tscn` / `.tres` / project-created images → runtime load**

Full generator contract, deterministic seed, validation, generated-output rules, dan prohibited asset list mengikuti Section 184.

Material utama:

`StandardMaterial3D` + project-authored shader bila benar-benar dibutuhkan.

Guideline:

- geometry + color blocking adalah sumber detail utama;
- 1–3 material slot per hero;
- vertex color diprioritaskan bila efektif;
- generated texture 256–1024 px untuk mayoritas runtime use;
- 2048 px hanya jika justified;
- no 4K runtime dependency;
- transparency dibatasi;
- material reuse wajib;
- no external PBR/material library;
- Godot built-in default font adalah baseline font v1.0.

Generated asset bukan placeholder. Hero object tetap harus memenuhi art direction, silhouette, geometry budget, dan reference lock Sections 99–101 serta 185.

---

# 103. LIGHTING & COLOR PALETTE

Dominant palette:

- warm grass green,
- muted lake blue-green,
- sunset cream,
- terracotta,
- faded red,
- warm yellow,
- wood brown,
- soft sky blue.

Shadow tidak menggunakan pure black.

Lighting baseline:

- satu `DirectionalLight3D` sebagai matahari,
- environment ambient light yang hangat,
- local light hanya pada lokasi yang benar-benar membutuhkan,
- shadow distance dibatasi,
- jumlah shadow-casting light minimal.

Target utama bukan photorealism.

Material dapat memiliki roughness dan subtle specular response agar objek mempunyai depth, tetapi tidak boleh berubah menjadi realistic PBR showcase.

Baked AO ke texture/vertex color dapat digunakan untuk memberi kedalaman ringan pada asset.

Post-processing harus ringan dan diuji pada Compatibility renderer.

---

# 104. COMPOSITION

Jangan memenuhi setiap pixel.

Setiap shot harus punya ruang kosong.

Motor Darto:

bagian environment.

Bukan hero prop pada seluruh gameplay.

Warung:

sederhana tetapi cukup detail untuk terasa digunakan sehari-hari.

Background:

tidak penuh NPC.

Vegetasi ditempatkan dalam cluster dan negative space, bukan menyebar merata.

Game harus terlihat handcrafted, bukan procedural clutter.

---

# 105. MOTOR

Motor Darto tua tetapi masih layak dan terawat secara wajar.

Fungsi:

- visual continuity,
- simbol kehidupan Darto,
- establishing shot,
- background prop di danau.

Tidak ada brand/logo nyata.

Tidak menjadi vehicle gameplay.

Model tetap low-poly namun harus mempunyai detail bentuk yang cukup untuk dikenali sebagai motor tua yang realistis secara proporsi.

---

# 106. CHARACTER ANIMATION

Animasi tidak meniru frame-rate retro.

Animation playback harus terasa halus pada 30/60 FPS.

Gaya gerak tetap stylized:

- pose kuat,
- timing komedi jelas,
- anticipation,
- overshoot ringan,
- exaggeration pada ikan,
- reaction pause untuk punchline.

Godot `AnimationPlayer` dan `AnimationTree` digunakan untuk karakter yang membutuhkan blend/state transition.

Beberapa gerakan dapat deliberately stepped hanya jika digunakan sebagai punchline spesifik, bukan sebagai style global.

Camera movement tetap lembut dan stabil.

---

# 107. AUDIO DIRECTION

Audio v1.0 adalah **100% code-generated/procedural**.

Tidak menggunakan imported `.ogg`, `.wav`, `.mp3`, `.flac`, `.aac`, atau `.m4a`.

Komponen utama:

- `AudioStreamGenerator`,
- `AudioStreamGeneratorPlayback`,
- programmatically created in-memory PCM/`AudioStreamWAV` untuk short generated SFX bila berguna,
- `AudioServer` buses,
- deterministic procedural sequencer,
- synthesis presets berupa numeric data/`.tres`, bukan media audio.

Bus minimal:

- Master,
- Music,
- SFX,
- Ambience,
- UI.

Music dan SFX mempunyai volume/toggle terpisah.

Rhythm gameplay wajib menggunakan authoritative audio clock, bukan frame delta.

Tidak ada voice acting pada v1.0; dialogue disampaikan melalui text/subtitle.

Spesifikasi lengkap authoritative terdapat pada **Section 175 — Procedural Audio Direction**.

---
# 108. LAKE AMBIENCE

Layers:

water noise.

wind.

birds.

distant motor.

insects.

occasional human ambience.

very distant dangdut.

Tidak semua layer aktif terus-menerus.

Random scheduler mencegah loop terasa pendek.

---

# 109. AMBIENT EVENTS

Setiap 15–35 detik saat waiting:

maximum satu ambient event.

Pool:

- dragonfly lands on float,
- flock of birds,
- distant motorcycle,
- wedding light sweep,
- cooking smoke,
- wind through grass,
- frog,
- plastic bag rolling,
- distant "test... one two..." microphone,
- radio interference,
- small fish jumping far away.

Event tidak boleh mengganggu strike indicator.

---

# 110. MUSIC

Fishing:

minimal.

Kadang hampir tidak ada musik.

Warm guitar-like synthesized plucks.

Soft keys.

Duel:

lebih keras.

Boxing:

retro arcade percussion.

Panco:

comedic heroic beat.

Dance:

koplo.

Suwit:

suspense parody.

Market:

radio-warung feeling.

Narrative:

sparse.

---

# 111. AUDIO PRIORITY

Bite cue tidak pernah ditutupi ambience.

Priority:

1. Gameplay critical.
2. UI.
3. Duel music.
4. Ambience.
5. Decorative event.

---

# 112. HUMOR RULES

Humor harus:

- deadpan,
- absurd,
- character-driven,
- tidak memaksa meme internet,
- tidak terlalu banyak dialog.

Hindari:

- setiap baris harus punchline,
- terlalu banyak referensi tren,
- joke yang cepat basi,
- ikan berbicara nonstop.

Silence juga bagian humor.

---

# 113. GAMBLING THEME RULE

Game tidak menampilkan aktivitas judi sebagai sesuatu yang menyenangkan.

Tidak ada gameplay judi uang.

Tidak ada mechanic:

- bet,
- double-or-nothing,
- slot,
- loot box.

Masa lalu Darto digunakan sebagai konteks cerita mengenai konsekuensi dan pemulihan.

Wheel of Fate:

tidak menggunakan uang.

Tidak menawarkan hadiah random ekonomi.

Hanya memilih minigame secara random.

---

# 114. DIALOGUE STYLE

Semua dialog in-game dalam English.

Bahasa sederhana.

Karakter Indonesia tetap terasa melalui konteks, environment, makanan, kebiasaan, dan rhythm percakapan.

Tidak perlu membuat semua karakter menggunakan broken English.

Example:

Rini:

> "Did you make anything today?"

Darto:

> "Three fish."

> "And a sandal."

Rini:

> "How much was the sandal?"

Darto:

> "Five hundred."

Rini:

> "Good sandal."

---

# 115. SAVE DATA

Save utama:

`user://save_v5.json`

Format:

JSON versioned schema.

Alasan menggunakan `user://`:

Godot menyediakan path writable lintas platform.

Pada Android, save berada di app user data.

Pada Web export, `user://` menggunakan storage browser yang dikelola platform Web; player harus diberi catatan bahwa membersihkan site data/browser storage dapat menghapus save.

Save write menggunakan temporary file + replace strategy bila platform memungkinkan agar risiko corrupt lebih kecil.

---

# 116. SAVE SCHEMA

> **SAVE SCHEMA NOTE:** Bagian ini adalah overview konseptual. Exact authoritative save schema v5 terdapat pada Section 171.

Conceptual:

```text
version
created_at
last_played_at

cash

debt:
    original
    paid
    remaining

upgrades:
    bait
    rod
    tonic
    coffee
    charm

bucket:
    catfish
    tilapia
    gourami
    carp
    snakehead
    arowana
    sandal
    can
    tyre

fish_book:
    discovered
    best_weight
    encounters
    wins
    losses

stats:
    total_casts
    successful_strikes
    failed_strikes
    lines_broken
    trash_caught
    fish_landed
    duel_wins
    duel_losses
    mode_wins
    lifetime_sales
    lifetime_debt_paid
    play_time

story:
    chapter
    seen_events
    ending_completed

settings:
    music_volume
    sfx_volume
    ambience_volume
    hud_shake
    reduced_flash
    master_volume

system:
    save_version
    engine_version
```

---

# 117. SAVE MIGRATION

> **SAVE SCHEMA NOTE:** Migration target resmi tetap schema v5 pada Section 171; document version v6 tidak memerlukan schema bump karena Sections 192–197 tidak menambah persisted gameplay field.

Schema version:

`5`.

Setiap load harus:

1. parse JSON,
2. validate tipe data,
3. clamp angka yang berada di luar range,
4. membaca `version`,
5. menjalankan migration berurutan jika save lama didukung,
6. membuat backup sebelum migration,
7. menulis ulang ke schema terbaru setelah sukses.

Corrupt save tidak boleh langsung ditimpa.

Backup:

`user://save_v5_corrupt_backup.json`

Jika save tidak dapat dipulihkan:

game menawarkan:

- TRY AGAIN,
- START NEW GAME.

Web build dapat memiliki fitur optional:

**EXPORT SAVE / IMPORT SAVE**

untuk membuat backup manual JSON bagi player itch.io.

---

# 118. AUTOSAVE

Autosave ketika:

- duel selesai,
- item dijual,
- upgrade dibeli,
- debt dibayar,
- story milestone selesai,
- settings berubah,
- player kembali ke Main Menu.

Tidak save setiap frame.

Autosave tidak boleh memunculkan freeze yang terasa.

Save icon kecil boleh muncul selama <1 sec.

---

# 119. GODOT TECHNICAL ARCHITECTURE

Engine baseline:

**Godot Engine 4.7 atau stable release yang lebih baru.**

Jika project dimulai saat versi stable >4.7 tersedia, project boleh memakai versi stable terbaru setelah regression test Web + Android.

Primary language:

**Typed GDScript.**

Alasan:

- satu codebase untuk Android dan Web,
- integrasi paling langsung dengan Godot,
- tooling/editor native,
- menghindari dependency runtime eksternal,
- mempermudah build automation.

Project menggunakan **Compatibility renderer** sebagai rendering baseline resmi karena Web export Godot menggunakan renderer tersebut.

Android v1.0 juga menggunakan Compatibility renderer agar:

- visual parity lebih tinggi,
- shader/material behavior seragam,
- debugging lintas platform lebih sederhana.

Migration Android ke Mobile renderer di masa depan hanya boleh dilakukan jika semua scene, material, shader, dan performance test mempunyai hasil ekuivalen.

---

## 119.1 PROJECT STRUCTURE

```text
res://
  autoload/
    game_state.gd
    save_manager.gd
    scene_router.gd
    audio_manager.gd
    input_manager.gd
    platform_service.gd
    rng_service.gd
    story_director.gd
    debug_service.gd

  data/
    fish/
    upgrades/
    dialogue/
    story/
    balance/
    audio/
    visual/

  scenes/
    boot/
    menu/
    story/
    fishing/
    market/
    wheel/
    boxing/
    arm_wrestle/
    dance/
    suwit/
    result/
    ui/

  scripts/
    gameplay/
    actors/
    ui/
    audio/
    accessibility/
    utilities/

  tools/
    generators/
    validation/

  generated/
    models/
    scenes/
    materials/
    textures/
    ui/
    references/
    manifests/

  shaders/
  tests/
  release/
```

Tidak ada folder production asset yang mengandalkan file internet/asset-store. Folder `generated/` berisi output yang dapat direproduksi dari generator repository sesuai Section 184.

Folder names menggunakan lowercase `snake_case`.

---

## 119.2 DATA-DRIVEN DESIGN

Balance tidak boleh tersebar sebagai magic number di berbagai script.

Gunakan Godot custom `Resource` / `.tres` untuk:

- `FishData`,
- `UpgradeData`,
- `DuelConfig`,
- `FishingBalance`,
- `StoryEvent`,
- `DialogueSequence`.

Contoh data ikan memuat:

```text
id
display_name
tier
sale_value
strike_window
reel_zone_width
reel_move_speed
boxing_hp
boxing_attack
boxing_telegraph
arm_strength
rhythm_skill
tell_truth_probability
weight_range
```

Semua display string yang tampil di game menggunakan English.

---

# 120. AUTOLOAD SERVICES & GAME CLOCK

Autoload minimal:

### `GameState`

Source of truth untuk runtime progression.

### `SaveManager`

Load, save, migration, validation.

### `SceneRouter`

Perpindahan scene dan transition.

### `AudioManager`

Bus volume, music state, ambience, crossfade.

### `InputManager`

Input abstraction dan input-device changes.

### `PlatformService`

Mendeteksi Web/Android, safe area, viewport class, platform-specific behavior.

### `RNGService`

Seeded deterministic RNG untuk gameplay.

Gameplay simulation menggunakan `_process(delta)` atau `_physics_process(delta)` sesuai kebutuhan, tetapi timer gameplay tidak boleh bergantung pada frame count.

Rhythm mode menggunakan clock audio khusus.

---

# 121. PAUSE CONTRACT

Godot SceneTree pause digunakan sebagai mekanisme utama.

Saat pause:

- gameplay nodes berhenti,
- fishing state freeze,
- duel timer freeze,
- character gameplay animation freeze,
- music mengikuti aturan pause,
- Pause UI tetap process ketika tree paused.

Pause overlay menggunakan node process mode yang tetap aktif saat pause.

UI sound tetap boleh dimainkan.

Tidak ada countdown yang tetap berjalan di background.

---

# 122. VIEWPORT, RESOLUTION & RESPONSIVE UI

Reference desktop/web resolution:

**1280 × 720 (16:9 landscape).**

Reference Android resolution:

**720 × 1280 (9:16 portrait).**

Rendering dan UI harus mendukung resolusi lain.

Godot Project Settings menggunakan stretch configuration yang menjaga UI scale konsisten.

Semua UI:

- `Control` based,
- memakai anchors,
- memakai `MarginContainer`, `VBoxContainer`, `HBoxContainer`, `GridContainer` bila sesuai,
- tidak bergantung pada hard-coded absolute screen coordinate.

Responsive mode ditentukan dari:

- viewport aspect ratio,
- platform,
- active input device.

Tidak menggunakan browser user-agent sebagai satu-satunya sumber keputusan.

---

# 123. PLATFORM & INPUT DETECTION

Platform branching menggunakan API Godot seperti:

- `OS.has_feature("web")`,
- `OS.has_feature("android")`,
- `DisplayServer`,
- current input events.

Input actions didefinisikan melalui Godot `InputMap`.

Contoh:

```text
ui_confirm
ui_cancel
pause
fish_cast
fish_reel
open_market
open_bucket
box_dodge_left
box_dodge_right
box_jab
box_cross
arm_mash
dance_lane_1
dance_lane_2
dance_lane_3
dance_lane_4
suwit_rock
suwit_scissors
suwit_paper
suwit_charm
```

Gameplay code membaca action, bukan keycode langsung.

Touch button memanggil action yang sama dengan keyboard/mouse.

---

# 124. PERFORMANCE TARGET

### Web / itch.io Desktop

Target:

60 FPS pada modern integrated GPU.

Minimum acceptable:

30 FPS stable.

### Android

Target:

60 FPS pada mid-range modern device.

Minimum acceptable:

30 FPS stable tanpa thermal/performance collapse selama sesi 20–30 menit.

Performance test wajib mencakup:

- Fishing lake,
- Market,
- semua duel,
- worst-case particles,
- viewport portrait,
- Web browser tab after long session.

Tidak boleh mengorbankan readability hanya untuk mengejar 60 FPS; gunakan scalable setting terlebih dahulu.

---

# 125. GRAPHICS QUALITY & RENDER SCALE

Quality presets:

### LOW

- reduced shadow distance,
- reduced vegetation density,
- reduced particles,
- lower internal scale jika diperlukan,
- simplified water.

### MEDIUM

Default Android.

### HIGH

Default Web/Desktop bila device mampu.

Karena Compatibility renderer merupakan baseline, semua preset harus tetap memakai feature set yang tersedia di target Web.

Dynamic resolution bukan requirement v1.0.

Resolution scale option boleh ditambahkan jika profiling menunjukkan kebutuhan.

---

# 126. SHADOW, WATER & ENVIRONMENT

Shadow:

- satu sun directional shadow sebagai default,
- shadow distance konservatif,
- small props tidak wajib cast shadow,
- vegetation shadow dipilih selektif.

Water:

stylized low-poly water surface.

Water dapat menggunakan:

- simple vertex movement,
- normal/albedo variation,
- shoreline ripple mesh/particle.

Hindari shader berat yang hanya bekerja pada renderer tertentu.

Reflection real-time bukan requirement.

Environment depth dibuat melalui:

- lighting,
- fog/depth cue bila kompatibel dan performant,
- overlapping low-poly foliage,
- color/value separation,
- carefully placed props.

---

# 127. MEMORY & RESOURCE MANAGEMENT

Resource reuse wajib.

Guideline:

- preload/shared resources untuk config yang sering dipakai,
- material reuse,
- texture atlas untuk prop kecil,
- `MultiMeshInstance3D` untuk repeated meshes,
- object pooling untuk particle/debris yang sangat sering dibuat,
- scene unload harus melepas reference yang tidak dibutuhkan,
- hindari load besar tepat ketika duel dimulai.

Gunakan `ResourceLoader`/preload strategy yang terkontrol.

Scene penting dapat di-preload saat Fishing idle jika profiling menunjukkan transition hitch.

Web memory usage harus dipantau secara khusus karena browser mempunyai batas lebih ketat dibanding native Android.

---

# 128. GAME STATE

Autoload:

`GameState`.

Tidak mengandalkan scene-local variable untuk data permanen.

Minimal:

```text
cash
debt
bucket
upgrades
stats
story
settings
current_fish
current_duel
session_seed
```

Scene menerima context dari `GameState`/`SceneRouter`, lalu menulis hasil kembali melalui API yang jelas.

UI tidak boleh mengubah save dictionary secara langsung.

---

# 129. RNG

Gunakan centralized seeded RNG melalui `RandomNumberGenerator`.

Gameplay seeded RNG untuk:

- fish roll,
- trash subtype,
- Wheel result,
- fish weight,
- rhythm chart generation,
- duel AI random decisions.

Visual-only effects boleh menggunakan RNG non-deterministic terpisah.

Debug build harus mampu mencetak:

- session seed,
- encounter seed,
- fish roll,
- Wheel result.

Hal ini memungkinkan bug direproduksi.

---

# 130. GODOT SCENES

Scene file utama:

```text
Boot.tscn
MainMenu.tscn
Story.tscn
Fishing.tscn
Market.tscn
Wheel.tscn
Boxing.tscn
ArmWrestle.tscn
Dance.tscn
Suwit.tscn
Result.tscn
PauseOverlay.tscn
HowTo.tscn
Credits.tscn
```

World set 3D dapat menjadi nested scene:

```text
LakeSet.tscn
MarketSet.tscn
BoxingSet.tscn
ArmWrestleSet.tscn
DanceSet.tscn
SuwitSet.tscn
HomeSet.tscn
```

Gunakan scene composition Godot daripada satu scene raksasa.

---

# 131. NODE & 3D SET CONVENTIONS

World root:

`Node3D`.

UI root:

`Control`.

Character root:

`CharacterBody3D` hanya jika benar-benar membutuhkan locomotion/collision berbasis karakter; karakter statis/cinematic dapat memakai `Node3D`.

Camera:

`Camera3D`.

Animation:

`AnimationPlayer` / `AnimationTree`.

Repeated environmental mesh:

`MultiMeshInstance3D`.

Particles:

`GPUParticles3D` jika feature/performance sesuai Compatibility renderer; fallback sederhana wajib tersedia jika efek tertentu terlalu mahal di Web.

Naming:

PascalCase untuk scene/node penting.

snake_case untuk file dan GDScript identifiers.

---

# 132. CUTSCENE SYSTEM

Cutscene memakai timeline data-driven yang dijalankan oleh Godot.

Action contoh:

```text
camera_cut
camera_tween
wait
actor_animation
actor_look_at
dialogue
sfx
music
fade
phone_notification
set_flag
```

Cutscene actor reference menggunakan stable node path/tag, bukan pencarian string bebas setiap frame.

Tween dapat menggunakan Godot `Tween`.

Story event disimpan sebagai resource/data sehingga dialog tidak hardcoded seluruhnya dalam scene script.

---

# 133. DIALOGUE & LANGUAGE DATA

**Seluruh teks yang pernah dilihat player harus berbahasa Inggris.**

Termasuk:

- Main Menu,
- Settings,
- How To Play,
- tutorial prompt,
- HUD,
- Market,
- Fish Book,
- Records,
- debt screen,
- subtitles,
- notification,
- dialogue,
- result screen,
- credits headings,
- error message yang dibuat game.

Nama proper seperti:

- Darto,
- Rini,
- Nisa,
- Bu Yati,
- Danau Cempaka,

tetap dipertahankan sebagai nama Indonesia.

Source copy disimpan secara centralized, misalnya melalui dialogue resources/CSV/JSON internal, walaupun release v1.0 hanya mempunyai bahasa Inggris.

Tujuan sentralisasi:

- consistency,
- typo checking,
- future localization,
- memisahkan copy dari gameplay code.

Tidak boleh ada visible Indonesian placeholder yang tertinggal di release build.

---

# 134. STORY SKIP

Cutscene yang sudah pernah dilihat:

hold confirm/cancel sesuai UI selama 0.8 sec:

**SKIP**

Cutscene pertama kali juga boleh dilewati.

Saat skip:

- story flag tetap diset benar,
- reward/state change tetap dieksekusi,
- scene berakhir pada state deterministik,
- tidak boleh melewati payment/reward logic yang diperlukan.

Game tidak memaksa replay cutscene setelah loss.

---

# 135. BUILD & DISTRIBUTION PIPELINE

## GODOT VERSION POLICY

Project minimum:

**Godot 4.7.**

Boleh upgrade ke versi stable lebih baru.

Tidak memakai nightly/dev build untuk release production kecuali ada blocker kritis dan keputusan tersebut didokumentasikan.

Setiap engine upgrade wajib menjalankan full regression test pada Android + Web.

---

## WEB / ITCH.IO

Export preset:

**Web**

Renderer:

**Compatibility**

Output utama:

`build/web/index.html`

Semua file hasil export Godot Web dimasukkan ke ZIP dengan `index.html` berada di root archive.

Upload itch.io:

- project type: HTML,
- "This file will be played in the browser",
- enable fullscreen button,
- recommended viewport 1280×720,
- responsive sizing diperbolehkan.

Web build menggunakan WebAssembly/WebGL 2 melalui Godot Web export.

Default release menghindari dependency terhadap multithreaded Web build jika hosting headers/cross-origin isolation belum diverifikasi.

Keyboard input harus mencegah browser action yang mengganggu gameplay melalui behavior Web export/UI design yang sesuai.

---

## ANDROID / GOOGLE PLAY STORE

Export preset:

**Android**

Release output:

`build/android/MancingManiaGelut.aab`

Google Play release wajib:

- menggunakan release keystore,
- tidak memakai debug signing,
- menggunakan Android App Bundle,
- mempunyai adaptive launcher icon,
- mempunyai version code/version name yang dinaikkan tiap release,
- memenuhi target API level yang diwajibkan Google Play pada saat submission,
- menggunakan 64-bit ARM build (`arm64-v8a`) sebagai architecture utama,
- permission seminimal mungkin.

Game tidak membutuhkan:

- contacts,
- location,
- microphone,
- camera,
- SMS,
- storage permission luas,

kecuali fitur masa depan benar-benar membutuhkannya dan GDD direvisi.

Orientation Android:

**Portrait.**

Back gesture/button:

- saat gameplay → membuka pause/confirmation,
- saat menu child → kembali satu level,
- tidak langsung menutup game tanpa konteks.

---

## EXPORT AUTOMATION

CLI export dapat digunakan untuk CI:

```text
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-release "Android" build/android/MancingManiaGelut.aab
```

Nama executable Godot pada environment CI dapat berbeda.

Release pipeline selalu menggunakan export templates yang sesuai dengan versi engine project.

---

# 136. QA & AUTOMATED VALIDATION

Tidak menggunakan `npm` test pipeline.

Gunakan Godot headless test runner internal/custom.

Contoh:

```text
godot --headless --path . --script res://tests/run_all.gd
```

Automated validation minimal:

### Save

- fresh save,
- valid load,
- corrupt save,
- migration,
- autosave,
- debt never negative.

### Economy

- fish price,
- boss multiplier,
- upgrade price,
- upgrade max level,
- sell-all math.

### RNG

Simulasi minimal:

100,000 encounter.

Distribution tolerance ditentukan per test.

### Gameplay Config

- strike window,
- fish stat completeness,
- all duel configs load,
- all story flags valid.

### UI

Dedicated debug scenes untuk:

- 1280×720,
- 1920×1080,
- 720×1280,
- 1080×2400,
- common Android notched safe areas.

### Export Smoke Test

Wajib dilakukan pada build hasil export, bukan hanya Editor:

1. launch,
2. New Game,
3. first fishing tutorial,
4. first duel,
5. Market,
6. sell,
7. debt payment,
8. save,
9. close/reopen,
10. continue.

Android test minimal dilakukan pada:

- satu low/mid-range physical Android,
- satu modern Android,
- emulator hanya sebagai tambahan.

Web test minimal:

- Chromium-based browser,
- Firefox,
- Safari/WebKit bila tersedia untuk compatibility check.

---
# 137. ACCEPTANCE CRITERIA — FISHING

Fishing dianggap benar jika:

- float berasal dari rod tip,
- rod forward setelah cast,
- strike windows sesuai config,
- trash tidak memicu Wheel,
- stress break mengembalikan player ke Fishing,
- camera tidak shake,
- HUD shake dapat dimatikan,
- Carbon Rod memperlebar zone,
- Bait memperpendek wait.

---

# 138. ACCEPTANCE CRITERIA — BOXING

- attack selalu telegraph,
- correct dodge membuka counter,
- wrong dodge terkena hit,
- HP upgrade berfungsi,
- mobile controls parity,
- timeout deterministic.

---

# 139. ACCEPTANCE CRITERIA — PANCO

- mash menghabiskan stamina,
- resting mengembalikan stamina,
- low stamina mengurangi force,
- Jamu meningkatkan maximum stamina,
- round 32 sec,
- timeout rule valid.

---

# 140. ACCEPTANCE CRITERIA — DANCE

- note target tetap sinkron dengan authoritative Godot audio clock,
- Coffee tidak menggeser beat,
- scoring sesuai timing,
- fish score direproduksi dengan seed,
- input Web tidak memicu browser behavior yang mengganggu gameplay,
- touch Android memakai action mapping yang sama dengan gameplay logic.

---

# 141. ACCEPTANCE CRITERIA — SUWIT

- first to 2 wins,
- draw tidak mengisi dot,
- tell truth probability berasal dari fish stats,
- Charm reveal actual choice,
- no-input auto random,
- charge reset tiap duel.

---

# 142. ACCEPTANCE CRITERIA — MARKET

- fish tidak menjadi cash sebelum dijual,
- Sell All benar,
- Bucket disimpan,
- upgrade info ditampilkan sebelum pembelian,
- debt payment mengurangi cash dan debt,
- debt tidak bisa dibayar melebihi remaining.

---

# 143. FIRST 15 MINUTES EXPERIENCE

Minute 0–2:

opening story.

Minute 2–5:

arrival + first cast.

Minute 5–8:

first fish + boxing tutorial.

Minute 8–10:

Market tutorial.

Minute 10–12:

first debt payment.

Minute 12+:

game opens.

Target:

player memahami seluruh thesis game dalam 10 menit:

**Catch fish → fight fish → sell fish → fix life.**

---

# 144. SESSION DESIGN

Ideal session:

10–25 menit.

Namun game tidak memaksa durasi.

Typical:

4–10 fishing encounters.

1–2 Market visits.

1 narrative event jika threshold tercapai.

---

# 145. DIFFICULTY PHILOSOPHY

Game tidak bertujuan menghukum.

Target win rate awal:

70–80%.

Mid-tier:

60–70%.

Don Arowana:

45–60% tanpa upgrade.

Dengan relevant Lv3:

65–75%.

Player harus merasakan upgrade secara nyata.

---

# 146. FAILURE PHILOSOPHY

Loss:

- ikan kabur,
- tidak mendapat uang,
- kembali memancing.

Tidak kehilangan:

- cash,
- upgrade,
- fish lain dalam bucket,
- debt progress.

Failure cost utama:

waktu.

Bukan punishment berat.

---

# 147. TUTORIAL PHILOSOPHY

Tutorial dilakukan melalui:

- contextual prompt,
- one mechanic at a time,
- no giant instruction modal.

Contoh:

> PRESS SPACE TO CAST

kemudian hilang.

> WAIT FOR THE FLOAT...

kemudian:

> STRIKE!

---

# 148. PROGRESSION FEEL

Early game:

"Uang sedikit tetapi setiap ikan berarti."

Mid game:

"Upgrade mulai membuat Darto lebih efektif."

Late game:

"Player menjadi sangat familiar dengan ikan dan duel."

Final:

"Debt akhirnya selesai karena banyak kemenangan kecil, bukan satu jackpot."

Ini harus terasa secara tematis.

---

# 149. NARRATIVE CALLBACK

Pada awal game Darto melihat:

Rp1,800,000

sebagai sesuatu yang mustahil.

Ending tidak memberikan Rp1,800,000 sekaligus.

Player harus secara literal melihat angka itu turun:

1,800,000  
1,742,000  
1,621,500  
...  
350,000  
84,000  
0.

Progress bar adalah metafora sederhana tetapi kuat.

---

# 150. CHARACTER GROWTH DARTO

Darto tidak berubah menjadi orang kaya.

Ia berubah dari:

> "Maybe I can win it back."

menjadi:

> "I'll earn it back."

Dan akhirnya:

> "Maybe tomorrow I'll catch another one."

Itu keseluruhan arc.

---

# 151. RINI'S ARC

Awal:

tidak percaya janji.

Middle:

melihat tindakan.

Ending:

tidak perlu mengatakan "I forgive you."

Ia cukup datang ke danau.

Itu lebih sesuai dengan tone understated.

---

# 152. NISA'S ARC

Awal:

jauh secara fisik.

Middle:

terhubung melalui cerita ikan.

Ending:

hadir di danau bersama Darto.

Fish Book yang awalnya mechanic berubah menjadi sesuatu yang Darto tunjukkan kepada Nisa.

---

# 153. BU YATI'S ARC

Tidak berubah banyak.

Dan itu lucu.

Awal:

> "Fish fresh?"

Ending:

> "Fish fresh?"

Darto:

> "Some things never change."

---

# 154. DON AROWANA'S ROLE

Don Arowana bukan final villain.

Ia adalah semacam legenda lokal.

Mengalahkannya memberi:

- banyak uang,
- prestige,
- Fish Book completion.

Tetapi **debt dapat selesai tanpa pernah mengalahkan Don Arowana**.

Ini penting.

Tema game bukan:

"butuh jackpot langka."

Tema game:

"kemenangan kecil yang konsisten cukup."

---

# 155. DON AROWANA FIRST WIN SCENE

Arowana tergeletak kalah.

Darto mengangkatnya.

Arowana:

> "Enjoy your victory."

Darto:

> "I was planning to."

Arowana:

> "The lake remembers."

Darto:

> "That's fine."

Pause.

> "Does the lake pay three hundred thousand?"

Arowana:

> "You disgust me."

---

# 156. VISUAL ENDING

Final shot:

wide shot.

Danau mengambil sekitar 60% frame.

Darto dan keluarga kecil di bawah pohon.

Motor di samping.

Warung terlihat jauh.

Matahari rendah.

Tidak ada fireworks.

Tidak ada giant "YOU SAVED YOUR FAMILY".

Credits muncul perlahan.

Ambient lake tetap terdengar.

---

# 157. TITLE SCREEN AFTER ENDING

Setelah ending:

Main Menu berubah sedikit.

Sebelumnya Darto sendirian.

Setelah ending:

ada tiga gelas/minuman di dekat bangku.

Tidak perlu karakter tambahan selalu terlihat.

Perubahan kecil.

Warm.

---

# 158. DESIGN RULE — NEVER TOO BUSY

Untuk setiap scene:

maksimum:

1 primary focal point.

2 secondary movement elements.

Ambient props tidak boleh semuanya bergerak bersamaan.

Contoh Fishing:

Primary:

float/water.

Secondary:

Darto + tree leaves.

Background:

static/simple.

---

# 159. DESIGN RULE — COMEDY NEEDS SILENCE

Setelah punchline:

berikan 0.4–1.2 sec pause jika konteks memungkinkan.

Jangan langsung menampilkan tiga joke berikutnya.

Fish animation reaction bisa menjadi punchline tanpa dialog.

---

# 160. DESIGN RULE — COZY UI

UI tidak futuristic.

Panel:

paper/cardboard feel melalui simple flat shape.

Corner sedikit rounded.

Shadow ringan.

Animation:

150–240 ms ease-out.

Menu sound:

wood tap / plastic click style synth.

---

# 161. IMPORTANT AUTHORITATIVE RULES

Jika implementasi dan dokumen lama bertentangan dengan bagian ini, versi ini yang berlaku.

1. Setting utama disebut **Danau Cempaka**.
2. Darto adalah protagonis resmi.
3. Rini adalah istri Darto.
4. Nisa adalah anak mereka.
5. Bu Yati adalah merchant utama.
6. Hutang awal adalah Rp1,800,000.
7. Hutang tidak memiliki bunga gameplay.
8. Basic bait unlimited.
9. Bucket unlimited.
10. Semua upgrade additive kecuali rule secara eksplisit menyatakan lain.
11. Don Arowana base Rp240k + 1.25× = Rp300k.
12. Trash distribution mengikuti tabel definitive.
13. Semua minigame mengikuti constants di GDD ini.
14. Debt dapat selesai tanpa Don Arowana.
15. Ending membuka endless Free Fishing.
16. **Seluruh teks yang terlihat player menggunakan English only.**
17. **Engine production adalah Godot Engine 4.7 atau stable version yang lebih baru.**
18. **Primary scripting language adalah Typed GDScript.**
19. **Release resmi harus tersedia sebagai Android `.aab` untuk Google Play dan Godot Web build untuk itch.io.**
20. **Compatibility renderer adalah baseline v1.0.**
21. Gaya visual selalu **stylized 3D low-poly modern, warm, clean, dan cukup detail**.
22. Tidak ada vertex wobble, pixelated retro filter, affine warping, atau imitasi PS1 sebagai style global.
23. **Seluruh model 3D, material/texture production, UI visual/icon, animation, reference art, store art, music, ambience, dan SFX v1.0 harus dibuat programmatically dari repository sendiri tanpa mengambil asset internet.**
24. Godot built-in default font adalah baseline; tidak ada downloaded font v1.0.
25. Gameplay tidak boleh berubah menjadi gritty debt simulator.
26. Komedi tidak boleh menghilangkan rasa hangat cerita keluarga.
27. Tidak boleh ada gambling gameplay dengan uang player.
28. v1.0 adalah **single-player offline-first**; tidak ada multiplayer/network gameplay.
29. v1.0 tidak memiliki **IAP, microtransaction, gacha, loot box, paid currency, rewarded/interstitial ads, atau ad SDK**.
30. Seluruh music, ambience, SFX, dan UI audio wajib generated by code sesuai Section 175.
31. Roster/content final mengikuti Complete Content Manifest Section 165.
32. Exact public code contract, resource schema, dan save schema mengikuti Sections 169–171.
33. Narrative arbitration mengikuti maksimum satu queued event per Market visit sesuai Section 177.
34. Pengerjaan AI dibagi menjadi 10 milestone sesuai Section 181.
35. Final human/story narrative copy mengikuti **Section 183** dan tidak boleh dibuat ulang secara generatif saat runtime.
36. Zero-internet programmatic asset pipeline mengikuti **Section 184**.
37. Visual identity/reference lock mengikuti **Section 185**.
38. Application/store identity dan current release verification mengikuti **Section 186**.
39. Privacy/Data Safety contract mengikuti **Section 187**.
40. Content-rating disclosure mengikuti **Section 188**; final badge ditentukan IARC/store, bukan ditebak developer.
41. Accessibility v1.0 mengikuti **Section 189**.
42. Hard performance/memory/package budget mengikuti **Section 190**.
43. Git/repository/change-control mengikuti **Section 191**.
44. Human playtest/release usability mengikuti **Section 192**.
45. Bug severity/triage/release defect gate mengikuti **Section 193**.
46. Release Candidate, Content Freeze, dan Gold Master mengikuti **Section 194**.
47. Master Release Checklist mengikuti **Section 195**.
48. Build provenance/reproducibility mengikuti **Section 196**.
49. Public patch/maintenance mengikuti **Section 197**.
50. `V1.0 RELEASE CANDIDATE — COMPLETE` mengikuti Section 182 + 191.17.
51. Final publication hanya boleh memakai artifact berstatus **`V1.0 GOLD MASTER — APPROVED`** menurut Section 194.

---

# 161.1 V6 CONFLICT RESOLUTION

Jika Section 0–160 menggunakan wording lama yang bertentangan dengan Sections 163–197, maka Sections 163–197 adalah authoritative untuk production v6. Balancing/gameplay lama tetap berlaku kecuali specification v6 secara eksplisit menggantinya.

Untuk visual asset pipeline, Section 184 secara eksplisit menggantikan semua izin lama mengenai imported/downloaded production assets.

Untuk narrative copy, Section 183 menggantikan contoh wording lama jika berbeda, tanpa mengubah fakta cerita utama.

---

# 162. ONE-SENTENCE CREATIVE NORTH STAR

Jika developer bingung menentukan sebuah fitur, kembali ke kalimat ini:

> **"A warm Sunday-afternoon fishing game about a flawed man slowly fixing his life, except every fish insists on settling the matter through an absurd duel first."**

Itulah *Mancing Mania: Gelut Edition*.
---

# 163. AI IMPLEMENTATION CONTRACT — AUTHORITATIVE

Bagian ini adalah kontrak kerja resmi untuk AI/developer yang mengimplementasikan game. Jika terdapat konflik antara asumsi implementer, praktik generik, dokumen lama, atau keputusan spontan dengan GDD v6 ini, **GDD v6 menang**.

## 163.1 SOURCE OF TRUTH

Urutan otoritas:

1. Section 161 — Important Authoritative Rules, setelah revisi v6.
2. Sections 163–197 — Final Authoritative Production, Release & Maintenance Specification v6.
3. Section 0–160 — desain dan balancing v3 yang tetap berlaku.
4. Komentar kode, prototype lama, asset placeholder, atau asumsi developer.

AI tidak boleh diam-diam mengubah desain agar “lebih mudah dibuat”. Jika sebuah fitur sulit, implementasi harus disederhanakan secara teknis tanpa mengubah pengalaman yang diwajibkan GDD.

## 163.2 NON-NEGOTIABLE BEHAVIOR

AI/developer WAJIB:

- membaca seluruh GDD sebelum memulai milestone pertama;
- menganggap semua angka balancing sebagai authoritative kecuali bagian balancing authoritative secara eksplisit mengizinkan tuning setelah simulasi;
- menggunakan Godot Engine 4.7 atau stable version yang lebih baru;
- menggunakan typed GDScript sebagai bahasa utama;
- menggunakan Compatibility renderer sebagai baseline v1.0;
- menjaga satu codebase untuk Web dan Android;
- menjaga seluruh teks yang dilihat player dalam English;
- menjaga GDD, komentar desain, dokumentasi engineering, dan laporan QA boleh dalam Bahasa Indonesia atau English;
- menjaga game tetap single-player;
- tidak menambahkan IAP, microtransaction, loot box, gacha, energy system, paid currency, gambling uang player, ad SDK, atau monetization hook tersembunyi;
- tidak menambahkan multiplayer, online account, login, leaderboard online, cloud backend, chat, PvP, co-op, atau networking gameplay;
- tidak mengubah Danau Cempaka menjadi open world;
- tidak menambahkan free-roam character locomotion jika tidak dibutuhkan oleh scene;
- tidak menambahkan inventory capacity pada Bucket;
- tidak menambahkan durability, hunger, thirst, stamina overworld, fuel, repair cost, atau survival mechanic;
- tidak menambahkan random economic reward pada Wheel of Fate;
- tidak mengganti daftar ikan, harga, peluang, upgrade, atau debt progression tanpa revisi GDD;
- membuat setiap milestone berakhir dalam keadaan project dapat boot dan diuji;
- menyelesaikan fitur secara vertikal daripada membuat banyak file kosong;
- menulis test untuk logic kritis sebelum milestone dinyatakan selesai;
- menghapus error, parser warning kritis, broken reference, dan missing resource sebelum lanjut milestone;
- menyimpan balancing/data sebagai Resource/data, bukan magic number tersebar;
- menggunakan InputMap, bukan hard-coded key checks pada gameplay logic;
- memakai API service yang didefinisikan pada Section 169;
- memakai schema resource Section 170 dan save Section 171;
- menggunakan event arbitration Section 177;
- mematuhi Definition of Done Section 182.

## 163.3 AI MUST NOT IMPROVISE DESIGN

AI DILARANG:

- menciptakan ikan ketujuh karena merasa roster terlalu kecil;
- membuat varian upgrade baru;
- menambahkan quest generator;
- mengubah cerita menjadi drama gelap;
- membuat Darto kembali berjudi sebagai mechanic;
- membuat Don Arowana mandatory untuk ending;
- mengubah orientation Android dari portrait sebagai layout utama;
- mengubah visual menjadi pixel-art, PS1, retro wobble, atau low-resolution aesthetic;
- mengganti minigame dengan mechanic lain;
- membuat audio bergantung pada file `.wav`, `.ogg`, `.mp3`, `.flac`, `.aac`, `.m4a`, atau audio download;
- menyisakan tombol yang tidak bekerja;
- menyisakan `TODO`, `FIXME`, fake button, fake settings, atau placeholder text pada v1.0;
- membuat silent failure jika save gagal, resource hilang, atau state invalid.

## 163.4 AMBIGUITY RESOLUTION RULE

Jika detail kecil benar-benar tidak dijelaskan:

1. pilih solusi paling sederhana;
2. pertahankan tone cozy/warm;
3. jangan memperbesar scope;
4. jangan mengubah ekonomi;
5. jangan menambah dependency eksternal;
6. gunakan pola Godot native yang paling mudah dipelihara;
7. dokumentasikan keputusan pada `docs/implementation_decisions.md`.

Keputusan tersebut tidak boleh mengubah rule authoritative.

## 163.5 NO TOKEN-WASTING IMPLEMENTATION STYLE

Untuk pengerjaan oleh AI:

- kerjakan hanya milestone aktif;
- jangan menghasilkan semua sistem milestone berikutnya “sekalian”;
- jangan membuat boilerplate untuk fitur yang belum masuk milestone;
- reuse component yang sudah stabil;
- satu milestone harus memiliki tujuan, file yang dibuat/diubah, test, dan exit criteria yang jelas;
- setelah milestone lulus, baru lanjut milestone berikutnya.

## 163.6 COMPLETION HONESTY

AI tidak boleh menyatakan fitur “selesai” hanya karena script sudah ditulis.

Fitur dianggap selesai hanya jika:

- scene dapat dijalankan;
- input bekerja pada target layout relevan;
- state transition benar;
- save/load relevan bekerja;
- test milestone lulus;
- tidak ada missing dependency;
- tidak ada crash pada happy path;
- acceptance criteria terkait lulus.

---

# 164. DEFINITION OF V1.0 SCOPE

## 164.1 PRODUCT DEFINITION

v1.0 adalah game **single-player offline-first** dengan dua target release:

- Godot Web build untuk itch.io;
- Android `.aab` untuk Google Play Store.

Engine production:

**Godot Engine 4.7 atau stable version yang lebih baru.**

Primary scripting:

**Typed GDScript.**

Renderer baseline:

**Compatibility.**

In-game language:

**English only.**

Setting dan nama karakter tetap Indonesia.

GDD/development documentation:

**Bahasa Indonesia diperbolehkan dan menjadi bahasa utama dokumen ini.**

## 164.2 REQUIRED V1.0 FEATURES

v1.0 WAJIB memiliki:

- Main Menu;
- New Game + safe overwrite confirmation;
- Continue;
- How To Play;
- Settings;
- Credits;
- Prologue;
- Danau Cempaka Fishing scene;
- full fishing cast/wait/nibble/strike/reel/land loop;
- trash catches;
- 6 fish roster authoritative;
- Wheel of Fate;
- Boxing;
- Arm Wrestling;
- Dance/Koplo rhythm duel;
- Suwit;
- Market;
- Sell All dan category sell;
- 5 upgrade families × 3 levels;
- Debt Ledger;
- all debt narrative milestones;
- Fish Book;
- Records;
- save/load/autosave;
- skippable narrative scenes;
- one queued narrative event maximum per Market visit;
- full ending;
- credits;
- post-game Free Fishing Mode;
- Family Savings post-game ledger;
- responsive Web layout;
- Android portrait layout;
- keyboard + mouse support on Web;
- touch support on Android;
- accessibility options di GDD;
- graphics Low/Medium/High presets;
- fully code-generated procedural audio;
- deterministic RNG for gameplay;
- debug/dev tooling pada debug build;
- automated tests;
- Web export preset;
- Android export preset.

## 164.3 EXPLICIT V1.0 NON-GOALS

Tidak termasuk v1.0:

- multiplayer;
- co-op;
- PvP;
- online services;
- dedicated server;
- matchmaking;
- user accounts;
- social login;
- chat;
- online leaderboard;
- cloud save;
- cross-device sync;
- IAP;
- microtransactions;
- gacha;
- loot boxes;
- paid currency;
- rewarded ads;
- interstitial ads;
- ad SDK;
- energy/lives monetization;
- DLC store;
- battle pass;
- subscription;
- open world;
- free walking exploration;
- motorcycle driving gameplay;
- crafting;
- cooking;
- farming;
- housing decoration system;
- equipment durability;
- bait inventory economy;
- bucket capacity;
- realistic day/night cycle;
- dynamic weather simulation;
- procedural quest generation;
- NPC relationship meters;
- branching endings;
- voice acting;
- localization selain English;
- controller/gamepad requirement;
- console release;
- PC native executable release sebagai requirement;
- Steam integration;
- achievements platform;
- telemetry/analytics SDK;
- crash-reporting cloud SDK.
- downloaded/asset-store production art, model, texture, icon, animation, font, music, or SFX;
- cloud asset-generation dependency.

Fitur di atas hanya boleh masuk setelah v1.0 melalui revisi GDD.

## 164.4 RELEASE MODEL

Game boleh didistribusikan gratis atau one-time premium sesuai keputusan publisher, tetapi build v1.0 sendiri:

- tidak memiliki IAP;
- tidak memiliki ad SDK;
- tidak memiliki gameplay monetization;
- tidak memerlukan internet untuk bermain setelah game termuat/terpasang.

---

# 165. COMPLETE CONTENT MANIFEST — V1.0

Section ini adalah daftar konten final. Jumlah konten tidak boleh diam-diam bertambah atau berkurang.

## 165.1 PLAYABLE LOCATIONS / SETS

Tepat 7 world/set utama:

1. `HomeSet` — prologue.
2. `LakeSet` — Danau Cempaka / fishing / main menu background.
3. `MarketSet` — Bu Yati's warung.
4. `BoxingSet` — Tinju Empang arena.
5. `ArmWrestleSet` — Panco Maut table set.
6. `DanceSet` — Joget Koplo set.
7. `SuwitSet` — Suwit set.

Tidak ada explorable map tambahan untuk v1.0.

## 165.2 HUMAN CHARACTERS

Tepat 4 karakter manusia bernama:

1. Darto.
2. Rini.
3. Nisa.
4. Bu Yati.

Decorative distant anglers boleh ada sebagai silhouette/low-detail ambient NPC tanpa nama dan tanpa quest/dialogue tree.

## 165.3 FISH ROSTER

Tepat 6 ikan gameplay. Semuanya berbasis ikan air tawar yang dikenal/terdapat di Indonesia.

| ID | Character Name | Basis ikan | Peran | Tier |
|---|---|---|---|---:|
| `catfish_bruiser` | Bruiser Catfish | Lele / catfish (`Clarias` spp.) | early/common | 1 |
| `tilapia_gym_rat` | Gym-Rat Tilapia | Nila / tilapia | early-mid | 2 |
| `gourami_shady` | Shady Gourami | Gurami / giant gourami | mid | 2 |
| `carp_golden` | Golden Carp | Ikan mas / common carp | mid-late | 3 |
| `snakehead_sergeant` | Snakehead Sergeant | Gabus / snakehead | late | 4 |
| `arowana_don` | Don Arowana | Arwana Asia | rare boss/legend | 5 |

Catatan:

- Don Arowana memang jauh lebih langka daripada ikan lain dan sengaja berfungsi sebagai legenda lokal.
- Fish name yang dilihat player tetap nama karakter English di atas.
- Fish Book dapat menampilkan subtitle basis spesies secara humoristik tanpa menjadi dokumenter ilmiah.

## 165.4 TRASH CONTENT

Tepat 3:

1. Lost Sandal.
2. Rusty Tin Can.
3. Ancient Tyre.

Tidak ada trash tambahan pada v1.0.

## 165.5 DUEL CONTENT

Tepat 4 mode:

1. Boxing / Tinju Empang.
2. Arm Wrestling / Panco Maut.
3. Dance / Joget Koplo.
4. Rock Paper Scissors / Suwit.

Wheel memiliki 8 visual segments tetapi hanya empat outcome unik dengan peluang 25% masing-masing.

## 165.6 ECONOMY CONTENT

Tepat 5 upgrade family, masing-masing Lv0–Lv3:

1. Super Pellet Bait.
2. Carbon Fibre Rod.
3. Herbal Tonic.
4. Black Coffee.
5. Agate Charm Ring.

Total purchasable upgrade steps:

**15.**

Debt awal:

**Rp 1,800,000.**

## 165.7 NARRATIVE EVENT MANIFEST

Event naratif v1.0:

| Event ID | Trigger | Wajib |
|---|---|---|
| `story_prologue_zero` | New Game | yes |
| `story_first_fish` | first scripted Catfish land | yes |
| `story_first_market` | first Market visit | yes/tutorial |
| `story_debt_100k` | lifetime debt paid >=100k | yes |
| `story_debt_300k` | >=300k | yes |
| `story_debt_600k` | >=600k | yes |
| `story_debt_1000k` | >=1,000k | yes |
| `story_debt_1400k` | >=1,400k | yes |
| `story_debt_1650k` | >=1,650k | yes |
| `story_debt_paid` | remaining debt == 0 | yes |
| `story_arowana_first_win` | first Don Arowana win | optional/special |
| `story_final_family` | after `story_debt_paid` | yes |
| `story_postgame_unlock` | credits complete/skip | yes/system |

Tutorial prompts bukan narrative-event quota kecuali scene/cutscene di tabel ini.

## 165.8 UI SCREEN MANIFEST

Tepat screen/overlay utama berikut:

- Boot;
- Main Menu;
- New Game Confirmation;
- Story/Cutscene Overlay;
- Fishing HUD;
- Bucket Quick Peek;
- Wheel;
- Boxing HUD;
- Arm Wrestling HUD;
- Dance HUD;
- Suwit HUD;
- Result;
- Market root;
- Sell tab;
- Upgrades tab;
- Debt tab;
- Fish Book tab;
- Records tab;
- Pause;
- Controls;
- Settings;
- How To Play;
- Credits;
- Save Error modal;
- Import/Export Save optional Web modal jika fitur diaktifkan.

## 165.9 PLAYER-VISIBLE TEXT CONTENT

Semua konten berikut wajib centralized:

- menu labels;
- settings labels;
- tutorial prompts;
- fish dialogue;
- human dialogue;
- story dialogue;
- notification text;
- Fish Book text;
- upgrade descriptions;
- result text;
- error text;
- credits headings.

Tidak boleh ada user-visible string utama hard-coded tersebar di gameplay script.

---

# 166. COMPLETE FISH DIALOGUE BIBLE

Semua baris di bawah adalah **English in-game copy**. Pemilihan random memakai seeded/non-critical dialogue RNG terpisah dari economic roll sehingga dialog tidak mengubah gameplay probability.

Aturan:

- `LAND` dimainkan setelah ikan berhasil direel dan sebelum Wheel.
- `PLAYER_WIN` berarti Darto menang duel dan ikan akan masuk Bucket.
- `FISH_WIN_ESCAPE` berarti ikan menang duel lalu kembali ke danau.
- `REEL_ESCAPE` dimainkan dari arah air jika line break terjadi setelah fish identity telah diketahui oleh internal encounter state.
- satu encounter maksimal menggunakan satu baris dari kategori relevan, kecuali first encounter scripted.
- punchline diberi silence 0.4–1.2 sec jika sesuai.

## 166.1 BRUISER CATFISH — LELE

Persona: preman lokal yang sebenarnya sopan dan profesional.

### First LAND — authoritative tutorial

Catfish: "Put me down."

Darto: "...What?"

Catfish: "You heard me."

Darto: "Fish don't talk."

Catfish: "And unemployed men don't usually argue with dinner."

Catfish: "Square up."

### LAND pool

- "Nothing personal, fisherman. Business is business."
- "We can do this politely. With violence."
- "You again? Fine. Keep your hands up."
- "I had plans this afternoon. Now I have to punch you."

### PLAYER_WIN pool

- "Fair. The bucket earned me."
- "Good hit. Don't make this weird."
- "Tell the market I went down professionally."
- "I respect the hustle. I do not respect the bucket."

### FISH_WIN_ESCAPE pool

- "Tell the bucket I said no."
- "Good effort. Terrible outcome."
- "Nothing personal. I prefer the lake."
- "Come back when your footwork stops apologizing."

### REEL_ESCAPE pool

- "Too much tension, fisherman!"
- "Your line resigned before I did."
- "We'll call that a warning."

## 166.2 GYM-RAT TILAPIA — NILA

Persona: terlalu berotot, terlalu bersemangat, semua hal dianggap latihan.

### First LAND

Tilapia: "DO YOU EVEN REEL?"

Darto: "I was reeling until five seconds ago."

Tilapia: "That rod has terrible form."

Darto: "It's a fishing rod."

Tilapia: "EXCUSES HAVE ZERO PROTEIN."

### LAND pool

- "Warm-up set complete. Now we duel."
- "I counted your pulls. Disappointing volume."
- "Excellent. Resistance training delivered itself."
- "Fisherman! Hydrate. Then prepare to lose."

### PLAYER_WIN pool

- "Solid technique. Questionable lifestyle."
- "That counter had good form. Respect."
- "Fine. Today was apparently leg day."
- "The bucket better have protein."

### FISH_WIN_ESCAPE pool

- "RECOVERY DAY!"
- "Your technique collapsed before my gains did."
- "Train harder. Reel cleaner."
- "I will log this as cardio."

### REEL_ESCAPE pool

- "Grip strength! Work on it!"
- "The line failed its set!"
- "Progressive overload, fisherman! Not catastrophic overload!"

## 166.3 SHADY GOURAMI — GURAMI

Persona: bertingkah seperti orang yang menjalankan bisnis rahasia yang tidak pernah dijelaskan.

### First LAND

Gourami: "You saw nothing."

Darto: "I literally pulled you out of the lake."

Gourami: "This lake doesn't know me."

Darto: "The lake is where I found you."

Gourami: "Allegedly."

### LAND pool

- "This meeting was not scheduled."
- "We can settle this without paperwork."
- "I have associates in deeper water."
- "Whatever happens next, you did not hear my name."

### PLAYER_WIN pool

- "Unfortunate. Delete the records."
- "The bucket and I have never met."
- "I want it noted that this transaction is disputed."
- "Fine. But I was never here."

### FISH_WIN_ESCAPE pool

- "No witnesses. Perfect."
- "Our business is concluded."
- "You should forget my face."
- "The lake has excellent legal representation."

### REEL_ESCAPE pool

- "Evidence destroyed."
- "Loose line. Loose ends. Same principle."
- "You cannot prove that was me."

## 166.4 GOLDEN CARP — IKAN MAS

Persona: sombong, mewah, menganggap dirinya kelas atas meski tinggal di danau yang sama.

### First LAND

Carp: "Careful with the scales. They're expensive."

Darto: "How expensive?"

Carp: "More than your motorcycle."

Darto: "That's not a high bar."

Carp: "I already dislike you."

### LAND pool

- "You may admire me briefly before losing."
- "Do not wrinkle the scales."
- "I was having a premium afternoon."
- "The audacity of that fishing line."

### PLAYER_WIN pool

- "This is economically humiliating."
- "Put something soft in the bucket."
- "I expect premium transportation."
- "You won. Your wardrobe remains concerning."

### FISH_WIN_ESCAPE pool

- "As expected. Luxury returns to the water."
- "Your net worth and your win rate remain consistent."
- "Do wave when I pass your motorcycle."
- "Some things simply cannot be afforded."

### REEL_ESCAPE pool

- "Cheap line. Predictable."
- "That was not premium tension management."
- "Consider equipment with dignity."

## 166.5 SNAKEHEAD SERGEANT — GABUS

Persona: instruktur militer yang menganggap setiap cast sebagai latihan disiplin.

### First LAND

Snakehead: "FISHERMAN!"

Darto: "Why are you yelling?"

Snakehead: "YOUR REELING LACKS CONVICTION!"

Darto: "I caught you."

Snakehead: "TEMPORARILY!"

### LAND pool

- "POSTURE! EYES FORWARD! PREPARE!"
- "YOU CALL THAT A LANDING? AGAIN!"
- "DISCIPLINE BEGINS WHERE COMFORT ENDS!"
- "YOU HAVE ENTERED COMBAT WATER!"

### PLAYER_WIN pool

- "ACCEPTABLE PERFORMANCE! BARELY!"
- "DEFEAT ACKNOWLEDGED! CARRY ON!"
- "GOOD COUNTER! TERRIBLE SANDALS!"
- "THE BUCKET IS NOW MY ASSIGNED POST!"

### FISH_WIN_ESCAPE pool

- "RETURN TO TRAINING!"
- "MISSION FAILED, FISHERMAN!"
- "THE LAKE RETAINS THIS POSITION!"
- "DISCIPLINE: MINE. DINNER: NOT YOURS."

### REEL_ESCAPE pool

- "LINE INTEGRITY FAILURE!"
- "TENSION MANAGEMENT: UNSATISFACTORY!"
- "REGROUP AND CAST AGAIN!"

## 166.6 DON AROWANA — ARWANA ASIA

Persona: tenang, elegan, seperti bos mafia tua yang tidak perlu menaikkan suara.

### First LAND

Arowana: "Darto."

Darto: "...How do you know my name?"

Arowana: "The lake talks."

Darto: "That is deeply concerning."

Arowana: "It should be."

### LAND pool

- "We meet again. The lake has a sense of humor."
- "Patience brought you here. Let us see what skill does."
- "You have become persistent. I respect persistence."
- "Do not mistake rarity for luck, Darto."

### PLAYER_WIN pool — repeat wins

- "A clean victory. Do not become arrogant."
- "You have improved. Quietly. That is preferable."
- "Take your money. The lake will survive the insult."
- "Consistency is an irritating quality. Keep it."

### FISH_WIN_ESCAPE pool

- "Not today, Darto."
- "You were close. Close is still underwater."
- "The lake keeps what you cannot finish."
- "Return when your patience is heavier than your regret."

### REEL_ESCAPE pool

- "You pulled too hard. Life has taught you nothing?"
- "Patience, Darto. Even a line knows its limit."
- "The lake remains undefeated by impatience."

### FIRST PLAYER WIN

Gunakan scene Section 155, bukan pool biasa:

Arowana: "Enjoy your victory."

Darto: "I was planning to."

Arowana: "The lake remembers."

Darto: "That's fine."

Darto: "Does the lake pay three hundred thousand?"

Arowana: "You disgust me."

## 166.7 DARTO GENERIC REACTION POOLS

Agar dialog tidak terasa satu arah:

### After PLAYER_WIN

- "Into the bucket. Please don't make this personal."
- "I can't believe this counts as work now."
- "Good. Bu Yati is going to ask questions again."
- "One fish closer. That's enough."

### After FISH_WIN_ESCAPE

- "Of course it can fight. Of course it can win."
- "Nobody at home needs to know that happened."
- "Fine. Next one."
- "I came here to relax. Important mistake."

### After REEL_ESCAPE

- "Too hard. My fault."
- "Easy, Darto. It's a fish, not a debt collector."
- "That line had a shorter career than I expected."

---

# 167. UI/UX BIBLE — WARM SUNDAY AFTERNOON

UI harus terasa seperti benda sederhana yang cocok berada di warung/danau pada Minggu sore: hangat, tactile, bersih, memuaskan, sedikit lucu, dan tidak futuristik.

## 167.1 DESIGN KEYWORDS

- warm;
- cozy;
- calm;
- handmade;
- faded but cared-for;
- satisfying;
- readable;
- slightly comedic;
- not childish;
- not flashy casino UI;
- not cyberpunk;
- not glossy mobile-gacha UI.

## 167.2 COLOR TOKENS

Gunakan token terpusat di `Theme`/resource:

| Token | Hex | Fungsi |
|---|---|---|
| `cream_50` | `#FFF7E6` | light surface |
| `cream_100` | `#F3E3C2` | primary panel |
| `paper_200` | `#E6CC9D` | secondary panel |
| `ink_900` | `#352F29` | primary text |
| `ink_700` | `#5A5046` | secondary text |
| `lake_500` | `#557F7A` | calm accent |
| `grass_500` | `#778B59` | success/nature accent |
| `sun_500` | `#E4AE55` | highlight/reward |
| `terracotta_500` | `#B8654E` | primary CTA |
| `red_500` | `#A9534D` | danger/stress |
| `blue_400` | `#7195A2` | neutral info |

Critical information tidak pernah bergantung pada warna saja.

## 167.3 TYPOGRAPHY

Untuk menghindari dependency eksternal, v1.0 menggunakan Godot built-in/default readable sans fallback melalui Theme sebagai baseline.

Hierarchy pada reference scale:

- Hero Title: 44 px desktop / 36 px portrait;
- Screen Title: 32 / 28;
- Section Header: 24 / 22;
- Body: 18 / 18;
- Small: 16 / 16;
- Critical Prompt: 28–34;
- Currency: tabular-feeling alignment melalui fixed minimum width, bukan font wajib monospace.

Text rule:

- uppercase hanya untuk prompt singkat, duel reveal, dan button penting;
- dialogue memakai sentence case;
- maksimal sekitar 65 characters per dialogue line pada desktop sebelum wrap;
- portrait menggunakan maksimal 2–3 lines per dialogue bubble jika mungkin.

## 167.4 SPACING & SHAPE TOKENS

Base spacing unit:

`8 logical px`.

Allowed spacing:

`4 / 8 / 12 / 16 / 24 / 32 / 48`.

Panel corner radius visual:

`10–14 px equivalent`.

Button corner radius:

`10 px`.

Panel shadow:

soft, offset 0–4 px, low opacity.

Border:

1–2 px equivalent, warm dark neutral.

## 167.5 INTERACTION STATES

Setiap interactive control memiliki:

- normal;
- hover jika pointer ada;
- focus;
- pressed;
- disabled.

Press feedback:

- scale visual sekitar 0.97 selama 70–100 ms;
- release overshoot maksimal 1.02 lalu settle;
- procedural wood/plastic click SFX;
- tidak lebih dari 180 ms total agar input terasa responsif.

Disabled:

- opacity turun;
- text tetap readable;
- tidak hanya berubah warna;
- jika ditekan/tap tidak melakukan action.

## 167.6 MOTION

Default UI transition:

150–240 ms ease-out.

Large modal:

220–300 ms.

Number count/tween untuk transaksi:

300–650 ms tergantung nominal.

Debt payment:

- cash turun;
- debt remaining turun;
- progress bar bergerak halus;
- procedural single `ding` sederhana;
- **tidak ada confetti, jackpot flash, atau slot-machine feedback.**

Sell receipt:

satisfying tetapi understated: item rows collapse/clear, total naik, satu cash accent pulse.

## 167.7 WEB RESPONSIVE BREAKPOINTS

Layout mode bukan berdasarkan user-agent.

- `LANDSCAPE_WIDE`: aspect >= 1.45;
- `LANDSCAPE_COMPACT`: 1.0–1.449;
- `PORTRAIT`: aspect < 1.0.

Web default:

1280×720 reference.

Minimum supported practical viewport:

960×540 desktop-style; di bawahnya berpindah ke compact/portrait arrangement sesuai aspect.

## 167.8 ANDROID PORTRAIT

Reference:

720×1280.

Semua critical control harus berada di safe area.

Minimum touch target:

48 logical px.

Preferred action target:

56–72 logical px.

Jangan menaruh dua critical action berdekatan tanpa minimal 8–12 px gap.

## 167.9 SCREEN-SPECIFIC UX

### Main Menu

- negative space dominan;
- menu panel tidak menutupi Darto/lake focal point;
- Continue paling atas jika save ada;
- after-ending menu hanya berubah subtle sesuai Section 157;
- versi build kecil di sudut untuk debug, hidden pada release jika tidak diperlukan.

### Fishing HUD

Tampilkan hanya:

- cash;
- bucket count;
- contextual prompt;
- tension/reel UI saat relevan;
- Market button;
- Pause.

Jangan tampilkan semua stats sekaligus.

### Wheel

Wheel harus lucu tetapi bukan kasino:

- paper/painted-wheel visual;
- tidak ada coin shower;
- tidak ada “BIG WIN” language;
- reveal singkat dan jelas;
- skip setelah pertama kali dilihat.

### Duel HUD

Informasi utama selalu dekat area perhatian player.

- Boxing: HP + telegraph readability.
- Arm: position + stamina + burst warning.
- Dance: lanes + judgment + score.
- Suwit: countdown + tell + choice row.

### Market

Market UI terasa seperti ledger/kartu harga, bukan e-commerce app.

Tab order:

SELL → UPGRADES → DEBT → FISH BOOK → RECORDS.

Default first visit membuka SELL.

### Dialogue

- bottom safe-area box;
- speaker label;
- max 3 visible text lines jika memungkinkan;
- confirm/tap untuk lanjut;
- hold skip indicator untuk scene;
- auto-advance tidak digunakan untuk dialogue penting kecuali cinematic timing mengharuskan.

### Settings

Sections:

- Audio;
- Visual;
- Accessibility;
- Controls;
- Save.

Setiap perubahan settings autosave.

## 167.10 SATISFYING FEEDBACK RULE

Feedback harus datang dari kombinasi kecil:

- timing;
- animation;
- sound;
- number movement;
- character reaction.

Jangan mengganti feedback dengan efek besar.

Contoh strike sukses:

float dip → prompt snap → input accepted → rod jerk → splash accent → reel UI muncul.

Contoh perfect dodge:

70 ms freeze → compact accent SFX → fish pose overshoot → counter window highlight.

## 167.11 COMEDY IN UI

Humor UI hanya sesekali:

- flavor subtitle fish;
- CePatCash copy;
- result microcopy;
- disabled-state joke yang tidak mengganggu informasi.

Critical instruction harus selalu jelas dan tidak dikaburkan punchline.


---

# 168. SCENE BLUEPRINT — EXACT GODOT COMPOSITION

Nama file menggunakan `snake_case.tscn`; nama root/key node menggunakan PascalCase. Blueprint ini authoritative untuk struktur utama. Leaf visual node boleh bertambah jika tidak mengubah API/path contract key node.

## 168.1 `boot.tscn`

```text
Boot (Node)
├── BootController (Node)
├── LoadingCanvas (CanvasLayer)
│   └── LoadingRoot (Control)
│       ├── Background (ColorRect)
│       ├── LogoBlock (VBoxContainer)
│       ├── StatusLabel (Label)
│       └── ProgressBar (ProgressBar)
└── TransitionLayer (CanvasLayer)
    └── FadeRect (ColorRect)
```

Responsibilities:

- validate project data;
- initialize save;
- warm procedural critical SFX;
- detect platform;
- verify Web audio unlock state;
- route to MainMenu.

## 168.2 `main_menu.tscn`

```text
MainMenu (Node)
├── World (Node3D)
│   ├── LakeSet (instance)
│   ├── DartoMenuPose (Node3D)
│   ├── MenuCamera (Camera3D)
│   └── MenuLighting (Node3D)
├── MenuCanvas (CanvasLayer)
│   └── SafeRoot (Control)
│       ├── TitleBlock (VBoxContainer)
│       ├── MenuButtons (VBoxContainer)
│       │   ├── ContinueButton
│       │   ├── NewGameButton
│       │   ├── HowToButton
│       │   ├── SettingsButton
│       │   └── CreditsButton
│       └── VersionLabel
├── ConfirmOverlay (CanvasLayer)
└── TransitionLayer (CanvasLayer)
```

## 168.3 `story.tscn`

```text
Story (Node)
├── StoryController (Node)
├── StageRoot (Node3D)
│   ├── ActiveSetAnchor (Node3D)
│   ├── Actors (Node3D)
│   ├── Props (Node3D)
│   └── StoryCamera (Camera3D)
├── StoryCanvas (CanvasLayer)
│   └── StoryUI (Control)
│       ├── DialoguePanel
│       ├── SpeakerLabel
│       ├── DialogueLabel
│       ├── ContinuePrompt
│       ├── NotificationPanel
│       └── SkipHoldIndicator
└── FadeLayer (CanvasLayer)
```

Semua story timeline mengontrol scene ini melalui `CutsceneDirector`/`StoryDirector`.

## 168.4 `fishing.tscn`

```text
Fishing (Node)
├── FishingController (Node)
├── World (Node3D)
│   ├── LakeSet (instance)
│   ├── Darto (Node3D)
│   │   ├── Rig
│   │   ├── RodSocket (Marker3D)
│   │   ├── Rod (Node3D)
│   │   │   └── RodTip (Marker3D)
│   │   └── AnimationPlayer
│   ├── FloatRoot (Node3D)
│   │   ├── FloatMesh
│   │   ├── RippleEmitter
│   │   └── BiteMarker
│   ├── FishShadowRoot (Node3D)
│   ├── FishingCamera (Camera3D)
│   └── FishingEffects (Node3D)
├── FishingCanvas (CanvasLayer)
│   └── SafeRoot (Control)
│       ├── TopBar (HBoxContainer)
│       │   ├── CashWidget
│       │   └── BucketWidget
│       ├── ContextPrompt
│       ├── ReelHUD
│       │   ├── TensionBar
│       │   ├── GreenZone
│       │   ├── PlayerMarker
│       │   ├── LandingProgress
│       │   └── StressWarning
│       ├── ContextActionButton
│       ├── MarketButton
│       └── PauseButton
├── BucketPeekOverlay (CanvasLayer)
└── PauseOverlay (instance)
```

Key path contract:

- rod release origin selalu `Darto/Rod/RodTip`;
- `FloatRoot` bukan child rod setelah release;
- camera tidak shake akibat line stress.

## 168.5 `market.tscn`

```text
Market (Node)
├── MarketController (Node)
├── World (Node3D)
│   ├── MarketSet (instance)
│   ├── BuYati (Node3D)
│   ├── DartoMarketPose (Node3D)
│   └── MarketCamera (Camera3D)
├── MarketCanvas (CanvasLayer)
│   └── SafeRoot (Control)
│       ├── HeaderBar
│       ├── TabBar
│       │   ├── SellTabButton
│       │   ├── UpgradeTabButton
│       │   ├── DebtTabButton
│       │   ├── FishBookTabButton
│       │   └── RecordsTabButton
│       ├── TabContent
│       │   ├── SellPanel
│       │   ├── UpgradePanel
│       │   ├── DebtPanel
│       │   ├── FishBookPanel
│       │   └── RecordsPanel
│       └── LeaveMarketButton
├── ReceiptOverlay (CanvasLayer)
└── PauseOverlay (instance)
```

`LeaveMarketButton` adalah titik utama pemanggilan event arbitration Section 177.

## 168.6 `wheel.tscn`

```text
Wheel (Node)
├── WheelController (Node)
├── World (Node3D)
│   ├── FishDisplayAnchor
│   └── WheelCamera
└── WheelCanvas (CanvasLayer)
    └── SafeRoot
        ├── FishTitle
        ├── WheelGraphic
        ├── Pointer
        ├── ResultLabel
        └── SkipHoldIndicator
```

Outcome sudah ditentukan sebelum visual spin dimulai.

## 168.7 `boxing.tscn`

```text
Boxing (Node)
├── BoxingController
├── World (Node3D)
│   ├── BoxingSet (instance)
│   ├── DartoFighter
│   ├── FishFighter
│   └── BoxingCamera
├── BoxingCanvas (CanvasLayer)
│   └── SafeRoot
│       ├── PlayerHP
│       ├── FishHP
│       ├── RoundTimer
│       ├── TelegraphWidget
│       └── MobileControls
│           ├── DodgeLeftButton
│           ├── DodgeRightButton
│           ├── JabButton
│           └── CrossButton
└── PauseOverlay (instance)
```

## 168.8 `arm_wrestle.tscn`

```text
ArmWrestle (Node)
├── ArmWrestleController
├── World (Node3D)
│   ├── ArmWrestleSet
│   ├── DartoArmRig
│   ├── FishArmRig
│   └── ArmCamera
├── ArmCanvas
│   └── SafeRoot
│       ├── PositionBar
│       ├── StaminaBar
│       ├── RoundTimer
│       ├── BurstWarning
│       └── MashButton
└── PauseOverlay
```

## 168.9 `dance.tscn`

```text
Dance (Node)
├── DanceController
├── RhythmClock
├── ChartGenerator
├── World (Node3D)
│   ├── DanceSet
│   ├── DartoDancer
│   ├── FishDancer
│   └── DanceCamera
├── DanceCanvas
│   └── SafeRoot
│       ├── LaneContainer
│       │   ├── Lane1
│       │   ├── Lane2
│       │   ├── Lane3
│       │   └── Lane4
│       ├── HitLine
│       ├── ScoreWidget
│       ├── ComboWidget
│       ├── JudgmentLabel
│       └── BeatPulse
└── PauseOverlay
```

## 168.10 `suwit.tscn`

```text
Suwit (Node)
├── SuwitController
├── World
│   ├── SuwitSet
│   ├── DartoSuwitPose
│   ├── FishSuwitPose
│   └── SuwitCamera
├── SuwitCanvas
│   └── SafeRoot
│       ├── ScoreDots
│       ├── Countdown
│       ├── TellWidget
│       ├── ChoiceRow
│       │   ├── RockButton
│       │   ├── ScissorsButton
│       │   └── PaperButton
│       └── CharmButton
└── PauseOverlay
```

## 168.11 `result.tscn`

```text
Result (Node)
├── ResultController
├── World
│   ├── ResultStageAnchor
│   ├── DartoResultPose
│   ├── FishResultPose
│   └── ResultCamera
└── ResultCanvas
    └── SafeRoot
        ├── ResultTitle
        ├── DetailLabel
        ├── ContinueButton
        └── AutoContinueProgress
```

## 168.12 OVERLAY SCENES

`pause_overlay.tscn`, `settings_panel.tscn`, `dialogue_panel.tscn`, `confirm_modal.tscn`, `save_error_modal.tscn`, `debug_overlay.tscn` dibuat reusable.

Tidak boleh ada scene raksasa yang memuat seluruh game sekaligus.

---

# 169. EXACT CODE / API CONTRACT

Semua public API menggunakan typed GDScript. Nama method/signals di bawah adalah contract; implementer boleh menambah private helper tetapi tidak boleh mengganti contract tanpa revisi.

## 169.1 AUTOLOADS

Autoload resmi:

```text
GameState
SaveManager
SceneRouter
AudioManager
InputManager
PlatformService
RNGService
StoryDirector
DebugService     # debug build active; release inert/stripped
```

## 169.2 `GameState`

Signals:

```gdscript
signal cash_changed(new_cash: int)
signal debt_changed(paid: int, remaining: int)
signal bucket_changed(total_items: int)
signal upgrade_changed(upgrade_id: StringName, level: int)
signal fish_book_changed(fish_id: StringName)
signal stats_changed()
signal story_state_changed()
```

Public API:

```gdscript
func new_game() -> void
func apply_loaded_save(data: Dictionary) -> void
func export_save_state() -> Dictionary

func get_cash() -> int
func add_cash(amount: int) -> void
func can_spend(amount: int) -> bool
func spend_cash(amount: int) -> bool

func get_debt_original() -> int
func get_debt_paid() -> int
func get_debt_remaining() -> int
func pay_debt(amount: int) -> int

func add_bucket_item(item_id: StringName, quantity: int = 1) -> void
func remove_bucket_item(item_id: StringName, quantity: int) -> bool
func get_bucket_quantity(item_id: StringName) -> int
func get_bucket_total_count() -> int
func clear_bucket_items(item_ids: Array[StringName]) -> Dictionary

func get_upgrade_level(upgrade_id: StringName) -> int
func can_buy_upgrade(upgrade_id: StringName) -> bool
func buy_next_upgrade(upgrade_id: StringName) -> bool

func record_encounter(fish_id: StringName) -> void
func record_fish_win(fish_id: StringName, weight_kg: float, duel_id: StringName) -> void
func record_fish_loss(fish_id: StringName) -> void
func is_fish_discovered(fish_id: StringName) -> bool

func increment_stat(stat_id: StringName, amount: int = 1) -> void
func add_play_time(seconds: float) -> void
```

Rules:

- negative cash tidak pernah valid;
- debt remaining di-clamp `0..1_800_000`;
- `pay_debt()` mengembalikan actual amount paid;
- UI tidak mengubah dictionary internal langsung.

## 169.3 `SaveManager`

Signals:

```gdscript
signal save_started()
signal save_finished(success: bool)
signal load_finished(success: bool)
signal save_error(message: String)
```

API:

```gdscript
func has_save() -> bool
func load_game() -> bool
func save_game(reason: StringName = &"manual") -> bool
func delete_save() -> bool
func create_backup(tag: StringName) -> bool
func validate_save(data: Dictionary) -> Dictionary
func migrate_save(data: Dictionary) -> Dictionary
func export_save_json() -> String
func import_save_json(json_text: String) -> bool
```

`validate_save` mengembalikan dictionary hasil normalisasi atau dictionary kosong jika unrecoverable.

## 169.4 `SceneRouter`

Signals:

```gdscript
signal transition_started(from_scene: StringName, to_scene: StringName)
signal transition_finished(scene_id: StringName)
```

API:

```gdscript
func goto_main_menu() -> void
func goto_fishing() -> void
func goto_market() -> void
func goto_wheel(fish_id: StringName) -> void
func goto_duel(duel_id: StringName, fish_id: StringName) -> void
func goto_result(result: Dictionary) -> void
func goto_story(event_id: StringName) -> void
func reload_current_scene() -> void
```

Transition selalu memakai centralized fade/loading strategy.

## 169.5 `AudioManager`

AudioManager adalah procedural synth facade; tidak load audio file.

Signals:

```gdscript
signal audio_unlocked()
signal music_state_changed(state_id: StringName)
```

API:

```gdscript
func initialize_procedural_audio() -> void
func is_audio_ready() -> bool
func request_web_audio_unlock() -> void
func play_sfx(sfx_id: StringName, gain_db: float = 0.0, seed: int = -1) -> void
func play_ui(sfx_id: StringName) -> void
func set_ambience_state(state_id: StringName, seed: int = -1) -> void
func set_music_state(state_id: StringName, seed: int = -1, bpm_override: float = -1.0) -> void
func stop_music(fade_sec: float = 0.5) -> void
func set_bus_volume(bus_id: StringName, linear: float) -> void
func set_paused(paused: bool) -> void
func get_authoritative_song_time_sec() -> float
func apply_rhythm_calibration(offset_ms: int) -> void
```

## 169.6 `InputManager`

```gdscript
signal input_device_changed(device_type: StringName)

func get_device_type() -> StringName
func is_touch_primary() -> bool
func set_gameplay_input_enabled(enabled: bool) -> void
func get_action_strength_safe(action: StringName) -> float
func consume_action_once(action: StringName) -> bool
```

## 169.7 `PlatformService`

```gdscript
signal viewport_class_changed(viewport_class: StringName)

func is_web() -> bool
func is_android() -> bool
func get_viewport_class() -> StringName
func get_safe_rect() -> Rect2i
func get_reference_scale() -> float
func supports_file_import_export() -> bool
func request_fullscreen(enable: bool) -> void
```

## 169.8 `RNGService`

Gameplay RNG dan cosmetic RNG harus terpisah.

```gdscript
func initialize_session(save_seed: int) -> void
func next_encounter_seed() -> int
func make_rng(seed: int) -> RandomNumberGenerator
func roll_float(channel: StringName, seed: int) -> float
func choose_index(channel: StringName, seed: int, count: int) -> int
func get_debug_snapshot() -> Dictionary
```

Tidak ada `randf()` global untuk keputusan gameplay authoritative.

## 169.9 `StoryDirector`

```gdscript
signal story_event_started(event_id: StringName)
signal story_event_finished(event_id: StringName, skipped: bool)

func evaluate_story_triggers() -> void
func enqueue_event(event_id: StringName) -> void
func get_pending_events() -> Array[StringName]
func begin_market_visit() -> void
func resolve_market_exit_event() -> StringName
func play_event(event_id: StringName) -> void
func skip_active_event() -> void
func mark_event_seen(event_id: StringName) -> void
func supersede_invalid_events() -> void
```

## 169.10 `DebugService`

```gdscript
func is_debug_tools_allowed() -> bool
func set_forced_fish(fish_id: StringName) -> void
func set_forced_duel(duel_id: StringName) -> void
func set_forced_result(result_id: StringName) -> void
func set_cash(value: int) -> void
func set_debt_remaining(value: int) -> void
func set_upgrade_level(upgrade_id: StringName, level: int) -> void
func trigger_story_event(event_id: StringName) -> void
func set_session_seed(seed: int) -> void
func clear_forces() -> void
```

Semua mutation debug harus unavailable pada release build.

## 169.11 `FishingController`

```gdscript
signal fishing_state_changed(state: StringName)
signal encounter_rolled(encounter: Dictionary)
signal fish_landed(fish_id: StringName, weight_kg: float)
signal fishing_failed(reason: StringName)

func start_cast() -> void
func attempt_strike() -> void
func set_reel_held(held: bool) -> void
func cancel_to_idle() -> void
func get_state() -> StringName
```

State ID resmi:

`idle`, `casting`, `waiting`, `bite_warning`, `strike_window`, `reeling`, `landed`, `escaped`.

## 169.12 `MarketController`

```gdscript
func get_sell_preview() -> Dictionary
func sell_all() -> Dictionary
func sell_category(category_id: StringName) -> Dictionary
func purchase_upgrade(upgrade_id: StringName) -> bool
func pay_debt(amount: int) -> int
func leave_market() -> void
```

Semua transaksi:

1. validate;
2. mutate GameState;
3. autosave;
4. refresh UI;
5. evaluate story trigger.

## 169.13 DUEL CONTROLLER CONTRACTS

### `WheelController`

```gdscript
func start_wheel(fish_id: StringName, seed: int, allow_skip: bool) -> void
func request_skip() -> void
func get_preselected_duel_id() -> StringName
```

Signal:

```gdscript
signal wheel_resolved(duel_id: StringName)
```

### `BoxingController`

```gdscript
func start_duel(fish_id: StringName, seed: int) -> void
func request_dodge(direction: StringName) -> void
func request_attack(attack_id: StringName) -> void
func get_snapshot() -> Dictionary
```

### `ArmWrestleController`

```gdscript
func start_duel(fish_id: StringName, seed: int) -> void
func request_mash() -> void
func get_snapshot() -> Dictionary
```

### `DanceController`

```gdscript
func start_duel(fish_id: StringName, seed: int) -> void
func submit_lane(lane_index: int, event_time_sec: float) -> void
func get_song_time_sec() -> float
func get_snapshot() -> Dictionary
```

`event_time_sec` dinormalisasi terhadap authoritative AudioManager song clock, bukan render-frame timestamp mentah.

### `SuwitController`

```gdscript
func start_duel(fish_id: StringName, seed: int) -> void
func choose_move(move_id: StringName) -> void
func use_charm() -> bool
func get_snapshot() -> Dictionary
```

Valid move ID: `rock`, `scissors`, `paper`.

### `ResultController`

```gdscript
func setup_result(result: Dictionary) -> void
func continue_from_result() -> void
```

Tidak ada controller duel yang menulis cash/debt langsung. Duel hanya menghasilkan result; GameState menangani fish/bucket/stat commit melalui flow terpusat.

## 169.14 DUEL RESULT CONTRACT

Semua duel mengembalikan:

```gdscript
{
    "duel_id": StringName,
    "fish_id": StringName,
    "player_won": bool,
    "duration_sec": float,
    "seed": int,
    "metrics": Dictionary
}
```

Result scene tidak menghitung ulang pemenang.

---

# 170. EXACT RESOURCE SCHEMAS

Semua resource berada di `res://data/` dan divalidasi saat Boot pada debug/test build.

## 170.1 `FishData`

File:

`res://data/fish/<fish_id>.tres`

Fields:

| Field | Type | Rule |
|---|---|---|
| `id` | `StringName` | unique, non-empty |
| `display_name` | `String` | English |
| `species_label` | `String` | English |
| `tier` | `int` | 1–5 |
| `sale_base` | `int` | >=0 |
| `sale_multiplier` | `float` | default 1.0; Arowana 1.25 |
| `conditional_chance` | `float` | fish-pool probability |
| `strike_window_sec` | `float` | >0 |
| `reel_half_width` | `float` | 0–0.245 |
| `reel_move_speed` | `float` | >0 |
| `line_stress_per_sec` | `float` | >0 |
| `boxing_hp` | `float` | >0 |
| `boxing_attack` | `float` | >0 |
| `boxing_telegraph_sec` | `float` | >0 |
| `arm_strength` | `float` | 0–100 |
| `rhythm_skill` | `float` | 0–100 |
| `tell_truth_probability` | `float` | 0–1 |
| `weight_min_kg` | `float` | >0 |
| `weight_max_kg` | `float` | >min |
| `dialogue_sequence_id` | `StringName` | valid |
| `model_scene` | `PackedScene` | required |
| `portrait_texture` | `Texture2D` | required final build |

Final authoritative values mengikuti tables Section 28, 32, 33, 35, 39, 40.

## 170.2 `UpgradeData`

File:

`res://data/upgrades/<upgrade_id>.tres`

Fields:

```text
id: StringName
name: String
max_level: int = 3
prices: Array[int]            # exactly 3
stat_key: StringName
effect_per_level: float
effect_unit: String
description: String
```

`prices[level]` menggunakan purchase dari level sekarang ke level+1 dengan index 0..2.

## 170.3 `FishingBalance`

File:

`res://data/balance/fishing_balance.tres`

```text
trash_probability: float = 0.16
base_wait_min_sec: float = 4.5
base_wait_max_sec: float = 9.5
wait_min_final_sec: float = 1.75
false_nibble_min: int = 0
false_nibble_max: int = 2
false_strike_delay_sec: float = 0.8
marker_hold_velocity: float = 0.72
marker_release_velocity: float = -0.58
input_ease_sec: float = 0.12
landing_gain_per_sec: float = 18.0
landing_loss_outside_per_sec: float = 3.0
stress_recover_inside_per_sec: float = 30.0
stress_recover_release_per_sec: float = 16.0
stress_break_value: float = 100.0
rod_half_width_per_level: float = 0.035
rod_half_width_max: float = 0.245
bait_wait_reduction_per_level: float = 0.18
big_one_probability: float = 0.05
```

## 170.4 `BoxingConfig`

`res://data/balance/boxing_config.tres`

```text
player_base_hp: float = 100
hp_per_tonic_level: float = 25
jab_damage: float = 11
jab_startup_sec: float = 0.11
jab_recovery_sec: float = 0.25
cross_damage: float = 18
cross_startup_sec: float = 0.20
cross_recovery_sec: float = 0.44
blocked_damage_multiplier: float = 0.40
perfect_dodge_window_sec: float = 0.18
perfect_freeze_sec: float = 0.07
perfect_counter_sec: float = 0.85
perfect_damage_multiplier: float = 2.4
normal_counter_sec: float = 0.62
normal_damage_multiplier: float = 2.0
round_time_sec: float = 60
normal_attack_cd_min: float = 1.2
normal_attack_cd_max: float = 2.1
boss_attack_cd_min: float = 0.95
boss_attack_cd_max: float = 1.65
```

## 170.5 `ArmWrestleConfig`

```text
round_time_sec: float = 32
position_min: float = -100
position_max: float = 100
base_stamina: float = 100
stamina_bonus_per_level: float = 0.20
press_impulse: float = 4.8
press_stamina_cost: float = 7
max_press_rate_per_sec: float = 10
regen_delay_sec: float = 0.35
regen_per_sec: float = 26
sudden_grip_threshold: float = 2
sudden_grip_target: float = 5
sudden_grip_max_sec: float = 5
boss_rematch_sec: float = 10
```

Power bands mengikuti Section 53.

## 170.6 `DanceConfig`

```text
bpm_min: int = 132
bpm_max: int = 156
duration_min_sec: float = 36
duration_max_sec: float = 44
perfect_window_ms: int = 55
great_window_ms: int = 100
good_window_ms: int = 175
perfect_score: int = 1000
great_score: int = 700
good_score: int = 350
combo_step: int = 10
combo_bonus_step: float = 0.10
combo_bonus_max: float = 0.50
coffee_visual_slow_per_level: float = 0.12
```

## 170.7 `SuwitConfig`

```text
wins_required: int = 2
countdown_sec: float = 3.0
tell_time_from_start_sec: float = 1.1
charm_reveal_sec: float = 0.8
charm_charge_per_level: int = 1
panic_pick_enabled: bool = true
```

## 170.8 `StoryEvent`

File:

`res://data/story/<event_id>.tres`

```text
id: StringName
priority: int
trigger_type: StringName
trigger_value: Variant
once: bool = true
market_event: bool = true
skippable: bool = true
supersedes: Array[StringName]
requires_seen: Array[StringName]
blocks_until_seen: Array[StringName]
timeline_id: StringName
```

Priority semakin tinggi berarti dipilih lebih dahulu.

## 170.9 `DialogueSequence`

```text
id: StringName
entries: Array[DialogueEntry]
```

`DialogueEntry`:

```text
speaker_id: StringName
text: String
min_hold_sec: float = 0.0
post_pause_sec: float = 0.4
portrait_expression: StringName
animation_cue: StringName
```

Semua `text` harus English pada v1.0.

## 170.10 `AudioPreset`

Bukan file audio. Ini hanya parameter synthesis.

```text
id: StringName
synth_type: StringName
base_gain_db: float
attack_sec: float
decay_sec: float
sustain: float
release_sec: float
pitch_hz: float
noise_amount: float
filter_cutoff_hz: float
seed_mode: StringName
```

Disimpan sebagai `.tres` di `res://data/audio/`.

---

# 171. EXACT SAVE SCHEMA — VERSION 5

Bagian ini menggantikan conceptual schema lama jika ada perbedaan.

Save path:

`user://save_v5.json`

Corrupt backup:

`user://save_v5_corrupt_backup.json`

Schema version:

`5`.

## 171.1 TOP-LEVEL JSON

```json
{
  "version": 5,
  "created_at_utc": "2026-01-01T00:00:00Z",
  "last_played_at_utc": "2026-01-01T00:00:00Z",
  "cash": 8430,
  "debt": {},
  "upgrades": {},
  "bucket": {},
  "fish_book": {},
  "stats": {},
  "story": {},
  "tutorials": {},
  "settings": {},
  "rng": {},
  "system": {}
}
```

Timestamp menggunakan ISO-8601 UTC string.

## 171.2 `debt`

```json
{
  "original": 1800000,
  "paid": 0,
  "remaining": 1800000
}
```

Invariant:

`paid + remaining == original`.

## 171.3 `upgrades`

```json
{
  "bait": 0,
  "rod": 0,
  "tonic": 0,
  "coffee": 0,
  "charm": 0
}
```

Semua int `0..3`.

## 171.4 `bucket`

```json
{
  "catfish_bruiser": 0,
  "tilapia_gym_rat": 0,
  "gourami_shady": 0,
  "carp_golden": 0,
  "snakehead_sergeant": 0,
  "arowana_don": 0,
  "trash_sandal": 0,
  "trash_can": 0,
  "trash_tyre": 0
}
```

Semua integer >=0.

## 171.5 `fish_book`

```json
{
  "catfish_bruiser": {
    "discovered": false,
    "best_weight_kg": 0.0,
    "encounters": 0,
    "wins": 0,
    "losses": 0,
    "favourite_duel": ""
  }
}
```

Entry yang sama wajib ada untuk keenam fish ID.

`favourite_duel` dihitung/disimpan sebagai ID dari mode dengan kemenangan terbanyak; tie menggunakan urutan `boxing`, `arm_wrestle`, `dance`, `suwit` untuk determinism.

## 171.6 `stats`

```json
{
  "total_casts": 0,
  "successful_strikes": 0,
  "failed_strikes": 0,
  "lines_broken": 0,
  "trash_caught": 0,
  "fish_landed": 0,
  "duel_wins": 0,
  "duel_losses": 0,
  "boxing_wins": 0,
  "arm_wrestle_wins": 0,
  "dance_wins": 0,
  "suwit_wins": 0,
  "don_arowana_defeated": 0,
  "lifetime_sales": 0,
  "lifetime_debt_paid": 0,
  "family_savings": 0,
  "largest_fish_id": "",
  "largest_fish_weight_kg": 0.0,
  "play_time_sec": 0.0
}
```

## 171.7 `story`

```json
{
  "chapter": "prologue",
  "seen_events": [],
  "pending_events": [],
  "ending_completed": false,
  "postgame_unlocked": false,
  "fish_book_unlocked": false,
  "arowana_first_win_seen": false,
  "market_visit_serial": 0,
  "last_market_event_visit_serial": -1
}
```

Arrays hanya berisi valid `StringName` serialized as String.

## 171.8 `tutorials`

```json
{
  "fishing_seen": false,
  "reeling_seen": false,
  "wheel_seen": false,
  "boxing_seen": false,
  "arm_wrestle_seen": false,
  "dance_seen": false,
  "suwit_seen": false,
  "market_seen": false,
  "debt_seen": false
}
```

## 171.9 `settings`

```json
{
  "master_volume": 1.0,
  "music_volume": 0.80,
  "sfx_volume": 0.90,
  "ambience_volume": 0.75,
  "ui_volume": 0.85,
  "hud_shake": "on",
  "reduced_flash": false,
  "reduced_motion": false,
  "high_contrast_hud": false,
  "ui_scale": 1.0,
  "text_scale": 1.0,
  "rhythm_beat_pulse": true,
  "rhythm_input_offset_ms": 0,
  "rhythm_visual_offset_ms": 0,
  "arm_input_mode": "mash",
  "mobile_handedness": "right",
  "dialogue_speed": "normal",
  "skip_hold_sec": 0.8,
  "quality_preset": "medium",
  "fullscreen_web": false,
  "input_remap": {}
}
```

Volumes clamp `0.0..1.0`.

`hud_shake`: `on`, `reduced`, `off`.

`ui_scale`: `0.9`, `1.0`, `1.15`, `1.30`.

`text_scale`: `1.0`, `1.15`, `1.30`, `1.50`.

`arm_input_mode`: `mash`, `hold_assist`.

`mobile_handedness`: `right`, `left`.

`dialogue_speed`: `instant`, `fast`, `normal`, `relaxed`.

`skip_hold_sec`: `0.4`, `0.8`, `1.2`.

Rhythm offsets clamp `-150..150 ms`.

`input_remap` menyimpan override action keyboard yang valid; empty object berarti default InputMap.

`quality_preset`: `low`, `medium`, `high`.

## 171.10 `rng`

```json
{
  "save_seed": 123456789,
  "encounter_counter": 0,
  "duel_counter": 0
}
```

Save seed dibuat saat New Game dan tidak berubah.

## 171.11 `system`

```json
{
  "schema_version": 5,
  "engine_version": "4.7",
  "build_version": "1.0.0",
  "last_platform": "web"
}
```

`last_platform`: `web`, `android`, atau `other` pada development.

## 171.12 VALIDATION RULES

Load harus:

- reject non-object root;
- reject version <=0;
- migrate supported old schema berurutan;
- clamp upgrade level;
- clamp negative counters ke 0;
- recompute debt invariant jika satu field inconsistent tetapi dua field lain valid;
- reject debt jika seluruh fields tidak recoverable;
- remove unknown story event IDs dari pending queue;
- preserve unknown harmless top-level field hanya selama migration jika diperlukan, tetapi rewrite latest schema tanpa field yang tidak dikenal;
- backup file sebelum destructive rewrite.

## 171.13 AUTOSAVE ORDER

Untuk transaction:

`validate action → mutate state → enqueue story trigger → save → show success feedback`.

Jika save gagal:

- state runtime tetap ada;
- player diberi error modal;
- retry tersedia;
- jangan berpura-pura save berhasil.

---

# 172. ANIMATION MANIFEST

Semua clip name menggunakan `snake_case` dan event marker deterministic. Playback smooth pada 30/60 FPS.

## 172.1 DARTO CORE CLIPS

| Clip | Duration guideline | Loop | Event marker |
|---|---:|---|---|
| `idle_fishing` | 4.0–7.0s | yes | subtle variation |
| `cast_prepare` | 0.30s | no | — |
| `cast_forward` | 0.42s | no | `release_float` at global cast t=0.48 |
| `cast_settle` | 0.63s | no | `cast_complete` |
| `reel_hold` | 1.0s | yes | — |
| `reel_release_relax` | 0.35s | no | — |
| `line_stress_jerk` | 0.30s | no/additive | — |
| `land_fish` | 1.10s | no | `fish_reveal` |
| `empty_pull` | 0.80s | no | — |
| `fish_escape_react` | 1.00s | no | — |
| `bucket_add` | 0.75s | no | `bucket_commit` |
| `market_idle` | 5.0s | yes | — |
| `phone_check` | 1.5s | no | — |
| `sit_home` | 5.0s | yes | — |
| `stand_home` | 1.4s | no | — |
| `small_laugh` | 1.2s | no | — |

## 172.2 DARTO BOXING

| Clip | Guideline |
|---|---|
| `box_idle` | loop, guarded but slightly awkward |
| `box_dodge_left` | 0.32s |
| `box_dodge_right` | 0.32s |
| `box_jab` | match 0.11 startup + 0.25 recovery |
| `box_cross` | match 0.20 startup + 0.44 recovery |
| `box_hit_left` | 0.45s |
| `box_hit_right` | 0.45s |
| `box_ko` | 1.20s |
| `box_win` | 1.10s understated |

Attack animation marker `hit_frame` harus sama dengan combat timing authoritative, bukan visual-only guess.

## 172.3 DARTO ARM WRESTLE

- `arm_idle_grip` loop;
- `arm_push_light` loop blend;
- `arm_push_hard` loop blend;
- `arm_recover`;
- `arm_win`;
- `arm_lose`.

Blend parameter mengikuti normalized position + stamina, bukan random animation.

## 172.4 DARTO DANCE

- `dance_idle_bounce`;
- `dance_hit_lane_1`;
- `dance_hit_lane_2`;
- `dance_hit_lane_3`;
- `dance_hit_lane_4`;
- `dance_combo_high`;
- `dance_miss`;
- `dance_win`;
- `dance_lose`.

Animation tidak menjadi authoritative timing source; audio clock tetap authoritative.

## 172.5 DARTO SUWIT

- `suwit_ready`;
- `suwit_rock`;
- `suwit_scissors`;
- `suwit_paper`;
- `suwit_win`;
- `suwit_lose`;
- `suwit_draw`.

## 172.6 UNIVERSAL FISH CLIP CONTRACT

Setiap fish rig menyediakan clip ID berikut meskipun pose/gerakan spesifik berbeda:

```text
fish_idle_water
fish_hooked_pull
fish_land_flop
fish_challenge
fish_bucket_defeat
fish_escape_jump
box_idle
box_attack_a
box_attack_b
box_attack_c
box_block
box_hit
box_ko
arm_idle
arm_burst
arm_win
arm_lose
dance_idle
dance_good
dance_great
dance_perfect
dance_miss
dance_win
dance_lose
suwit_ready
suwit_tell_true
suwit_tell_fake
suwit_reveal
suwit_win
suwit_lose
suwit_draw
```

Box attack marker:

- `telegraph_start`;
- `impact`;
- `recovery_end`.

Telegraph duration mengikuti `FishData`, bukan fixed animation assumption.

## 172.7 SPECIES SIGNATURE MOTION

- Catfish: whisker secondary motion, compact boxer stance.
- Tilapia: exaggerated chest/fin flex, fast confident bounce.
- Gourami: suspicious glance, minimal body movement, sunglasses adjustment.
- Carp: slow elegant turn, offended recoil.
- Snakehead: sharp military snaps, rigid salutes.
- Arowana: minimal movement, smooth deliberate turns, no frantic flapping.

## 172.8 HUMAN SUPPORT CLIPS

Rini:

`idle_home`, `put_on_shoes`, `look_darto`, `deadpan_pause`, `sit_lake`, `small_smile`.

Nisa:

`phone_call_idle`, `sit_lake`, `lean_forward`, `laugh_small`.

Bu Yati:

`market_idle`, `weigh_fish`, `cash_count`, `look_darto`, `deadpan_blink`.

## 172.9 ENVIRONMENT ANIMATION

- tree leaves: low-amplitude looping sway;
- grass clusters: staggered sway;
- water: slow procedural movement;
- hanging lamp: almost static, optional subtle sway;
- market fan: rotating when visible;
- smoke: slow procedural particle;
- distant birds: occasional one-shot.

Rule Section 158 tetap berlaku: jangan semua bergerak bersamaan.


---

# 173. CAMERA & CUTSCENE BIBLE

Camera harus stabil, understated, dan tidak mencoba membuat cerita sederhana terasa seperti melodrama blockbuster.

## 173.1 GLOBAL CAMERA RULES

- Perspective `Camera3D`.
- Default FOV gameplay sekitar 45°–55° sesuai set.
- Dialogue medium shot sekitar 40°–48°.
- Emotional close-up jarang; FOV 35°–42° hanya jika dibutuhkan.
- No handheld shake untuk narrative.
- No dutch angle kecuali satu joke visual yang sangat jelas dan tidak mengganggu readability; default tidak digunakan.
- Camera move memakai ease-in/out lembut.
- Cut lebih disukai daripada camera orbit panjang.
- Establishing shot 2.5–5 sec.
- Reaction hold setelah punchline 0.4–1.2 sec.
- Tidak ada fast montage pada prologue.
- Fishing camera tidak shake akibat stress.

## 173.2 SHOT ID CONVENTION

`<EVENT>_S<NN>`.

Timeline setiap shot menyimpan:

```text
shot_id
camera_anchor
fov
start_duration
move_type
look_target
actor_cues
dialogue_id
sfx_id
music_state
end_transition
```

## 173.3 PROLOGUE `story_prologue_zero`

Target total: 38–52 sec tanpa player skip.

| Shot | FOV | Durasi | Deskripsi |
|---|---:|---:|---|
| `ZERO_S01` | 50 | 3.0s | black → fade ke wide rumah sederhana; kipas dan room tone |
| `ZERO_S02` | 42 | 4.0s | medium Darto duduk di lantai, ponsel di foreground |
| `ZERO_S03` | 38 | 3.0s | insert phone: BANK BALANCE dan TOTAL DEBT |
| `ZERO_S04` | 45 | 12–18s | two-shot Darto/Rini untuk dialogue utama; camera static |
| `ZERO_S05` | 50 | 3.0s | pintu menutup; Darto tetap frame, pause |
| `ZERO_S06` | 45 | 4.0s | insert joran, ember, helm, kunci motor |
| `ZERO_S07` | 50 | 3.0s | Darto berdiri; hard cut ke luar |

Music:

none.

Audio:

procedural fan, distant motor, room tone, door click.

## 173.4 MOTOR TITLE SHOT

Target total: 10–14 sec.

- `MOTOR_S01`: wide roadside static, FOV 52, motor masuk frame 4 sec.
- `MOTOR_S02`: trailing side composition, FOV 48, 4 sec, no dramatic acceleration.
- `MOTOR_S03`: wider lake approach, FOV 55, title appears, then `SUNDAY — 3:17 PM`.

Motor bukan hero product shot.

## 173.5 FIRST FISH `story_first_fish`

Target total setelah landing: 28–40 sec.

- `FIRSTFISH_S01`: fish lift reveal; FOV 48.
- `FIRSTFISH_S02`: medium Darto reaction; FOV 42.
- `FIRSTFISH_S03`: fish close-medium, Catfish speaks; FOV 40.
- `FIRSTFISH_S04`: alternating static cuts; no orbit.
- `FIRSTFISH_S05`: glove reveal with small sting; hold 0.7 sec after “Square up.”
- transition to Wheel tutorial.

## 173.6 FIRST MARKET `story_first_market`

Target: 22–32 sec.

- establishing warung 3 sec;
- medium Bu Yati at scale;
- two-shot sale interaction;
- insert cash/debt UI only when tutorial begins;
- final reaction after first Rp10,000 payment.

## 173.7 DEBT MILESTONE SCENES

Semua milestone dibuat singkat dan tampil melalui Story scene setelah Market exit arbitration.

### `story_debt_100k`

15–22 sec.

Shot:

1. Darto di bangku luar Market melihat ledger.
2. Small relieved exhale.
3. Short text/phone from Rini tanpa dramatic reaction.

Tone:

progress kecil, belum celebration.

### `story_debt_300k`

18–25 sec.

1. phone notification close-medium;
2. Rini text: `I saw the payment.`
3. Darto reply;
4. Rini deadpan response;
5. Darto small smile.

### `story_debt_600k`

25–40 sec.

Nisa phone call.

1. Darto duduk dekat danau, phone at ear;
2. Nisa represented through phone UI/subtitle; no need split-screen;
3. Nisa asks about strange fish;
4. request to send picture if golden one caught;
5. Fish Book unlock card appears after scene.

### `story_debt_1000k`

22–32 sec.

1. home or market-side phone scene;
2. Rini talks about what comes after debt;
3. Darto tidak membuat janji besar;
4. understated end.

### `story_debt_1400k`

18–28 sec.

1. Bu Yati weighing fish;
2. tells Darto regular buyer likes his catch;
3. Darto realizes activity can remain useful after debt;
4. no promotion fanfare.

### `story_debt_1650k`

15–22 sec.

1. ledger insert;
2. Darto looks at lake;
3. same ambience as always;
4. one simple line emphasizing almost done but life unchanged.

## 173.8 `story_arowana_first_win`

22–32 sec.

1. Don Arowana defeated pose, low but not heroic angle, FOV 42.
2. Darto lifts Arowana; medium two-shot style.
3. dialogue Section 155/166.
4. pause after “Does the lake pay three hundred thousand?”
5. Arowana: “You disgust me.”
6. cut to Result.

No boss explosion, no giant victory flare.

## 173.9 `story_debt_paid`

20–30 sec.

1. insert Debt Ledger before action.
2. player chooses `PAY REMAINING`.
3. cash/debt UI settles to Rp0.
4. phone CePatCash message.
5. medium Darto waiting.
6. `"...That's it?"`
7. small laugh.
8. fade.

No music until final small laugh; then optional one soft warm motif.

## 173.10 `story_final_family`

45–60 sec.

1. Wide lake: two helmets visible before people clearly readable.
2. Medium family around simple food.
3. Nisa asks fish question.
4. Rini mentions Darto lost twice.
5. dialogue continues with static/slow cuts.
6. float dips.
7. Darto stands.
8. Rini: `"Don't start a fight."`
9. Darto: `"I don't start them."`
10. water insert; Don Arowana: `"LIAR."`
11. 0.8 sec reaction silence.
12. cut to black → Credits.

Final wide composition:

lake approximately 60% frame; family small in composition; no fireworks.

## 173.11 SKIP BEHAVIOR

Hold skip 0.8 sec.

Skip must:

- execute all state changes;
- execute unlocks;
- mark event seen;
- preserve debt/cash already committed;
- restore correct audio state;
- route to deterministic destination;
- never leave actor/camera/timeline half-state.

---

# 174. GENERATED ASSET MANIFEST & FILE NAMING

Section ini adalah manifest nama final untuk production asset yang **dihasilkan programmatically**. Full generation contract ada di Section 184. Tidak ada downloaded/imported production asset.

## 174.1 NAMING

Prefix logical ID:

- `chr_` human character;
- `fish_` fish;
- `prop_` prop;
- `env_` environment;
- `veh_` vehicle;
- `ui_` UI/icon;
- `mat_` material;
- `tex_` generated texture;
- `fx_` effect.

Generated output memakai `.tscn`, `.tres`, `.res`, atau image hasil project generator jika benar-benar diperlukan. Tidak ada `final2`, `new_new`, `temp_final`, atau `untitled`.

## 174.2 HUMAN GENERATED SCENES

```text
generated/scenes/characters/chr_darto.tscn
generated/scenes/characters/chr_rini.tscn
generated/scenes/characters/chr_nisa.tscn
generated/scenes/characters/chr_bu_yati.tscn
```

## 174.3 FISH GENERATED SCENES

```text
generated/scenes/fish/fish_catfish_bruiser.tscn
generated/scenes/fish/fish_tilapia_gym_rat.tscn
generated/scenes/fish/fish_gourami_shady.tscn
generated/scenes/fish/fish_carp_golden.tscn
generated/scenes/fish/fish_snakehead_sergeant.tscn
generated/scenes/fish/fish_arowana_don.tscn
```

## 174.4 VEHICLES

```text
generated/scenes/vehicles/veh_darto_old_motorcycle.tscn
generated/scenes/vehicles/veh_bu_yati_motorcycle.tscn
```

No real brand/logo.

## 174.5 FISHING / HOME / MARKET PROPS

Logical generated IDs include:

```text
prop_fishing_rod_basic
prop_float_basic
prop_bucket_blue
prop_helmet_darto
prop_helmet_family_second
prop_phone_old
prop_home_floor_mat
prop_home_low_table
prop_home_fan
prop_home_shoe_pair
prop_home_door
prop_market_table
prop_market_scale
prop_market_freezer
prop_market_thermos
prop_market_jar_set
prop_plastic_chair
prop_hanging_lamp
prop_market_price_board
prop_market_fan
```

## 174.6 ENVIRONMENT MODULES

```text
env_lake_water
env_lake_shore
env_tree_large_a
env_tree_large_b
env_grass_cluster_a
env_reeds_cluster_a
env_road_segment
env_power_pole
env_street_lamp
env_distant_house_cluster
env_distant_garden_cluster
env_market_shell
env_home_room_shell
```

Repeated foliage memakai MultiMesh/instancing dengan fixed placement seed.

## 174.7 DUEL PROPS

```text
prop_boxing_corner_stool
prop_boxing_ropes
prop_boxing_mat
prop_arm_table
prop_arm_elbow_pad
prop_dance_platform
prop_dance_string_light
prop_suwit_table
```

## 174.8 TRASH

```text
prop_trash_lost_sandal
prop_trash_rusty_can
prop_trash_ancient_tyre
```

## 174.9 FISH BOOK PORTRAITS

Fish Book portrait dirender otomatis dari generated 3D fish melalui reference/render generator.

```text
generated/textures/fish_book/tex_fishbook_catfish_bruiser.png
generated/textures/fish_book/tex_fishbook_tilapia_gym_rat.png
generated/textures/fish_book/tex_fishbook_gourami_shady.png
generated/textures/fish_book/tex_fishbook_carp_golden.png
generated/textures/fish_book/tex_fishbook_snakehead_sergeant.png
generated/textures/fish_book/tex_fishbook_arowana_don.png
```

These PNGs are project-generated outputs, not internet assets.

## 174.10 UI ICON IDs

```text
ui_icon_cash
ui_icon_bucket
ui_icon_market
ui_icon_pause
ui_icon_rod
ui_icon_bait
ui_icon_tonic
ui_icon_coffee
ui_icon_charm
ui_icon_debt
ui_icon_fish_book
ui_icon_records
ui_icon_boxing
ui_icon_arm
ui_icon_dance
ui_icon_suwit
ui_icon_rock
ui_icon_scissors
ui_icon_paper
ui_icon_warning
ui_icon_save
ui_icon_privacy
ui_icon_accessibility
```

UI icons dibuat melalui `ui_art_builder.gd` dari line/polygon/shape primitives.

## 174.11 FONT

v1.0 menggunakan Godot built-in default readable font. Tidak ada custom/downloaded font file.

## 174.12 AUDIO

Tidak ada production audio media file. Section 175 authoritative.

## 174.13 PROVENANCE

Setiap generated asset harus tercatat pada `generated/manifests/generator_manifest.json` dengan generator ID/version/seed/output.

## 174.14 COMPLETENESS GATE

Release gagal jika:

- required logical ID tidak menghasilkan output;
- generated output missing/broken;
- hero asset masih terlihat placeholder primitive;
- external production asset ditemukan;
- internet fetch dibutuhkan untuk regenerate;
- real-world logo tertinggal;
- generated asset melanggar reference sheet Section 185.

---

# 175. PROCEDURAL AUDIO DIRECTION — 100% CODE GENERATED

Bagian ini menggantikan semua izin lama untuk imported audio. **Tidak ada audio file eksternal pada v1.0.**

## 175.1 AUDIO PRINCIPLE

Semua:

- music;
- ambience;
- SFX;
- UI sound;
- fishing sound;
- duel sound;
- procedural radio feeling;

harus dihasilkan dari code + numeric synthesis presets.

Dialog tidak memiliki voice acting. Dialogue dibaca sebagai on-screen text/subtitle.

## 175.2 TECHNICAL ARCHITECTURE

Gunakan kombinasi:

- `AudioStreamGenerator` untuk continuous procedural stream;
- `AudioStreamGeneratorPlayback` untuk push frames;
- programmatically created `AudioStreamWAV` in-memory untuk short SFX yang di-render saat boot/first use;
- `AudioServer` bus untuk routing;
- deterministic sequencer untuk music/rhythm;
- lightweight DSP implemented in GDScript, dengan helper class terpisah agar `_process` gameplay tidak terbebani.

Project mix target:

**48,000 Hz stereo** jika platform stabil; fallback 44,100 Hz hanya jika device/browser membutuhkan.

Generator buffer guideline:

80–140 ms untuk ambience/music.

Critical short SFX dipre-render ke memory agar input-to-sound latency tidak menunggu synthesis block.

## 175.3 SYNTH MODULES

Minimal modules:

```text
Oscillator        # sine, triangle, square/pulse, saw
NoiseGenerator    # white/pink-ish filtered noise
EnvelopeADSR
OnePoleLPF
OnePoleHPF
BiquadLikeFilter  # simplified if CPU allows
PitchEnvelope
LFO
DelayLine         # subtle, short
KarplusStrong     # pluck/string-like tone
DrumSynth
Sequencer
ProceduralAmbience
SFXRenderer
```

Clipping:

soft limiter/saturation ringan pada final synth chain, bukan hard clipping.

## 175.4 BUS LAYOUT

```text
Master
├── Music
├── SFX
├── Ambience
└── UI
```

Dialogue tidak memiliki voice bus karena tidak ada voice-over.

Default linear settings mengikuti save schema.

## 175.5 MIX PRIORITY & DUCKING

Priority tetap:

1. gameplay critical;
2. UI confirmation;
3. duel music;
4. ambience;
5. decorative events.

Saat bite cue:

- Ambience duck sekitar 3–5 dB selama 350–550 ms.

Saat Result reveal:

- Music duck sekitar 2–3 dB sebentar jika diperlukan agar sting readable.

Tidak ada aggressive sidechain pumping.

## 175.6 PROCEDURAL FISHING SFX RECIPES

### `sfx_cast_whoosh`

Filtered noise burst + falling high-pass + short envelope, 220–400 ms.

### `sfx_float_plip`

Sine 700–1100 Hz short droplet + filtered noise tick, 80–130 ms.

### `sfx_false_nibble`

Quieter variant of plip + very small water noise.

### `sfx_real_bite`

Low water thump + bright click + short pitch drop; unmistakable from nibble.

### `sfx_strike_success`

Short stick/pluck transient + rod tension twang.

### `sfx_reel_tick`

Sparse mechanical click; rate-limited so hold reel tidak menjadi machine gun.

### `sfx_line_stress`

Tension creak synthesized through pitched noise/granular-like impulse cluster. Intensity mapped to stress band.

### `sfx_line_break`

Short snapped string via Karplus-Strong high tension + noise crack.

### `sfx_large_splash`

Layered low noise burst + bandpassed mid splash + several tiny droplets.

## 175.7 UI SFX RECIPES

### `ui_click`

Wood/plastic hybrid: short filtered impulse + sine body 180–260 Hz.

### `ui_back`

Lower pitch, softer click.

### `ui_disabled`

Dry muted tap, no negative buzzer.

### `ui_purchase`

Two-note warm pluck, ascending small interval.

### `ui_sell`

Soft paper/coin-like tick cluster, no slot-machine cascade.

### `ui_debt_ding`

Single clean warm chime; understated.

### `ui_save`

Tiny soft tick; optional and <=1 sec indicator.

## 175.8 BOXING SFX

- `box_glove_swing`: short noise whoosh;
- `box_hit_light`: low-mid transient + soft noise;
- `box_hit_heavy`: stronger body thump, no realistic gore;
- `box_block`: muted padded hit;
- `box_dodge`: fast cloth/noise sweep;
- `box_perfect`: compact tonal accent + 70 ms freeze;
- `box_ko`: short comic low tom sequence.

No bone-breaking realism.

## 175.9 ARM WRESTLING SFX

- table creak: filtered noise + low sine body;
- hand strain: subtle synthetic friction, not human pain vocals;
- mash accepted: extremely light click every accepted press, dynamically reduced at high press rate;
- fish burst telegraph: low rising pulse;
- win: short heroic parody motif;
- loss: descending two-note motif.

## 175.10 KOPLO / DANCE MUSIC SYNTHESIS

Track sepenuhnya generated per duel seed.

Instrument voices:

- kick: sine pitch drop + short click;
- snare: filtered noise + body tone;
- closed hat: high-pass noise;
- open hat: longer noise envelope;
- kendang-like low: resonant sine/triangle + pitch bend;
- kendang-like high: shorter higher resonant tone;
- bass: triangle/sine hybrid;
- pluck: Karplus-Strong or short decaying triangle;
- chord pad: low-voice-count triangle/sine chord;
- comedic accent: short pitch bend synth.

Pattern:

- BPM 132–156 as GDD;
- deterministic seeded bar generator;
- 4/4 base;
- rhythm chart target times derived from same musical sequencer timeline;
- chart generation and music generation share seed but chart remains explicitly reproducible;
- music event schedule created before duel starts;
- authoritative clock berasal dari AudioServer/playback time.

Tidak boleh menggunakan frame delta sebagai beat authority.

## 175.11 FISHING MUSIC

Minimalist state.

Generator menggunakan:

- sparse Karplus plucks;
- soft two/three-note motifs;
- long quiet gaps;
- occasional warm triangle/sine pad;
- no constant melody.

Rule:

silence is valid music state.

## 175.12 MARKET RADIO FEEL

Bukan rekaman radio.

Synth recipe:

- band-limited noise sangat rendah;
- mono-ish narrow EQ feeling;
- simple generated melody/percussion pattern;
- occasional amplitude flutter;
- no copyrighted melody;
- no recognizable song reproduction.

## 175.13 AMBIENCE SYNTHESIS

### Water

Filtered noise + random low-frequency amplitude modulation + tiny droplet impulses.

### Wind

Pink-ish filtered noise dengan slow cutoff modulation.

### Birds

Procedural chirp phrases: sine frequency curves + envelope, randomized species-like patterns tetapi bukan sample imitation exact.

### Insects

Very quiet high-frequency pulse clusters.

### Distant motorcycle

Low oscillator + harmonics + doppler-like pitch/amplitude envelope; very occasional.

### Human distant ambience

Low-volume filtered formant-like murmur synth, intentionally unintelligible.

### Distant microphone joke

Jika event “test... one two...” dipertahankan, gunakan intentionally robotic/formant procedural syllable approximation yang sangat jauh dan jelas bersifat synthetic; tidak menggunakan recorded speech.

## 175.14 AMBIENT EVENT SCHEDULER

Setiap 15–35 sec during waiting:

- maximum one decorative event;
- no event within critical bite cue window jika akan menutupi cue;
- deterministic optional seed for reproducible debug;
- decorative RNG tidak mengubah fish probability.

## 175.15 CPU BUDGET

Target simultaneous synth voices:

- normal Fishing: 8–14;
- Market: 8–12;
- Duel: 12–22;
- hard cap default: 24 voices;
- decorative voices steal oldest lowest-priority voice terlebih dahulu.

SFX pendek dipre-render/cached in memory.

No synthesis allocation setiap audio sample frame.

## 175.16 WEB AUDIO UNLOCK

Browser dapat memblokir audio sebelum user gesture.

Rules:

- Main Menu dapat tampil dalam silent-ready state;
- first pointer/key interaction memanggil `request_web_audio_unlock()`;
- gameplay tidak memulai Dance duel sebelum audio ready;
- jika audio context suspend karena tab background, auto-pause gameplay;
- resume rhythm hanya setelah clock re-established; safest default restart current Dance duel countdown/chart rather than resuming at unknown timing offset.

## 175.17 AUDIO QA GATE

Automated repository scan gagal jika menemukan forbidden audio file extensions.

Test:

- all declared SFX IDs synthesize without error;
- no NaN/Inf sample;
- peak within safe limit;
- 20-minute Fishing audio has no runaway memory;
- Dance clock drift within acceptable target;
- Web unlock tested;
- Android suspend/resume tested.

---

# 176. PLAYABILITY & RUNTIME EDGE-CASE CONTRACT

Tujuan: game selalu terasa mudah dipahami, cepat merespons, tidak menjebak player, dan aman terhadap interruption khas Web/Android.

## 176.1 INPUT RESPONSIVENESS

- UI button response visual <=100 ms.
- Gameplay input diproses pada frame diterima, tidak menunggu animation completion kecuali rule mechanic membutuhkan.
- Context button tidak boleh mengganti action pada frame yang sama dengan tap lama sehingga input “menembus” ke state berikutnya.
- Setelah state transition, gunakan short input consume/debounce 80–150 ms bila perlu.

## 176.2 NO DEAD-END RULE

Player selalu dapat:

- kembali ke Fishing dari Result;
- kembali ke Main Menu dari Pause;
- memancing tanpa membeli bait;
- melanjutkan game walau cash 0;
- membayar debt kapan pun punya cash;
- menyelesaikan cerita tanpa Don Arowana.

## 176.3 TRANSITION TARGET

Scene transition target:

- Web/Desktop typical <2 sec setelah warm cache;
- Android mid-range typical <2.5 sec;
- jika lebih lama, tampilkan loading feedback.

Jangan freeze UI selama resource load berat.

## 176.4 FOCUS LOSS — WEB

Saat browser/tab kehilangan focus:

- auto-pause active gameplay;
- stop duel timer;
- stop input acceptance;
- pause/freeze AudioManager appropriately;
- show `PAUSED — CLICK TO CONTINUE` saat focus kembali;
- Dance duel restart dari short 3 sec countdown jika authoritative audio clock tidak dapat dipertahankan dengan aman.

## 176.5 ANDROID BACKGROUND / SUSPEND

Saat app masuk background:

1. pause gameplay;
2. request autosave;
3. pause procedural audio;
4. do not advance timers;
5. on resume validate scene/state;
6. show pause overlay before continuing.

Jika OS membunuh app setelah autosave, Continue harus mengembalikan persistent progression, bukan exact mid-duel state.

Mid-duel resume tidak wajib; duel boleh dianggap belum selesai dan restart duel dari awal dengan fish yang sama/seed yang sama bila app suspend sebelum result commit.

## 176.6 RESIZE / ORIENTATION

Web resize:

- UI relayout live;
- gameplay world camera reframes safely;
- no button outside viewport;
- Dance lanes maintain equal usable width.

Android production orientation tetap portrait.

## 176.7 PAUSE DURING STATE TRANSITION

Pause request diabaikan selama critical atomic transition <500 ms seperti result commit/save transaction; setelah atomic step selesai pause dibuka.

Player tidak boleh menghasilkan duplicate transaction melalui pause spam.

## 176.8 SAVE FAILURE

Jika save gagal:

- visible modal;
- `RETRY SAVE`;
- `CONTINUE WITHOUT SAVING` boleh tersedia kecuali saat import/migration risk;
- state runtime tidak reset;
- quit to menu warns if unsaved changes remain.

## 176.9 RAPID INPUT / DOUBLE TAP

Semua transaction buttons lock setelah accepted sampai response selesai.

Tidak boleh:

- double sell;
- double upgrade purchase;
- double debt payment;
- double scene route;
- two Wheel outcomes.

## 176.10 FIRST-TIME TUTORIAL SAFETY

- first fish scripted Catfish;
- first duel scripted Boxing;
- first duel loss grants retry tutorial;
- Market/debt tutorial cannot softlock;
- tutorial skip tidak menghilangkan required unlock.

## 176.11 DIFFICULTY COMFORT

Failure cost = time only.

No cash loss.

No upgrade loss.

No debt rollback.

No bucket wipe.

## 176.12 RHYTHM ACCESSIBILITY

- visual beat pulse always available;
- calibration offset `-200..+200 ms` recommended UI range;
- chart remains winnable at 30 FPS because judgment uses audio clock;
- touch target spans full lower lane region;
- no swipe requirement.

## 176.13 ARM WRESTLE COMFORT

10 accepted presses/sec hard cap.

Input above cap ignored without punishment.

No requirement to exceed comfortable tapping rate.

## 176.14 BOXING READABILITY

- every attack telegraph;
- direction cue includes pose/shape/motion, not color only;
- no off-screen attacks;
- camera composition keeps both combatants readable.

## 176.15 SUWIT FORGIVENESS

No input → `PANIC PICK!`, not hard fail.

Draw → replay round, no score dot.

## 176.16 MARKET FLOW

- Market entry immediately usable;
- default tab Sell;
- no walking/travel interaction required to reach Bu Yati;
- leaving Market always explicit;
- story event resolved at Market exit according to Section 177.

## 176.17 PERFORMANCE DEGRADATION

Jika FPS drop:

- decorative particles/vegetation reduce first;
- gameplay timing remains time-based;
- input/hit windows tidak berubah berdasarkan frame count;
- audio critical cue tetap priority.

---

# 177. STORY EVENT ARBITRATION — ONE EVENT PER MARKET VISIT

Ini adalah rule authoritative.

## 177.1 MARKET VISIT DEFINITION

Market visit dimulai saat transition `Fishing → Market` selesai.

Pada saat itu:

```text
story.market_visit_serial += 1
current_market_event_consumed = false
```

Pergantian tab tidak membuat visit baru.

Pause tidak membuat visit baru.

## 177.2 EVENT TRIGGERING

Saat debt payment, fish achievement, first Arowana win, atau state lain memenuhi trigger:

- `StoryDirector.evaluate_story_triggers()`;
- eligible event dimasukkan ke `pending_events` jika belum seen/pending;
- event tidak langsung memotong transaction UI.

## 177.3 DISPLAY MOMENT

Narrative event Market dipilih **ketika player menekan Leave Market**.

Flow:

```text
Leave Market
→ save pending transaction
→ evaluate triggers
→ resolve one highest-priority eligible event
→ if event exists: Story scene
→ event complete/skip
→ Fishing
```

Dengan demikian milestone yang tercapai di dalam Market visit yang sama dapat ikut diprioritaskan sebelum player kembali memancing.

## 177.4 MAXIMUM ONE EVENT

Tepat maksimum satu queued narrative event per Market visit.

Setelah satu event started:

`last_market_event_visit_serial = market_visit_serial`.

Event lain tetap pending untuk visit berikutnya kecuali superseded.

## 177.5 PRIORITY ORDER

Default priority:

| Event | Priority |
|---|---:|
| `story_debt_paid` | 1000 |
| `story_final_family` | handled as chained finale state, not second Market queue event |
| `story_arowana_first_win` | 800 |
| `story_debt_1650k` | 650 |
| `story_debt_1400k` | 600 |
| `story_debt_1000k` | 550 |
| `story_debt_600k` | 500 |
| `story_debt_300k` | 450 |
| `story_debt_100k` | 400 |

`story_first_market` adalah tutorial event dan terjadi pada first visit onboarding; setelah tutorial selesai, normal quota rules berlaku.

## 177.6 FINALE CHAIN EXCEPTION CLARIFICATION

`story_debt_paid` adalah satu event yang dipilih pada Market exit.

Setelah event itu selesai, game boleh langsung masuk finale flow `story_final_family` setelah required transition/credits setup karena keduanya dianggap **satu finale chain**, bukan dua independent queued Market events.

Lower-priority debt milestone yang belum tampil dan tidak lagi relevan setelah debt paid dapat di-mark `superseded` dan tidak diputar setelah ending.

## 177.7 SKIP

Setiap queued narrative event dapat di-skip dengan hold 0.8 sec.

Skip tetap:

- mark seen;
- apply unlock;
- save;
- remove event from pending;
- apply supersede list;
- route destination normal.

## 177.8 DETERMINISTIC TIEBREAK

Jika priority sama:

1. event dengan trigger threshold lebih rendah/lebih lama pending lebih dulu;
2. lalu lexical `event_id` ascending sebagai final deterministic tiebreak.

## 177.9 QUEUE SAFETY

Queue tidak boleh:

- memiliki duplicate ID;
- memutar seen event lagi kecuali explicitly repeatable;
- memutar event dengan prerequisite belum seen;
- memutar narrative setelah ending jika event sudah obsolete;
- menampilkan dua event independent dalam satu Market visit.


---

# 178. DEBUG / DEV MODE

Debug tools hanya aktif pada debug/development build. Release build tidak boleh membuka mutation tools walaupun player menemukan gesture/key tersembunyi.

## 178.1 ACCESS

Desktop/Web debug build:

`F10` toggle Debug Overlay.

Android debug build:

tap build/version label 5× dalam 3 sec.

Release:

- F10 ignored;
- version multi-tap ignored;
- `DebugService.is_debug_tools_allowed()` false.

## 178.2 DEBUG OVERLAY TABS

### STATE

- cash set/add;
- debt remaining set;
- family savings set;
- upgrade level per ID;
- bucket quantity per item;
- story flags;
- tutorial flags;
- play time.

### FISHING

- force fish;
- force trash;
- force next strike success/fail;
- force line break;
- force BIG ONE;
- set wait time 0.5 sec debug override;
- show internal marker/green-zone values;
- show landing/stress numeric values.

### WHEEL / DUEL

- force duel type;
- force player win/loss;
- force exact fish attack direction;
- force perfect dodge window visualization;
- set arm position/stamina;
- show Dance song time / note time / offset;
- force Suwit choice/tell truth/lie.

### STORY

- list pending events;
- trigger event;
- mark seen/unseen;
- clear event queue;
- simulate Market visit serial;
- jump to finale;
- reset story only without resetting economy, with warning.

### RNG

Display:

- save seed;
- session seed;
- encounter counter;
- duel counter;
- current encounter seed;
- fish roll;
- trash roll;
- Wheel result;
- dialogue cosmetic seed.

Actions:

- set seed;
- copy seed text;
- replay previous encounter seed.

### PERFORMANCE

Display:

- FPS;
- frame time;
- process time;
- draw calls if available;
- visible object count;
- approximate memory;
- procedural audio voice count;
- audio underrun counter;
- active particles;
- current quality preset.

### PLATFORM/UI

- simulate 1280×720;
- 1920×1080;
- 720×1280;
- 1080×2400;
- narrow Web portrait;
- safe-area inset presets;
- mouse mode;
- touch mode;
- Web focus lost simulation.

## 178.3 DEBUG CHEATS MUST NOT SAVE BY DEFAULT

Forced fish/duel/result bersifat runtime override dan tidak disimpan.

Mutation state seperti cash/debt dari Debug Overlay:

- default `DEV DIRTY STATE` indicator;
- save hanya jika tester menekan explicit `SAVE DEBUG STATE`;
- automated test dapat membuat isolated temp save.

## 178.4 LOGGING

Debug log format:

```text
[TIME][SYSTEM][LEVEL] message key=value
```

Contoh:

```text
[12.422][FISHING][INFO] encounter fish=catfish_bruiser seed=918221 roll=0.1832
```

Release logging minimal dan tidak spam console setiap frame.

## 178.5 REPRO PACKAGE

Debug menu menyediakan `COPY REPRO STATE` menghasilkan text block:

```text
build_version
engine_version
platform
scene
save_seed
encounter_counter
duel_counter
fish_id
duel_id
quality
viewport
```

Tidak menyertakan data pribadi karena game tidak mengumpulkan akun/data personal.

---

# 179. BALANCING SIMULATION TARGETS

Tujuan simulasi bukan mengganti feel test, tetapi mendeteksi ekonomi rusak, RNG salah, atau progression terlalu pendek/panjang.

## 179.1 REQUIRED MONTE CARLO RUNS

Automated simulation minimum:

- 100,000 successful encounter rolls untuk distribution;
- 100,000 trash subtype rolls;
- 100,000 Wheel rolls;
- 25,000 simulated sessions per skill profile;
- 10,000 full progression economy runs per upgrade strategy.

Gunakan deterministic seed range agar hasil reproducible.

## 179.2 DISTRIBUTION TARGET

Expected per successful encounter:

| Result | Expected |
|---|---:|
| Trash | 16.00% |
| Bruiser Catfish | 25.20% |
| Gym-Rat Tilapia | 20.16% |
| Shady Gourami | 16.80% |
| Golden Carp | 11.76% |
| Snakehead Sergeant | 7.56% |
| Don Arowana | 2.52% |

100k-run acceptance guideline:

- common outcomes within ±0.50 percentage point;
- Arowana within ±0.20 percentage point;
- sum exactly ~100% within floating rounding.

Trash subtype within trash pool:

45/40/15% with ±0.75 percentage point tolerance pada 100k trash rolls.

Wheel each mode:

25% ±0.50 percentage point pada 100k rolls.

## 179.3 HUMAN SKILL PROFILES

Simulator memakai abstract win chance target, bukan mencoba meniru frame-perfect input.

### NOVICE

- early fish duel win: 62–70%;
- mid: 50–60%;
- Snakehead: 40–50%;
- Arowana base: 35–45%.

### AVERAGE TARGET PLAYER

- early: 72–80%;
- mid: 62–70%;
- Snakehead: 55–63%;
- Arowana base: 45–60%;
- Arowana relevant Lv3: 65–75%.

### SKILLED

- early: 88–95%;
- mid: 80–90%;
- Snakehead: 72–82%;
- Arowana base: 65–75%.

Upgrade harus memperbaiki win/efficiency secara nyata tetapi tidak membuat seluruh game auto-win.

## 179.4 ECONOMY TARGETS

Target median gross earning rate untuk average player, termasuk failure dan trash:

- Early: Rp180k–Rp260k per active gameplay hour;
- Mid: Rp240k–Rp360k/hour;
- Late: Rp300k–Rp450k/hour.

Ini guideline, bukan guaranteed payout.

Target full debt payoff untuk average player:

**sekitar 5–8 jam total playtime**, tergantung prioritas upgrade dan skill.

Completionist yang membeli banyak/all upgrade sebelum debt selesai:

**sekitar 7–11 jam**.

Skilled lucky player tidak seharusnya secara konsisten menyelesaikan story <3.5 jam.

Novice player tidak seharusnya median >12 jam hanya untuk melunasi debt.

## 179.5 MILESTONE PACING TARGET

Average player guideline:

| Lifetime Debt Paid | Expected cumulative playtime |
|---|---|
| 100k | 15–35 min |
| 300k | 45–90 min |
| 600k | 1.5–2.7 h |
| 1,000k | 2.7–4.3 h |
| 1,400k | 3.7–5.8 h |
| 1,650k | 4.5–7.0 h |
| 1,800k | 5.0–8.0 h |

Karena player boleh membeli upgrade, debt pacing tidak linear.

## 179.6 AROWANA TARGET

Arowana probability 2.52% per successful encounter berarti rare tetapi terlihat selama long play.

Target:

- tidak mandatory;
- satu Arowana tidak boleh menyelesaikan debt sendirian;
- Rp300k effective value tetap significant;
- simulator harus membuktikan debt completion remains practical pada run yang tidak pernah memenangkan Arowana.

Required test:

10,000 progression runs dengan Arowana reward forced to zero; median debt completion tetap <=9.5 h untuk average profile.

## 179.7 UPGRADE ROI TARGET

- Bait harus terasa pada waiting cadence tanpa membuat waiting hilang total.
- Rod harus meningkatkan reel success secara nyata.
- Tonic harus meningkatkan survivability/stamina tetapi tidak mandatory.
- Coffee harus membantu readability rhythm tanpa mengubah beat.
- Charm harus memberi information advantage, bukan auto-win.

Target payback feel:

upgrade Lv1 seharusnya terasa bermanfaat dalam 1–3 normal sessions setelah dibeli.

## 179.8 SESSION TARGET

Ideal 10–25 min session:

- 4–10 encounters;
- 1–2 Market visits;
- maksimal 1 narrative event per Market visit;
- minimal satu meaningful progress moment: catch, upgrade, sale, debt payment, record, atau story.

## 179.9 BALANCE CHANGE RULE

Jika simulasi keluar target:

1. periksa bug lebih dulu;
2. jangan langsung mengubah semua harga;
3. ubah satu family parameter per tuning pass;
4. simpan hasil before/after;
5. perubahan angka authoritative harus dicatat pada GDD changelog.

---

# 180. FULL QA TEST MATRIX

Legend:

- P0 = release blocker/crash/data loss/core progression broken.
- P1 = major gameplay/UX defect.
- P2 = polish/minor issue.
- AUTO = automated/headless where feasible.
- MAN = manual/device validation.

## 180.1 BOOT / PROJECT / DATA

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| BOOT-001 | P0 | AUTO | Boot with all resources valid | reaches Main Menu |
| BOOT-002 | P0 | AUTO | Missing FishData | validation fails clearly in debug/test |
| BOOT-003 | P0 | AUTO | duplicate fish ID | validation fails |
| BOOT-004 | P0 | AUTO | invalid upgrade price array | validation fails |
| BOOT-005 | P1 | MAN | first Web load | visible loading, no frozen canvas |
| BOOT-006 | P1 | MAN | Android cold start | menu usable, portrait safe area correct |

## 180.2 SAVE / LOAD

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| SAVE-001 | P0 | AUTO | fresh new game | v5 schema created |
| SAVE-002 | P0 | AUTO | save then load | state exact |
| SAVE-003 | P0 | AUTO | corrupt JSON | backup + recovery UI path |
| SAVE-004 | P0 | AUTO | negative cash input | clamped/rejected |
| SAVE-005 | P0 | AUTO | debt invariant broken | repaired if recoverable |
| SAVE-006 | P0 | AUTO | upgrade >3 | clamp 3 |
| SAVE-007 | P0 | AUTO | unknown pending story ID | removed safely |
| SAVE-008 | P0 | AUTO | atomic save interruption simulation | previous valid save retained where platform supports |
| SAVE-009 | P1 | AUTO | settings autosave | reload preserves |
| SAVE-010 | P1 | MAN | Web browser storage clear warning documentation | user informed in UI/help |
| SAVE-011 | P1 | MAN | Android background autosave | progression persists |
| SAVE-012 | P0 | AUTO | no debt below zero | invariant passes all transaction cases |

## 180.3 FISHING

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| FISH-001 | P0 | MAN | cast input | rod sequence correct |
| FISH-002 | P0 | AUTO/MAN | release marker timing | float releases at 0.48 sec |
| FISH-003 | P1 | MAN | rod settle | points toward lake, not vertical |
| FISH-004 | P0 | AUTO | wait time Lv0 | within 4.5–9.5 sec |
| FISH-005 | P0 | AUTO | bait Lv3 | formula + min clamp valid |
| FISH-006 | P1 | MAN | false nibble | no reaction bar |
| FISH-007 | P1 | MAN | false strike | 0.8 sec light penalty only |
| FISH-008 | P0 | AUTO | strike windows all fish | config exact |
| FISH-009 | P0 | AUTO | late strike | fish escapes, no duel |
| FISH-010 | P0 | AUTO | trash success | bucket direct, no Wheel |
| FISH-011 | P0 | AUTO | encounter distribution | tolerance Section 179 |
| FISH-012 | P0 | AUTO | line stress >=100 | line break |
| FISH-013 | P0 | AUTO | landing >=100 | fish landed exactly once |
| FISH-014 | P1 | MAN | stress HUD | shake tiers correct; camera stable |
| FISH-015 | P1 | MAN | HUD shake OFF | no HUD shake |
| FISH-016 | P0 | AUTO | Carbon Rod width clamp | <=0.245 |

## 180.4 WHEEL

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| WHEEL-001 | P0 | AUTO | 100k outcomes | 25/25/25/25 within tolerance |
| WHEEL-002 | P0 | AUTO | FPS variance | chosen outcome unchanged |
| WHEEL-003 | P1 | MAN | first viewing | cannot accidentally skip immediately |
| WHEEL-004 | P1 | MAN | later hold skip 0.6s | reveal still shown |
| WHEEL-005 | P0 | AUTO | first tutorial | forced Boxing |

## 180.5 BOXING

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| BOX-001 | P0 | AUTO | player base HP | 100 |
| BOX-002 | P0 | AUTO | Tonic Lv1–3 HP | 125/150/175 |
| BOX-003 | P0 | AUTO | jab/cross values | exact config |
| BOX-004 | P0 | AUTO/MAN | attack telegraph | every attack readable |
| BOX-005 | P0 | AUTO | correct dodge | counter opens |
| BOX-006 | P0 | AUTO | wrong dodge | hit applied |
| BOX-007 | P0 | AUTO | perfect window | final 180ms |
| BOX-008 | P0 | AUTO | perfect multiplier | 2.4× |
| BOX-009 | P0 | AUTO | normal multiplier | 2.0× |
| BOX-010 | P0 | AUTO | blocked damage | 40% |
| BOX-011 | P0 | AUTO | timeout | HP percentage comparator |
| BOX-012 | P0 | AUTO | exact tie | sudden death |
| BOX-013 | P1 | MAN | mobile layout | four controls non-overlap |
| BOX-014 | P1 | MAN | no color-only telegraph | shape/motion readable |

## 180.6 ARM WRESTLING

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| ARM-001 | P0 | AUTO | initial position | 0 |
| ARM-002 | P0 | AUTO | accepted press | +impulse, -7 stamina |
| ARM-003 | P0 | AUTO | >10 press/sec | excess ignored |
| ARM-004 | P0 | AUTO | regen delay | 0.35 sec |
| ARM-005 | P0 | AUTO | regen rate | 26/sec |
| ARM-006 | P0 | AUTO | Tonic stamina | 100/120/140/160 |
| ARM-007 | P0 | AUTO | low stamina power bands | exact Section 53 |
| ARM-008 | P1 | MAN | burst telegraph | visible before burst |
| ARM-009 | P0 | AUTO | 32 sec timeout | position rule correct |
| ARM-010 | P0 | AUTO | near-zero timeout | Sudden Grip |
| ARM-011 | P0 | AUTO | exact boss zero | 10 sec rematch |
| ARM-012 | P1 | MAN | mobile mash comfort | large target, no missed zone issue |

## 180.7 DANCE

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| DANCE-001 | P0 | AUTO | BPM generation | 132–156 |
| DANCE-002 | P0 | AUTO | duration | 36–44 sec |
| DANCE-003 | P0 | AUTO | same seed | same chart/music schedule |
| DANCE-004 | P0 | AUTO | PERFECT | ±55ms |
| DANCE-005 | P0 | AUTO | GREAT | ±100ms |
| DANCE-006 | P0 | AUTO | GOOD | ±175ms |
| DANCE-007 | P0 | AUTO | combo bonus | +10%/10, max +50% |
| DANCE-008 | P0 | AUTO | Coffee | visual speed only |
| DANCE-009 | P0 | AUTO | audio clock | judgment independent from render FPS |
| DANCE-010 | P0 | AUTO | fish performance seed | reproducible note-by-note |
| DANCE-011 | P0 | AUTO | equal score tie | perfect → combo → encore |
| DANCE-012 | P1 | MAN | Android touch lanes | equal, readable, comfortable |
| DANCE-013 | P1 | MAN | 30 FPS device | chart remains playable |
| DANCE-014 | P0 | MAN | Web tab focus loss | auto-pause/restart safe |

## 180.8 SUWIT

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| SUWIT-001 | P0 | AUTO | first-to-two | correct |
| SUWIT-002 | P0 | AUTO | draw | no dot, repeat |
| SUWIT-003 | P0 | AUTO | hidden choice time | before tell |
| SUWIT-004 | P0 | AUTO | truth probability | FishData value |
| SUWIT-005 | P0 | AUTO | no input | panic random pick |
| SUWIT-006 | P0 | AUTO | Charm charges | 0/1/2/3 |
| SUWIT-007 | P0 | AUTO | Charm reveal | actual move, 0.8 sec |
| SUWIT-008 | P0 | AUTO | next duel | charges reset |
| SUWIT-009 | P1 | MAN | mobile choice buttons | no accidental adjacent tap |

## 180.9 MARKET / ECONOMY

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| MKT-001 | P0 | AUTO | fish sale values | exact |
| MKT-002 | P0 | AUTO | Arowana sale | 240k×1.25=300k |
| MKT-003 | P0 | AUTO | trash sale values | exact |
| MKT-004 | P0 | AUTO | Sell All | bucket decremented, cash correct |
| MKT-005 | P0 | AUTO | category sell | only category removed |
| MKT-006 | P0 | AUTO | insufficient upgrade cash | purchase blocked |
| MKT-007 | P0 | AUTO | all upgrade prices | exact |
| MKT-008 | P0 | AUTO | max Lv3 | no Lv4 |
| MKT-009 | P0 | AUTO | debt payment >cash | clamped/blocked as UI contract |
| MKT-010 | P0 | AUTO | debt payment >remaining | cannot overpay |
| MKT-011 | P0 | AUTO | transaction double click | no duplicate mutation |
| MKT-012 | P1 | MAN | receipt feedback | readable, cozy, no casino effect |

## 180.10 STORY / EVENT ARBITRATION

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| STORY-001 | P0 | AUTO | milestone trigger | pending once |
| STORY-002 | P0 | AUTO | same event trigger twice | no duplicate |
| STORY-003 | P0 | AUTO | one Market visit | <=1 independent queued event |
| STORY-004 | P0 | AUTO | two thresholds crossed | higher priority one shown, other pending |
| STORY-005 | P0 | AUTO | debt paid | finale priority |
| STORY-006 | P0 | AUTO | ending supersede | obsolete milestones removed |
| STORY-007 | P0 | AUTO | skip event | state/unlock/seen preserved |
| STORY-008 | P0 | AUTO | skip finale event | deterministic finale chain |
| STORY-009 | P1 | MAN | dialogue language | English only |
| STORY-010 | P1 | MAN | comedy pause | not rushed |
| STORY-011 | P0 | AUTO | debt completion without Arowana | possible |
| STORY-012 | P0 | AUTO | postgame unlock | Free Fishing + Family Savings |

## 180.11 FISH BOOK / RECORDS

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| BOOK-001 | P0 | AUTO | before unlock | hidden/locked appropriately |
| BOOK-002 | P0 | AUTO | first defeat fish | entry discovered |
| BOOK-003 | P0 | AUTO | best weight | only increases on higher value |
| BOOK-004 | P1 | AUTO | BIG ONE | 5% rule/90th percentile criterion valid |
| BOOK-005 | P0 | AUTO | record counters | exact increments |
| BOOK-006 | P1 | MAN | silhouette state | no accidental portrait leak |

## 180.12 UI / ACCESSIBILITY

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| UI-001 | P0 | MAN | 1280×720 | no overlap/crop |
| UI-002 | P0 | MAN | 1920×1080 | anchors scale correctly |
| UI-003 | P0 | MAN | 720×1280 | portrait usable |
| UI-004 | P0 | MAN | 1080×2400 | safe area usable |
| UI-005 | P0 | MAN | notch simulation | controls inside safe rect |
| UI-006 | P1 | MAN | min touch target | >=48 logical px |
| UI-007 | P1 | MAN | no color-only critical cue | pass |
| UI-008 | P1 | MAN | reduced flash | effect reduced |
| UI-009 | P1 | MAN | HUD shake off/reduced | honored |
| UI-010 | P1 | MAN | dialog wrap | no clipping |
| UI-011 | P1 | MAN | disabled controls | readable + non-interactive |
| UI-012 | P1 | MAN | live Web resize | relayout no offscreen controls |

## 180.13 PROCEDURAL AUDIO

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| AUD-001 | P0 | AUTO | scan forbidden audio extension | zero matches |
| AUD-002 | P0 | AUTO | all SFX IDs | synthesize successfully |
| AUD-003 | P0 | AUTO | sample validity | no NaN/Inf |
| AUD-004 | P0 | AUTO | peak safety | no uncontrolled clipping |
| AUD-005 | P0 | MAN | bite cue under ambience | clearly audible |
| AUD-006 | P1 | MAN | UI sounds | warm/non-fatiguing |
| AUD-007 | P1 | MAN | Fishing 20 min | no obvious tiny-loop repetition |
| AUD-008 | P0 | MAN | Web first gesture | audio unlocks |
| AUD-009 | P0 | MAN | Web focus suspend/resume | no broken clock |
| AUD-010 | P0 | MAN | Android background/resume | safe |
| AUD-011 | P0 | AUTO/MAN | Dance same seed | same schedule |
| AUD-012 | P1 | MAN | voice count cap | graceful stealing, no collapse |

## 180.14 PERFORMANCE

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| PERF-001 | P1 | MAN | Web modern iGPU | target ~60 FPS |
| PERF-002 | P0 | MAN | Web minimum | stable >=30 FPS acceptable |
| PERF-003 | P1 | MAN | Android mid-range | target ~60 FPS |
| PERF-004 | P0 | MAN | Android sustained 30 min | no thermal/perf collapse below acceptable |
| PERF-005 | P1 | MAN | worst particles | no gameplay timing break |
| PERF-006 | P1 | MAN | long Web session | no runaway memory |
| PERF-007 | P1 | MAN | Low preset | meaningful load reduction |
| PERF-008 | P1 | MAN | scene transition | target loading budget |

## 180.15 PLATFORM / EXPORT

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| WEB-001 | P0 | MAN | Chromium export smoke | pass |
| WEB-002 | P0 | MAN | Firefox export smoke | pass |
| WEB-003 | P1 | MAN | Safari/WebKit if available | compatibility pass/report |
| WEB-004 | P0 | MAN | itch ZIP | `index.html` root |
| WEB-005 | P0 | MAN | keyboard browser actions | no unwanted scroll/navigation during gameplay |
| AND-001 | P0 | MAN | release export | `.aab` generated |
| AND-002 | P0 | MAN | portrait | locked/correct |
| AND-003 | P0 | MAN | Android Back gameplay | pause/confirmation |
| AND-004 | P0 | MAN | Android Back child menu | one level back |
| AND-005 | P0 | MAN | permissions | only minimal required |
| AND-006 | P0 | MAN | physical mid/low device | smoke pass |
| AND-007 | P1 | MAN | modern physical device | smoke pass |

## 180.16 CONTENT / RELEASE HYGIENE

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| REL-001 | P0 | AUTO | missing resource scan | zero |
| REL-002 | P0 | AUTO | TODO/FIXME release scan | zero unresolved |
| REL-003 | P0 | AUTO | Indonesian visible placeholder scan | zero intended player copy |
| REL-004 | P0 | AUTO | real brand/logo asset check manifest | none |
| REL-005 | P0 | AUTO/MAN | content manifest count | exact roster/content |
| REL-006 | P1 | MAN | Credits | readable |
| REL-007 | P0 | AUTO | debug mutation release build | unavailable |
| REL-008 | P0 | AUTO | all tests | P0 pass |

## 180.17 V6 PRODUCTION / STORE / PRIVACY / REPOSITORY TESTS

| ID | P | Type | Test | Expected |
|---|---|---|---|---|
| GEN-001 | P0 | AUTO | generator clean run | all required outputs generated without network |
| GEN-002 | P0 | AUTO | generator provenance manifest | every generated production asset mapped to source generator |
| GEN-003 | P0 | AUTO | external visual/audio asset scan | zero unauthorized production assets |
| GEN-004 | P0 | AUTO | regenerate twice same seed | equivalent manifest/output structure |
| GEN-005 | P1 | MAN | hero primitive-look review | no hero reads as placeholder |
| VIS-001 | P0 | MAN | all Section 185 reference sheets | generated and approved against spec |
| VIS-002 | P1 | MAN | six fish silhouettes | distinct at small read size |
| NAR-001 | P0 | AUTO | Section 183 key coverage | every mandatory story event has final copy |
| NAR-002 | P0 | AUTO | placeholder dialogue scan | zero runtime placeholder |
| NAR-003 | P1 | MAN | full story tone pass | warm/understated/no gambling glamorization |
| STORE-001 | P0 | MAN | target SDK release check | current Google Play requirement satisfied |
| STORE-002 | P0 | AUTO/MAN | generated Play icon | correct current dimensions/format |
| STORE-003 | P0 | AUTO/MAN | generated feature graphic | correct current dimensions/format |
| STORE-004 | P0 | MAN | screenshot set | truthful gameplay + current store requirements |
| STORE-005 | P0 | MAN | publisher metadata | no placeholder required field |
| PRIV-001 | P0 | AUTO/MAN | network/SDK audit | no analytics/ad/tracking/backend endpoint |
| PRIV-002 | P0 | MAN | privacy policy in-app | accessible offline summary/full text path |
| PRIV-003 | P0 | MAN | Play Data Safety | completed and consistent with binary/policy |
| PRIV-004 | P0 | MAN | public privacy URL | valid HTTPS page for Play submission |
| RATE-001 | P0 | MAN | content disclosure build audit | matches Section 188 |
| RATE-002 | P0 | MAN | IARC questionnaire | completed truthfully, result recorded |
| A11Y-013 | P0 | MAN | 150% text + portrait | critical flow fully usable |
| A11Y-014 | P0 | AUTO/MAN | remap persistence | custom keyboard binding survives reload |
| A11Y-015 | P0 | MAN | Hold Assist | all Arm tiers remain playable |
| PKG-001 | P0 | AUTO | Web ZIP budget | Section 190 budget pass or documented approved exception |
| PKG-002 | P0 | AUTO | itch official hard limits | pass current limits at release |
| PKG-003 | P0 | AUTO | Android AAB budget | Section 190 budget pass or investigated exception |
| MEM-001 | P0 | MAN | repeated scene cycle memory | no runaway leak |
| REPO-001 | P0 | AUTO/MAN | secret scan | zero signing/API secret committed |
| REPO-002 | P0 | MAN | milestone tag/release tag | follows Section 191 |
| REPO-003 | P0 | AUTO | clean checkout build | run/tests/export path works |
| PLAY-001 | P0 | MAN | human playtest minimum | Section 192 participant/platform thresholds met |
| PLAY-002 | P0 | MAN | first-12-minute comprehension | >=90% core-loop comprehension |
| PLAY-003 | P0 | MAN | tutorial usability | >=80% no-intervention success |
| BUG-001 | P0 | MAN | release triage | zero BLOCKER/P0 and zero known P1 core |
| RC-001 | P0 | MAN | content freeze | post-RC changes follow Section 194 |
| RC-002 | P0 | MAN | Gold Master status | exact source commit/artifacts approved |
| RELCHK-001 | P0 | MAN | master release checklist | all critical Section 195 items checked |
| PROV-001 | P0 | AUTO/MAN | build provenance | build/release/generator manifests complete |
| PROV-002 | P0 | AUTO | release checksums | SHA-256 recorded for final artifacts |
| PROV-003 | P0 | AUTO/MAN | clean rebuild traceability | no hidden local production dependency |

## 180.18 RELEASE RULE

v1.0 tidak boleh dirilis jika ada:

- P0 open;
- data loss known issue;
- broken story progression;
- missing required asset;
- missing required platform build;
- persistent crash;
- procedural audio failing critical cue;
- release debug cheat active;
- unauthorized external production asset;
- privacy/Data Safety mismatch;
- incomplete content-rating questionnaire;
- failed programmatic asset provenance;
- Section 190 hard platform limit violation;
- publisher/store required metadata placeholder;
- human playtest gate Section 192 belum lulus;
- BLOCKER/P0 atau P1 core menurut Section 193;
- Gold Master belum disetujui menurut Section 194;
- critical Master Release Checklist item Section 195 belum checked;
- build/release provenance Section 196 incomplete.

P1 hanya boleh ditunda jika benar-benar non-blocking dan dicatat, tetapi target v1.0 adalah **zero known P1 pada core loop**.

---

# 181. DEVELOPMENT ROADMAP — 10 MILESTONES TO V1.0

Prinsip:

- kerjakan satu milestone per prompt/work session;
- jangan implement milestone berikutnya sebelum exit gate milestone aktif lulus;
- setiap milestone harus menghasilkan project yang bootable;
- token/context diarahkan ke implementasi aktif, bukan seluruh game sekaligus.

## MILESTONE 1 — FOUNDATION, DATA, SAVE, INPUT, DEBUG SHELL

Target:

- Godot project baseline;
- Compatibility renderer;
- folder structure final;
- `tools/generators/` architecture + generator manifest skeleton;
- zero-internet-asset validation shell;
- InputMap;
- autoloads;
- Resource classes/schemas;
- all authoritative fish/upgrade/balance data;
- Save v5 create/load/validate/autosave foundation;
- SceneRouter;
- procedural AudioManager skeleton + critical UI click generation;
- DebugService + basic overlay;
- Boot validation;
- Main Menu functional skeleton.

Exit gate:

- project boots;
- New Game creates valid save;
- Continue reloads state;
- tests BOOT/SAVE foundation pass;
- no parser errors.

## MILESTONE 2 — FISHING VERTICAL SLICE

Target:

- LakeSet playable composition;
- Darto/rod/float integration;
- cast timing;
- wait/nibble/bite/strike;
- encounter roll;
- reel system;
- stress/landing;
- trash direct bucket;
- fish land routing;
- fishing HUD responsive;
- code-generated fishing SFX/ambience baseline;
- programmatically generated LakeSet/Darto/rod/float baseline;
- all six fish generator profiles may be integrated progressively, but Bruiser Catfish final-quality + reference render required.

Exit gate:

- full cast→land/escape loop works;
- all FISH P0 tests pass;
- desktop + portrait HUD usable.

## MILESTONE 3 — MARKET, ECONOMY, UPGRADES, BOOK, RECORDS

Target:

- Market set/UI;
- Sell All/category sell;
- all prices;
- five upgrade families;
- Debt Ledger;
- Fish Book data/UI;
- Records;
- transaction autosave;
- market procedural ambience/UI audio;
- basic story trigger queue without final cutscenes.

Exit gate:

- fish can become cash only via sale;
- upgrade/debt math exact;
- Market P0 tests pass;
- save/reload preserves everything.

## MILESTONE 4 — BOXING COMPLETE

Target:

- Boxing scene;
- all controls Web/Android;
- telegraph system;
- dodge/perfect dodge;
- jab/cross/block;
- HP/upgrades;
- timeout/sudden death;
- fish boxing animation contract;
- procedural boxing SFX;
- all six fish stats active.

Exit gate:

- Catfish through Arowana can complete Boxing;
- BOX P0 tests pass;
- no unreadable attack.

## MILESTONE 5 — ARM WRESTLING COMPLETE

Target:

- position force system;
- mash rate cap;
- stamina/power bands;
- regen;
- fish constant pressure/burst;
- timeout/Sudden Grip;
- mobile large mash control;
- procedural arm audio.

Exit gate:

- ARM P0 pass;
- 32 sec round deterministic;
- comfortable mobile input verified.

## MILESTONE 6 — DANCE + PROCEDURAL MUSIC ENGINE

Target:

- full procedural synth/sequencer architecture;
- deterministic koplo track;
- deterministic chart;
- authoritative audio clock;
- 4 lanes;
- judgments;
- combo/scoring;
- fish rhythm AI;
- Coffee modifier;
- calibration setting;
- Web audio unlock/focus safety.

Exit gate:

- same seed reproduces track schedule/chart;
- DANCE/AUD critical tests pass;
- 30/60 FPS timing remains correct.

## MILESTONE 7 — SUWIT, WHEEL, FULL FISH PERSONALITY CONTENT

Target:

- production Wheel;
- Suwit full rules;
- tell truth/lie;
- Charm;
- panic pick;
- all fish dialogue Section 166;
- fish Fish Book descriptions;
- full fish animation/personality pass;
- Result scene;
- encounter→Wheel→all four duel→Result→Fishing complete.

Exit gate:

- every fish works in every duel;
- WHEEL/SUWIT P0 pass;
- no missing dialogue key.

## MILESTONE 8 — NARRATIVE, CUTSCENES, EVENT ARBITRATION, ENDING

Target:

- Story scene/timeline system;
- prologue;
- first fish/Market scenes;
- all debt milestone scenes using exact Section 183 final copy;
- all Rini/Nisa/Bu Yati/CePatCash narrative copy Section 183;
- Fish Book/How To/tutorial/error narrative copy coverage;
- one-event-per-Market-visit arbitration;
- skip logic;
- Rini/Nisa/Bu Yati content;
- Don Arowana first win scene;
- debt-paid finale;
- final family scene;
- credits;
- post-game Free Fishing;
- Family Savings;
- post-ending Main Menu variation.

Exit gate:

- start-to-ending story can be completed;
- STORY/NAR P0 pass;
- zero placeholder narrative key;
- debt can complete without Arowana.

## MILESTONE 9 — FINAL ART, UI/UX, ANIMATION, AUDIO, ACCESSIBILITY, PERFORMANCE

Target:

- complete programmatic generator implementation Section 184;
- all final human/fish/vehicle/prop/environment generated assets;
- no hero placeholders;
- complete provenance manifest;
- final reference-sheet renders Section 185;
- UI Theme + all procedural icons final;
- all responsive states;
- final programmatic animation clips;
- full procedural ambience/music/SFX library;
- Low/Medium/High graphics;
- Accessibility Bible 2.0 Section 189 complete;
- safe area + left-handed/mobile variants;
- optimization;
- memory/resource pass;
- Section 190 performance budget profiling baseline;
- visual Sunday-afternoon polish.

Exit gate:

- no missing required generated asset;
- GEN/VIS/UI/AUD/A11Y/PERF major tests pass;
- all reference sheets generated and visually locked;
- visual direction consistent;
- zero unauthorized external production asset;
- no forbidden audio files.

## MILESTONE 10 — BALANCE, FULL QA, RELEASE CANDIDATE & GOLD MASTER

Target:

- all simulations Section 179;
- fix outliers/bugs;
- full QA matrix;
- regression all systems;
- current store requirement re-check + `docs/store_compliance_report.md`;
- Web build;
- itch.io ZIP + official-limit scan;
- Android target SDK current requirement + AAB/export readiness;
- physical Android smoke tests;
- browser smoke tests;
- release hygiene scan;
- docs;
- credits/licenses;
- Section 186 store identity + generated store art + final listing copy;
- Section 187 privacy policy/Data Safety completion;
- Section 188 IARC/content-rating questionnaire completion;
- accessibility full pass;
- hard performance/package budget pass;
- repository/release hygiene;
- Section 192 human playtest protocol + report;
- Section 193 final bug triage;
- RC1/content freeze process Section 194;
- Section 195 master release checklist;
- Section 196 build provenance/checksum manifests;
- Gold Master candidate archive;
- final delivery package.

Exit gate:

- all P0 pass;
- zero known P1 core-loop defect target;
- export smoke pass;
- Definition of Done Section 182 + V6 Final Production Gate Section 191.17 satisfied; kemudian jalankan Sections 192–196 untuk Gold Master approval.

## 181.1 MILESTONE PROMPTING RULE

Saat AI diminta “kerjakan Milestone N”:

- gunakan seluruh GDD sebagai context;
- fokus hanya scope milestone N;
- boleh memperbaiki dependency milestone sebelumnya;
- dilarang mengimplement milestone N+1 secara penuh;
- akhir pengerjaan wajib memberi daftar file changed, test run, known issue, dan next gate;
- known issue P0 harus dibereskan sebelum milestone dinyatakan selesai.

---

# 182. FINAL DELIVERY CONTRACT — DEFINITION OF DONE V1.0

Project hanya boleh disebut **Mancing Mania: Gelut Edition v1.0 complete** jika seluruh contract berikut terpenuhi.

## 182.1 SOURCE PROJECT

Deliverable harus memiliki:

- complete Godot project;
- `project.godot`;
- all `.tscn` required;
- all typed `.gd` required;
- all `.tres` data/resources;
- all final programmatically-generated 3D/UI assets;
- generator source + manifest;
- shaders/materials;
- tests;
- export presets;
- no broken path;
- no external runtime dependency selain Godot/Web browser/Android platform.

## 182.2 BUILDABLE FROM CLEAN CHECKOUT/FOLDER

Developer harus dapat:

1. membuka project di supported Godot stable;
2. run Main Scene;
3. menjalankan tests;
4. export Web;
5. export Android setelah signing configuration tersedia.

Tidak boleh membutuhkan asset yang hanya ada di machine pembuat.

## 182.3 REQUIRED DOCUMENTATION

```text
README.md
README_BUILD.md
README_TESTING.md
CHANGELOG.md
LICENSES.md
docs/implementation_decisions.md
docs/qa_release_report.md
docs/balance_simulation_report.md
docs/performance_report.md
docs/store_compliance_report.md
docs/balance_changes.md
PRIVACY_POLICY.md
```

README menyebut:

- supported Godot version;
- how to run;
- how to test;
- how to export;
- Android signing prerequisite;
- itch.io packaging steps;
- asset regeneration command;
- privacy/store compliance manual submission steps.

## 182.4 WEB DELIVERABLE

Required:

`build/web/` export output.

Required archive:

`build/release/mancing-mania-gelut-edition-web-v1.0.zip`

`index.html` harus berada di root ZIP.

Build harus smoke-tested pada Chromium + Firefox; WebKit/Safari bila tersedia dicatat hasilnya.

## 182.5 ANDROID DELIVERABLE

Target production:

`build/android/MancingManiaGelut-v1.0.aab`

Play Store signing membutuhkan production keystore milik publisher/user.

Jika keystore/secret tidak tersedia kepada implementation environment:

- project tetap harus release-ready;
- Android export preset lengkap selain secret;
- debug/test AAB/APK boleh dibuat untuk validation;
- dokumentasikan satu-satunya external manual step: memasukkan signing credential lalu export release AAB.

AI/developer **tidak boleh membuat atau menyimpan secret palsu di repository** dan tidak boleh mengklaim Play Store-ready signed release jika signing credential tidak tersedia.

## 182.6 AUDIO DELIVERY

Release repository:

- zero external audio media files;
- all audio source berasal dari synthesis code + `.tres` numeric presets;
- code-generated music/SFX/ambience dapat direproduksi;
- no copyright dependency pada lagu/sample eksternal.

## 182.7 CONTENT COMPLETENESS

Wajib lengkap:

- 4 human named characters;
- 6 fish;
- 3 trash;
- 4 duel modes;
- 5×3 upgrade steps;
- all story events Section 165;
- full fish dialogue Section 166;
- full narrative/human story copy Section 183;
- all required UI screens;
- ending;
- post-game.

Tidak ada konten required yang diganti placeholder.

## 182.8 CODE QUALITY GATE

Release source:

- zero parser error;
- zero known null/missing reference on core flow;
- no duplicate authoritative constants scattered jika sudah ada Resource;
- no direct save dictionary mutation from UI;
- no hard-coded gameplay keycode bypassing InputMap;
- no use of global nondeterministic RNG untuk authoritative gameplay;
- no unresolved `TODO`/`FIXME` pada release-critical path;
- no disabled test untuk menyembunyikan failure;
- no downloaded/external production asset dependency;
- no runtime asset network fetch.

## 182.9 QA GATE

- all P0 tests pass;
- target zero known P1 core defect;
- full export smoke test pass;
- story full run pass;
- save/reload pass;
- balance simulation report within target atau exception explicitly approved;
- performance minimum acceptable met + Section 190 hard budgets reviewed;
- accessibility Section 189 pass;
- privacy/store/content-rating compliance review pass;
- Android physical test completed;
- Web browser test completed.

## 182.10 PLAYER EXPERIENCE GATE

Seorang new player harus dapat tanpa developer explanation:

- memahami cast;
- menangkap fish pertama;
- memahami duel;
- menjual fish;
- membayar debt;
- memahami upgrade;
- menemukan Fish Book setelah unlock;
- pause/resume;
- keluar dan Continue;
- mencapai ending.

Target first 10–12 min thesis tetap:

**Catch fish → fight fish → sell fish → fix life.**

## 182.11 LANGUAGE GATE

Release scan memastikan seluruh visible player-facing copy adalah English.

Nama Indonesia tetap tidak diterjemahkan secara paksa.

Tidak ada placeholder Bahasa Indonesia pada UI release.

## 182.12 SCOPE GATE

Release tidak boleh diam-diam memiliki:

- multiplayer;
- IAP;
- ad SDK;
- online account;
- gacha;
- lootbox;
- energy monetization;
- gambling uang player;
- unsupported extra fish/upgrade yang mengubah balance.

## 182.13 FINAL HANDOFF REPORT

Handoff wajib menyertakan ringkasan:

```text
Build version
Godot version
Commit/package identifier if available
Web build path
Android build/signing status
Automated tests: pass/fail counts
Manual QA platforms
Known issues
Performance observations
Balance simulation summary
Save schema version
Content manifest verification
Programmatic asset provenance verification
Privacy/Data Safety status
Content rating questionnaire status
Accessibility QA summary
Performance/package budget summary
Repository tag/commit
```

Jika known issue P0 ada, status tidak boleh `COMPLETE`.

## 182.14 FINAL COMPLETION STATEMENT

Hanya setelah seluruh implementation/QA gate di Section 182 dan pre-Gold-Master production gate Section 191.17 terpenuhi, project boleh diberi status:

# `V1.0 RELEASE CANDIDATE — COMPLETE`

Status ini **belum merupakan izin publish**. Publication memerlukan Sections 192–196 dan status `V1.0 GOLD MASTER — APPROVED` menurut Section 194.

Jika sebagian besar fitur sudah ada tetapi gate belum lulus, gunakan status:

`IMPLEMENTATION COMPLETE — QA NOT YET PASSED`

atau

`MILESTONE IN PROGRESS`.

Dilarang menggunakan kata “done”, “finished”, atau “release-ready” untuk project yang belum lulus contract ini.

---

# 183. COMPLETE NARRATIVE SCRIPT BIBLE — FINAL V1.0 COPY

Bagian ini adalah **source of truth final untuk narasi manusia, story event, notification, tutorial narrative copy, Fish Book flavor copy, dan ending v1.0**. Semua teks yang terlihat player tetap **English only**. Bahasa Indonesia pada bagian ini hanya menjelaskan staging/intent developer.

Jika Section 12–19 atau contoh dialog lama berbeda wording dengan Section 183, **Section 183 menang untuk copy final**, sedangkan fakta cerita, milestone, dan struktur gameplay lama tetap berlaku.

AI/developer **tidak boleh menulis ulang dialog sesuka hati**. Perubahan copy release membutuhkan revisi GDD atau catatan eksplisit pada `docs/implementation_decisions.md` yang disetujui owner.

## 183.1 NARRATIVE TONE CONTRACT

Narasi harus selalu:

- hangat;
- understated;
- deadpan;
- manusiawi;
- tidak menghakimi Darto setiap saat;
- tidak menjadikan hutang sebagai horror;
- tidak menjadikan judi masa lalu sebagai lelucon atau gameplay menyenangkan;
- tidak menjadikan Rini sebagai karakter pemarah satu dimensi;
- tidak menjadikan Nisa alat guilt-trip;
- tidak membuat Bu Yati terlalu sentimentil;
- memberikan ruang hening 0.4–1.2 detik setelah punchline bila sesuai;
- membiarkan tindakan kecil membawa bobot emosional.

Darto tidak pernah mendapat pidato besar mengenai redemption. Pemulihan terlihat dari tindakan berulang.

## 183.2 STORY EVENT ORDER — AUTHORITATIVE

Urutan event wajib mengikuti sistem arbitration Section 177:

1. `story_prologue_zero`
2. `story_first_fish`
3. `story_first_market`
4. `story_debt_100k`
5. `story_debt_300k`
6. `story_debt_600k`
7. `story_debt_1000k`
8. `story_debt_1400k`
9. `story_debt_1650k`
10. `story_arowana_first_win` — optional special, queued sesuai priority
11. `story_debt_paid`
12. `story_final_family`
13. `story_postgame_unlock`

Hanya satu queued narrative event dimainkan per Market visit sesuai Section 177. Prologue, first scripted fish, first Market tutorial, credits, dan mandatory ending routing mengikuti flow khususnya sendiri.

## 183.3 `story_prologue_zero` — FINAL SCRIPT

### Shot A — Black / Room Ambience

Tidak ada musik.

SFX procedural:

- kipas tua;
- motor jauh;
- ambience rumah tenang.

Fade in.

Phone UI:

> BANK BALANCE: Rp 18,430

Pause 1.0 sec.

> TOTAL DEBT: Rp 1,800,000

Notification:

> CEPATCASH — PAYMENT REMINDER
> Your outstanding balance remains outstanding.
> We are also outstandingly disappointed.

Darto:

> "...Fair."

Rini sedang mengenakan sepatu kerja.

Rini:

> "I'm leaving."

Darto:

> "Yeah."

Rini berhenti.

Rini:

> "Did you open it again?"

Darto:

> "No."

> "I deleted everything."

Rini:

> "Good."

Pause 0.8 sec.

Rini:

> "Deleting it is the easy part."

Darto:

> "I know."

Rini melihatnya sebentar, tidak marah.

Rini:

> "There's rice in the cooker."

Darto:

> "Okay."

Rini:

> "And don't sell the cooker."

Darto melihat Rini.

Darto:

> "That happened once."

Rini:

> "That is why I said it."

Rini pergi.

Pintu tertutup.

Pause 1.0 sec.

Darto melihat joran, ember biru, helm, dan kunci motor.

Darto:

> "All right."

> "No shortcuts."

Ia mengambil kunci.

### Shot B — Motorcycle Establishing

Motor tua melewati jalan kecil.

Tidak ada montage heroik.

Title:

> MANCING MANIA: GELUT EDITION

Subtitle:

> SUNDAY — 3:17 PM

Tidak ada narrator voice-over.

## 183.4 `story_first_fish` — FINAL SCRIPT

Setelah reel tutorial sukses, Bruiser Catfish terangkat.

Pause 0.8 sec.

Catfish:

> "Put me down."

Darto:

> "...What?"

Catfish:

> "You heard me."

Darto:

> "Fish don't talk."

Catfish:

> "And unemployed men don't usually argue with dinner."

Pause 0.9 sec.

Darto:

> "That felt unnecessary."

Sarung tinju procedural muncul/terpasang sebagai prop visual absurd.

Catfish:

> "Square up."

Darto:

> "Of course."

Wheel tutorial muncul dan dikunci ke Boxing.

Jika tutorial duel kalah:

Catfish:

> "That was rough."

Darto:

> "For me or you?"

Catfish:

> "Yes. Again."

Retry otomatis tanpa punishment.

Setelah kemenangan tutorial:

Catfish:

> "Fair. The bucket earned me."

Darto:

> "I'm not explaining this to anyone."

## 183.5 `story_first_market` — FINAL SCRIPT

Bu Yati melihat ember.

Bu Yati:

> "Fish fresh?"

Darto:

> "Very."

Bu Yati:

> "Still moving?"

Darto:

> "Emotionally, yes."

Bu Yati melihat Darto.

Pause 0.7 sec.

Bu Yati:

> "Put it on the scale."

Tutorial SELL dimulai.

Setelah sale pertama:

Darto:

> "That's more than I expected."

Bu Yati:

> "Then expect less. It's healthier."

Phone notification:

> DEBT PAYMENT AVAILABLE

Tutorial DEBT tab.

Minimum tutorial payment: Rp10,000.

Setelah pembayaran:

> DEBT REMAINING: Rp 1,790,000

Procedural single soft ding.

Darto:

> "One down."

Bu Yati:

> "One million seven hundred ninety thousand to go."

Darto:

> "...You didn't have to say the whole number."

Bu Yati:

> "You looked too relaxed."

Tutorial berakhir.

## 183.6 `story_debt_100k` — “A NUMBER THAT MOVED”

Trigger: lifetime debt paid >= Rp100,000.

Market exit event.

Darto melihat Debt Ledger.

> PAID: Rp 100,000

Darto:

> "One hundred thousand."

Bu Yati:

> "That's a number."

Darto:

> "It's a decent number."

Bu Yati:

> "It's smaller than one point eight million."

Darto:

> "I liked it better before you helped."

Bu Yati:

> "I wasn't helping."

Phone vibrates.

Rini message:

> How was the lake?

Darto reply choice tidak interaktif; auto-script:

> Profitable enough to go back.

Rini:

> Go back to the lake or go back home?

Darto:

> Both.

Rini:

> Good answer.

Darto memasukkan phone ke saku.

Tidak ada musik kemenangan.

## 183.7 `story_debt_300k` — “PAYMENTS ARE GOOD”

Trigger: lifetime debt paid >= Rp300,000.

Phone notification setelah Market selesai.

Rini:

> "I saw the payment."

Darto:

> "Good payment or bad payment?"

Rini:

> "Payments are generally good, Darto."

Darto:

> "Just checking the category."

Rini:

> "Keep going."

Pause 0.8 sec.

Darto membaca dua kata terakhir lagi sebelum menutup phone.

Tidak ada dialogue tambahan.

## 183.8 `story_debt_600k` — “THE GOLDEN ONE”

Trigger: lifetime debt paid >= Rp600,000.

Phone call dari Nisa.

Nisa:

> "Dad?"

Darto:

> "Hey. Everything okay?"

Nisa:

> "Mom said you're fishing now."

Darto:

> "That's one way to describe it."

Nisa:

> "What's the other way?"

Darto:

> "Employment with unusually aggressive seafood."

Nisa tertawa kecil.

Nisa:

> "Mom said the fish fight you."

Darto:

> "Your mother shares too much."

Nisa:

> "Did you win?"

Darto:

> "Some of them."

Nisa:

> "Which one's the weirdest?"

Darto:

> "There's a tilapia that judges my exercise routine."

Nisa:

> "Take notes."

Darto:

> "On the insults?"

Nisa:

> "On all of them."

Pause.

Nisa:

> "And send me a picture if you catch the golden one."

Darto:

> "You know about that one?"

Nisa:

> "The internet exists, Dad."

Darto:

> "Right. Boarding school has advanced technology."

Nisa:

> "Very advanced. We have chairs."

Darto:

> "Show-off."

Call ends warmly.

System unlock:

> FISH BOOK UNLOCKED
> Keep notes for Nisa. And, apparently, for science.

## 183.9 `story_debt_1000k` — “AFTER”

Trigger: lifetime debt paid >= Rp1,000,000.

Rini dan Darto phone call/message hybrid; staging di Market bench.

Rini:

> "You're past halfway."

Darto:

> "I noticed."

Rini:

> "You usually avoid looking at numbers."

Darto:

> "I'm trying a new hobby."

Rini:

> "Numbers?"

Darto:

> "Finishing things."

Pause 0.9 sec.

Rini:

> "When this is done..."

Darto menunggu.

Rini:

> "The roof still leaks near the kitchen."

Darto:

> "Romantic."

Rini:

> "I'm serious."

Darto:

> "I know."

Rini:

> "I'm talking about after, Darto."

Pause.

Darto:

> "Yeah."

> "After sounds good."

Call ends.

No hug montage, no dramatic music.

## 183.10 `story_debt_1400k` — “REGULAR”

Trigger: lifetime debt paid >= Rp1,400,000.

Bu Yati sedang menulis angka pada papan kecil.

Bu Yati:

> "That restaurant man asked about your fish again."

Darto:

> "The one with the white van?"

Bu Yati:

> "Yes."

Darto:

> "Is that good?"

Bu Yati:

> "He pays."

Darto:

> "Excellent character reference."

Bu Yati:

> "He wants regular supply if you keep bringing decent fish."

Darto berhenti bercanda sebentar.

Darto:

> "Regular?"

Bu Yati:

> "That's what I said."

Darto:

> "Like... work?"

Bu Yati:

> "Don't make it dramatic. Bring fish."

Darto tersenyum kecil.

Darto:

> "Right."

Bu Yati:

> "Fresh fish."

Darto:

> "Emotionally?"

Bu Yati:

> "No."

## 183.11 `story_debt_1650k` — “ALMOST”

Trigger: lifetime debt paid >= Rp1,650,000.

Scene pendek di danau setelah keluar Market.

Wide shot.

Danau sama seperti biasa.

Darto duduk.

Phone menunjukkan:

> DEBT REMAINING: Rp 150,000

Darto:

> "Almost."

Pause 1.2 sec.

Burung jauh.

Darto melihat air.

Darto:

> "Still looks like the same lake."

Pause.

Darto:

> "Good."

Ia menyimpan phone dan cast lagi.

Tidak ada musik kemenangan.

## 183.12 `story_arowana_first_win` — FINAL SCRIPT

Gunakan hanya setelah kemenangan pertama Don Arowana.

Arowana kalah tetapi tetap tenang.

Arowana:

> "Enjoy your victory."

Darto:

> "I was planning to."

Arowana:

> "The lake remembers."

Darto:

> "That's fine."

Pause 0.9 sec.

Darto:

> "Does the lake pay three hundred thousand?"

Arowana:

> "You disgust me."

Darto:

> "That's not a no."

Cut to Result.

## 183.13 `story_debt_paid` — “THAT'S IT?”

Trigger: debt remaining == 0 setelah transaction committed.

Debt Ledger:

> DEBT REMAINING: Rp 0

Tidak ada confetti.

Tidak ada fanfare.

Phone vibrates.

CePatCash:

> YOUR BALANCE HAS BEEN FULLY SETTLED.

Pause 0.8 sec.

Second line:

> Thank you.

Darto menunggu.

Darto:

> "...That's it?"

Phone silent.

Darto:

> "No final boss?"

Pause.

Ia tertawa kecil pada dirinya sendiri.

Darto:

> "Good."

Rini message masuk beberapa detik kemudian:

> I saw it.

Darto:

> It's done.

Rini:

> Come home when you're finished there.

Darto melihat danau.

Darto:

> Soon.

Rini:

> Okay.

Fade.

## 183.14 `story_final_family` — “SUNDAY”

Minggu berikutnya.

Wide lake shot. Dua helm terlihat dekat motor.

Nisa:

> "So which one punched you?"

Darto:

> "The catfish."

Rini:

> "He lost twice."

Darto:

> "Why are we keeping statistics?"

Nisa:

> "For science."

Darto:

> "Science has become very judgmental."

Nisa membuka Fish Book di phone/notebook UI.

Nisa:

> "You wrote that the tilapia called your posture weak."

Darto:

> "Accurate notes are important."

Rini:

> "Your posture is weak."

Darto:

> "This family has chosen violence."

Pause 0.8 sec.

Mereka makan sederhana.

Nisa:

> "Are you still going to come here?"

Darto melihat danau.

Darto:

> "Probably."

Rini:

> "He likes being yelled at by fish."

Darto:

> "I like the quiet parts."

Pause.

Nisa:

> "And the money."

Darto:

> "And some of the money."

Float tenggelam.

Darto berdiri.

Rini:

> "Don't start a fight."

Darto:

> "I don't start them."

Water insert.

Don Arowana muncul.

Arowana:

> "LIAR."

Hold 0.8 sec.

Cut to black.

Credits.

## 183.15 `story_postgame_unlock` — FINAL COPY

Setelah credits selesai atau di-skip:

> FREE FISHING MODE UNLOCKED

> The debt is gone.
> The fish are unfortunately still here.

Second panel:

> DEBT LEDGER has become FAMILY SAVINGS.

> Keep fishing, finish the Fish Book, upgrade your gear, chase records, or simply stay by the lake for a while.

Button:

> BACK TO THE LAKE

## 183.16 CEPATCASH NOTIFICATION POOL

CePatCash selalu terasa birokratis, sedikit absurd, tidak mengancam, tidak glamor.

Pool boleh muncul maksimal satu setiap 18–35 menit dan tidak saat duel/cutscene.

Pre-completion examples:

> PAYMENT REMINDER
> Your outstanding balance remains outstanding.

> ACCOUNT NOTICE
> We appreciate your recent payment.
> We would appreciate the rest more.

> BALANCE UPDATE
> Progress detected.
> Enthusiasm remains procedurally limited.

> FRIENDLY REMINDER
> This is the friendly version of the reminder.

> PAYMENT STATUS
> Still not zero.
> We checked twice.

Darto optional reactions:

- "Very informative."
- "Thank you, tiny rectangle of stress."
- "We're getting there."
- "I know."

Setelah debt paid, pool dinonaktifkan permanen.

## 183.17 MARKET AMBIENT BANTER POOL

Banter ini bukan narrative event dan tidak menghabiskan quota story Market visit. Maksimum satu line exchange setiap Market visit, dan tidak dimainkan jika queued story event akan diputar.

Bu Yati:

> "Fish fresh?"

Darto:

> "That question has become threatening."

---

Darto:

> "Do you ever take a day off?"

Bu Yati:

> "This is my day off."

Darto melihat warung.

> "You are at work."

Bu Yati:

> "Quietly."

---

Bu Yati:

> "You caught another sandal."

Darto:

> "The lake provides."

Bu Yati:

> "The lake needs cleaning."

---

Darto:

> "Do people normally sell this many fighting fish?"

Bu Yati:

> "No."

Darto:

> "Good."

Bu Yati:

> "I didn't say good."

## 183.18 FISH BOOK — FINAL FLAVOR COPY

### Bruiser Catfish

Species line:

> CATFISH / LELE

Subtitle:

> LOCAL TROUBLEMAKER

Description:

> A thick-whiskered catfish with the manners of a neighborhood tough guy and the surprising professionalism of a tax accountant. Prefers the lake to the bucket. Understandable.

### Gym-Rat Tilapia

Species line:

> TILAPIA / NILA

Subtitle:

> PROTEIN ENTHUSIAST

Description:

> Treats every reel, punch, and poor life decision as part of a training program. Has never been asked for fitness advice. Continues to provide it.

### Shady Gourami

Species line:

> GIANT GOURAMI / GURAMI

Subtitle:

> ALLEGEDLY PRESENT

Description:

> Claims not to live in Danau Cempaka despite repeatedly being caught in Danau Cempaka. Frequently requests that records be deleted. Records have not been deleted.

### Golden Carp

Species line:

> COMMON CARP / IKAN MAS

Subtitle:

> SELF-DECLARED LUXURY

Description:

> Golden, expensive-looking, and deeply offended by ordinary containers. Estimates its own value several times per conversation. The Market uses different mathematics.

### Snakehead Sergeant

Species line:

> SNAKEHEAD / GABUS

Subtitle:

> COMBAT WATER INSTRUCTOR

Description:

> Believes fishing is a discipline problem. Believes everything is a discipline problem. Volume control remains under investigation.

### Don Arowana

Species line:

> ASIAN AROWANA / ARWANA

Subtitle:

> THE LAKE REMEMBERS

Description:

> A rare old legend of Danau Cempaka. Calm, expensive, and disturbingly well-informed about Darto's personal life. Defeating him is impressive. It is not required to fix your life.

## 183.19 HOW TO PLAY — FINAL COPY

### Fishing

> CAST, then wait for a real bite.
> Small nibbles are only warnings.
> When the float sinks, STRIKE before the reaction window closes.
> During reeling, HOLD REEL to move the marker upward and RELEASE to let it fall.
> Keep the marker inside the green zone while reeling to land the catch.
> If line stress reaches maximum, the fish escapes.

### Boxing

> Read the fish's telegraphed attack direction.
> DODGE in the indicated direction, then counter with JAB or CROSS.
> A late, correct dodge becomes a PERFECT DODGE and opens a stronger counter window.
> Random button mashing is less useful than paying attention.

### Arm Wrestling

> MASH to push the position toward your side.
> Mashing consumes stamina.
> Stop briefly to recover.
> Low stamina means weaker pushes, not complete failure.

### Dance

> Hit the four lanes when notes reach the target line.
> PERFECT timing scores the most.
> Missing breaks your combo.
> Black Coffee changes only visual travel speed, never the beat itself.

### Suwit

> First to two wins.
> Draws do not count.
> The fish gives a tell, but some fish lie more than others.
> Agate Charm reveals the fish's real move for a moment.

### Market

> Sell catches for cash.
> Use cash to upgrade your gear or pay the debt.
> Paying debt advances the story.
> Upgrading first can make future fishing easier.
> There is no wrong order.

## 183.20 TUTORIAL PROMPT COPY — FINAL

Fishing:

```text
PRESS SPACE OR CLICK TO CAST
WAIT FOR THE FLOAT...
SMALL NIBBLES ARE NOT THE REAL BITE
STRIKE!
HOLD TO REEL
RELEASE TO LOWER TENSION
KEEP THE MARKER IN THE GREEN ZONE
LINE STRESS!
CATCH LANDED
```

Mobile substitutes physical key wording with action labels:

```text
TAP CAST
WAIT FOR THE FLOAT...
STRIKE!
HOLD REEL
RELEASE TO LOWER TENSION
```

Market:

```text
SELL YOUR CATCH
OPEN THE DEBT TAB
PAY Rp 10,000
UPGRADES CAN WAIT — OR NOT. YOUR CHOICE.
```

Bucket:

> YOUR BUCKET HAS NO CAPACITY LIMIT. THIS IS A MERCY.

Fish Book unlock:

> NEW: FISH BOOK
> Nisa asked for notes. Try to make them accurate.

## 183.21 ERROR / RECOVERY COPY — FINAL

Save corrupt:

Title:

> SAVE DATA COULD NOT BE READ

Body:

> Your current save appears damaged. A backup has been preserved when possible.

Buttons:

> TRY AGAIN
> START NEW GAME

Save write failure:

> SAVE FAILED
> Your latest progress may not be stored yet. Please keep the game open and try again.

Web storage notice:

> WEB SAVE NOTICE
> Progress is stored in this browser. Clearing site data may remove your save. Use EXPORT SAVE if you want a manual backup.

Import invalid:

> IMPORT FAILED
> This file is not a valid Mancing Mania: Gelut Edition save.

Unsupported save version:

> SAVE VERSION NOT SUPPORTED
> This save was created by an incompatible version of the game.

## 183.22 CREDITS COPY STRUCTURE

Heading:

> MANCING MANIA: GELUT EDITION

Subheading:

> A very serious game about very unserious fish.

Credit categories:

```text
GAME DESIGN
PROGRAMMING
PROCEDURAL 3D & UI SYSTEMS
PROCEDURAL AUDIO SYSTEMS
WRITING
QUALITY ASSURANCE
SPECIAL THANKS
```

Jika hanya satu creator mengisi banyak role, nama boleh diulang atau roles digabung.

Final card:

> Thank you for spending a Sunday afternoon at Danau Cempaka.

Pause.

> Please do not argue with the fish.

## 183.23 NARRATIVE COMPLETENESS TEST

Release gagal jika:

- ada story event tanpa final English copy;
- ada placeholder seperti `TODO_DIALOGUE`;
- AI menulis dialogue runtime generatif;
- nama karakter berubah tanpa revisi GDD;
- Rini menjadi caricature yang hanya marah;
- debt story berubah menjadi ancaman kekerasan;
- gambling masa lalu berubah menjadi reward/joke mechanic;
- ending memberi sudden wealth/jackpot;
- Fish Book description kosong;
- tutorial copy berbeda antara input method tanpa alasan platform.


---

# 184. PROGRAMMATIC ASSET GENERATION CONTRACT — ZERO INTERNET ASSETS

v1.0 **tidak boleh mengambil asset 3D, UI image, icon, texture, animation, music, ambience, atau SFX dari internet, asset store, marketplace, stock library, model repository, sample pack, font website, atau generator cloud eksternal.**

Tujuan:

- project dapat direproduksi dari source;
- tidak ada dependency lisensi asset pihak ketiga;
- art style konsisten;
- AI dapat membangun seluruh project tanpa mencari asset;
- clean checkout tetap lengkap.

## 184.1 ALLOWED SOURCE MATERIAL

Production v1.0 hanya boleh memakai:

1. code/GDScript yang berada di repository;
2. Godot built-in primitive/resource classes;
3. numeric/color/config resources `.tres` yang ditulis project;
4. geometry yang dihasilkan oleh generator project sendiri;
5. procedural `Image` / `ImageTexture` yang dibuat project sendiri;
6. Godot default built-in font sebagai satu-satunya font baseline;
7. shader source buatan project;
8. procedural audio code Section 175;
9. output render/screenshot yang dihasilkan dari asset project sendiri.

Tidak boleh ada network request untuk asset generation pada build process.

## 184.2 AUTHORITATIVE GENERATOR ARCHITECTURE

Tambahkan folder:

```text
res://tools/generators/
  generate_all_assets.gd
  generator_manifest.gd
  mesh_builder.gd
  material_builder.gd
  character_builder.gd
  fish_builder.gd
  prop_builder.gd
  environment_builder.gd
  vehicle_builder.gd
  ui_art_builder.gd
  reference_sheet_generator.gd
  generator_validation.gd
```

Semua generator adalah `@tool` Typed GDScript yang dapat dijalankan dari Godot Editor/headless.

Canonical headless command:

```text
godot --headless --editor --path . --script res://tools/generators/generate_all_assets.gd
```

Jika versi Godot tertentu memerlukan variasi CLI, README harus mencatat command ekuivalen yang tervalidasi.

## 184.3 GENERATED OUTPUT PATH

Output final generator:

```text
res://generated/
  models/
  scenes/
  materials/
  textures/
  ui/
  references/
  manifests/
```

`res://generated/` boleh di-commit agar clean checkout langsung runnable, **tetapi seluruh output harus dapat diregenerasi dari source generator tanpa internet**.

Release build tidak menjalankan full asset generator saat startup.

Generation dilakukan:

- editor-time;
- CI/release preparation;
- explicit developer command.

Runtime hanya memuat resource final hasil generation.

## 184.4 GENERATION DETERMINISM

Setiap generated asset memiliki:

- stable generator ID;
- generator version;
- fixed numeric seed bila memakai randomness;
- expected output path;
- checksum/hash manifest bila praktis.

`generator_manifest.json` minimal berisi:

```json
{
  "generator_schema": 1,
  "project_version": "1.0.0",
  "assets": {
    "chr_darto": {
      "generator": "character_builder",
      "generator_version": 1,
      "seed": 1101,
      "output": "res://generated/scenes/characters/chr_darto.tscn"
    }
  }
}
```

Menjalankan generator dua kali dengan source/seed sama harus menghasilkan visual/resource structure yang ekuivalen.

## 184.5 MESH CONSTRUCTION RULES

Gunakan Godot native APIs seperti:

- `ArrayMesh`;
- `SurfaceTool`;
- `MeshDataTool` jika perlu;
- `BoxMesh`;
- `CylinderMesh`;
- `SphereMesh`/custom low-segment sphere;
- `CapsuleMesh` hanya jika silhouette sesuai;
- `PrismMesh`;
- `QuadMesh`;
- generated indexed triangle arrays.

Primitive default tidak boleh dibiarkan terlihat seperti placeholder pada hero asset.

Hero bentuk dibangun melalui:

- low-segment custom profile;
- taper/frustum;
- vertex displacement terkontrol;
- asymmetric proportions;
- merged or layered parts;
- custom silhouette geometry;
- vertex color/material blocking.

## 184.6 CHARACTER GENERATION STRATEGY

Human characters menggunakan **stylized rigid-part/semi-rigid low-poly rig** yang mudah direproduksi dengan code.

Setiap character generated scene minimal:

```text
CharacterRoot (Node3D)
├── Skeleton3D
├── BodyMeshes
├── AccessoryMeshes
├── FaceMarkers
├── AnimationPlayer
└── AnimationTree (jika dibutuhkan)
```

Skeleton minimum bones:

```text
root
pelvis
spine_lower
spine_upper
neck
head
upper_arm_l
forearm_l
hand_l
upper_arm_r
forearm_r
hand_r
thigh_l
shin_l
foot_l
thigh_r
shin_r
foot_r
```

Mesh body part dapat menggunakan weighted skin sederhana atau rigid bone-attached segment jika visual lebih stabil/performatif.

Tidak mengejar deformation realism.

Prioritas:

1. silhouette;
2. pose readability;
3. animation clarity;
4. performance;
5. reproducibility.

## 184.7 FISH GENERATION STRATEGY

Fish dibuat dari procedural body profile + fins + tail + eyes + character accessory.

Minimum fish rig:

```text
root
body_front
body_mid
body_back
tail_base
tail_tip
fin_left
fin_right
jaw_or_head
```

Fish body harus berbeda secara nyata per species, bukan satu mesh yang hanya diganti warna.

Species profile:

- Catfish: long low body, broad head, whiskers, muted dark-grey/olive;
- Tilapia: taller compressed oval body, strong cheek/body exaggeration;
- Gourami: tall broad body, longer ventral feel, calmer silhouette;
- Carp: rounded/arched back, gold blocking, visible large-fin silhouette;
- Snakehead: long torpedo body, flat-ish head, dark band accents;
- Arowana: long premium silhouette, upward mouth, large scale-like color blocking through geometry/material zones.

Whiskers, headbands, glasses, gloves, chains, scar mark, dan accessories juga dihasilkan project sendiri.

## 184.8 MOTORCYCLE GENERATION STRATEGY

Motor Darto dibuat dari procedural modular primitives/custom meshes:

- front/rear tyre;
- rims;
- fork;
- headlamp;
- handlebar;
- mirrors;
- fuel tank;
- seat;
- engine block;
- exhaust;
- rear shocks;
- frame;
- side panels;
- fenders;
- kickstand.

Target tetap motor tua awal-2000-an secara generik tanpa menyalin logo/model proprietary secara literal.

Tidak ada brand/logo.

## 184.9 ENVIRONMENT GENERATION STRATEGY

Environment menggunakan modular generated assets:

- terrain/shore profile meshes;
- water plane/shader;
- procedural trees dari trunk branch frustum + foliage clusters;
- grass/reeds from low-poly blade clusters;
- road strip;
- power poles;
- lamps;
- distant house silhouettes;
- market shell;
- home room shell;
- plastic chairs;
- tables;
- thermos;
- jars;
- fan;
- signs;
- fishing props;
- duel set dressing.

Vegetation random placement menggunakan fixed seed per set agar reproducible.

## 184.10 MATERIAL & TEXTURE GENERATION

Primary visual style mengandalkan geometry + material color blocking.

Allowed texture generation:

- flat color image;
- gradients;
- procedural noise;
- subtle speckle;
- baked-like AO approximation generated from rule/vertex color;
- simple line/shape decals drawn with `Image`;
- UI illustration rendered from generated 3D.

Forbidden:

- downloaded photo texture;
- stock texture;
- scanned material pack;
- external PBR material library;
- AI-cloud-generated texture dependency.

Material source adalah `StandardMaterial3D` atau project shader.

## 184.11 UI ART GENERATION

Seluruh UI dibuat dari:

- Godot `Control` nodes;
- `StyleBoxFlat`;
- procedural `_draw()` primitives;
- generated `ImageTexture` jika raster diperlukan;
- project-created shaders;
- generated 3D renders untuk Fish Book portrait.

Tidak ada downloaded icon pack.

Icon harus dibentuk melalui code dari:

- polygons;
- arcs;
- lines;
- circles;
- simple silhouettes.

Contoh:

- cash: rectangular note + central circle;
- bucket: trapezoid + handle arc;
- rod: curved/diagonal line + float;
- coffee: cup + steam curves;
- charm: ring + gem polygon;
- fish book: book rectangle + fish silhouette.

## 184.12 FONT RULE

v1.0 menggunakan **Godot built-in default readable font only**.

Tidak ada download font eksternal.

Tidak ada custom font requirement.

Jika di masa depan custom font ditambahkan, itu perubahan post-v1.0 dan memerlukan revisi GDD + license review.

## 184.13 ANIMATION GENERATION

Animation resources dibuat oleh code/project:

- transform keyframes;
- bone rotation/translation tracks;
- material parameter tracks bila perlu;
- call-method event markers;
- blend setup.

Tidak ada animation file dari Mixamo, marketplace, mocap pack, atau internet.

Procedural generator dapat membuat base clips, lalu nilai numeric boleh di-tune manual di source data selama source tetap berada dalam project.

## 184.14 REFERENCE IMAGE GENERATION

Reference sheet PNG bukan external art.

`reference_sheet_generator.gd` membuat output dari final generated asset:

- front;
- side;
- back;
- 3/4;
- silhouette;
- palette swatches;
- scale reference;
- hero pose.

Output disimpan ke:

`res://generated/references/` untuk QA/art lock.

## 184.15 GENERATED ASSET QA

Setiap asset generator wajib test:

- output exists;
- no null material;
- bounding box sensible;
- triangle count within budget;
- required node names exist;
- scale approximately correct;
- no NaN/INF vertex;
- no zero-area critical mesh surface jika dapat divalidasi;
- no missing animation referenced by manifest;
- visual reference render dapat dibuat.

## 184.16 ZERO-ASSET-INTERNET RELEASE GATE

Release scan gagal jika ditemukan:

- imported `.glb`, `.fbx`, `.obj`, `.blend` yang bukan hasil generator repository;
- downloaded `.png/.jpg/.webp/.svg` visual production asset;
- downloaded font file;
- imported animation pack;
- external sound file;
- third-party asset-store license;
- attribution yang muncul karena production asset eksternal;
- runtime network load untuk asset.

Allowed release image files hanyalah output yang **dihasilkan generator project sendiri** dan dapat ditelusuri ke manifest.

---

# 185. FINAL VISUAL REFERENCE SHEET BIBLE

Bagian ini mengunci identitas visual agar dua implementer tidak menghasilkan karakter/set yang berbeda secara fundamental.

Reference sheet final adalah **spesifikasi + render otomatis**. Spesifikasi di bawah authoritative; PNG reference yang dibuat generator harus mencerminkannya.

## 185.1 GLOBAL SCALE

Godot world convention:

`1 unit = 1 meter`.

Approximate human height:

- Darto: 1.72 m;
- Rini: 1.60 m;
- Nisa: 1.52 m;
- Bu Yati: 1.56 m.

Scale tidak perlu anatomically exact, tetapi relative height harus konsisten antar-scene.

## 185.2 DARTO — FINAL SHEET

Identity:

> Ordinary Indonesian man trying to become dependable again; visually unheroic but likeable.

Silhouette:

- average/slightly lean body;
- relaxed shoulders;
- small belly allowed but not caricature;
- slightly forward resting posture;
- old cap;
- waist bag;
- sandals;
- fishing rod gives strongest secondary silhouette.

Head/face:

- rounded rectangular head;
- short messy dark hair visible below cap;
- simple eyebrows;
- small tired eye shapes;
- nose indicated by low-poly wedge, not realistic sculpt;
- subtle stubble only via material tone if used.

Clothing:

- faded warm beige/olive T-shirt;
- dark desaturated shorts/trousers;
- brown/grey sandals;
- muted waist bag.

Palette target:

- shirt `#A78D68` family;
- trousers `#4F554E` family;
- skin warm medium tan range;
- cap faded `#6A6655`.

Readability:

Darto must still be identifiable as silhouette at 128 px character height.

Never:

- muscular hero body;
- fashionable streetwear;
- luxury accessories;
- dirty/homeless stereotype;
- clown proportions.

## 185.3 RINI — FINAL SHEET

Identity:

> Practical factory worker, tired but composed, warmth expressed through restraint.

Silhouette:

- compact practical posture;
- simple tied/short dark hair;
- modest everyday clothing;
- work bag or lunch container only when scene requires.

Clothing:

- muted blue-grey/terracotta work-casual palette;
- practical shoes/sandals;
- no glamorized factory uniform requirement.

Expression baseline:

- neutral/deadpan;
- eyebrow micro-movement important;
- small smile rare and therefore meaningful.

Never:

- angry-wife caricature;
- exaggerated glamour;
- constant crossed arms;
- exaggerated sadness.

## 185.4 NISA — FINAL SHEET

Identity:

> Bright 14-year-old boarding-school student who finds her father's fish stories genuinely funny.

Silhouette:

- youthful but not childlike chibi;
- simple backpack/phone accessory optional;
- neat casual clothes.

Palette:

- soft sky blue;
- warm cream;
- small muted red accent.

Body proportion must clearly read as teenager and never sexualized.

Expression:

- curious;
- amused;
- observant.

## 185.5 BU YATI — FINAL SHEET

Identity:

> Warung owner who has seen everything and does not have time to dramatize any of it.

Silhouette:

- compact sturdy older adult;
- simple blouse/shirt;
- practical skirt/trousers;
- tied hair/head covering style may be simple and culturally neutral, but do not introduce religious signifier unless intentionally approved.

Palette:

- muted maroon/brown;
- warm cream;
- olive accent.

Pose:

- comfortable behind counter;
- one-hand-on-scale/table poses;
- minimal expressive movement.

## 185.6 BRUISER CATFISH — FINAL SHEET

Basis:

Lele.

Silhouette:

- broad head;
- long dark body;
- four major whisker pairs stylized/readable;
- worn red boxing gloves oversized enough to read but not giant comedy props.

Palette:

- charcoal olive body;
- lighter belly;
- faded red gloves.

Expression:

professional neighborhood tough guy, not evil.

## 185.7 GYM-RAT TILAPIA — FINAL SHEET

Basis:

Nila.

Silhouette:

- tall compressed fish body;
- exaggerated shoulder/pectoral area suggesting impossible musculature;
- headband;
- fins posed like flexing arms when joking.

Palette:

- cool grey-green;
- warm red/orange headband;
- lighter belly.

Never literal human abs texture; muscle joke comes from geometry/pose.

## 185.8 SHADY GOURAMI — FINAL SHEET

Basis:

Gurami.

Silhouette:

- high broad body;
- long ventral fin feel;
- small dark sunglasses;
- slightly hunched suspicious orientation.

Palette:

- muted silver/olive;
- dark glasses;
- subtle purple-brown accent.

Glasses remain readable from gameplay camera.

## 185.9 GOLDEN CARP — FINAL SHEET

Basis:

Ikan mas.

Silhouette:

- arched back;
- round premium body;
- broad tail;
- thin exaggerated necklace/chain.

Palette:

- warm gold/orange;
- cream belly;
- darker fin tips;
- metallic feel achieved by roughness/specular and color blocking, not realistic gold texture.

Must look expensive to itself, not like a fantasy magical creature.

## 185.10 SNAKEHEAD SERGEANT — FINAL SHEET

Basis:

Gabus.

Silhouette:

- long torpedo body;
- broad/flat head;
- rigid posture;
- military-style headband without real-world military insignia.

Palette:

- dark olive;
- muddy brown;
- desaturated khaki headband.

No real national military logo/rank.

## 185.11 DON AROWANA — FINAL SHEET

Basis:

Arwana Asia.

Silhouette:

- longest/elegant fish silhouette;
- upward mouth;
- broad flowing fins;
- deliberate curve;
- thin chain;
- subtle scar.

Palette:

- deep bronze/red-gold body;
- dark wine fins;
- muted gold chain.

Motion:

- slow;
- economical;
- rarely flails.

Must feel like local legend, not supernatural dragon.

## 185.12 DARTO MOTORCYCLE — FINAL SHEET

Visual target:

- early-2000s old Indonesian standard/naked motorcycle feeling;
- upright tank/seat silhouette;
- round-ish headlamp;
- visible engine;
- narrow tyres;
- twin-shock/rear suspension feeling;
- maintained but aged.

Palette:

- faded dark maroon or deep muted green tank;
- black/dark frame;
- warm grey metal;
- worn-but-intact seat.

Never:

- recognizable real brand/logo;
- sports bike fairing;
- severe rust pile;
- broken seat;
- custom chopper.

## 185.13 DANAU CEMPAKA — GOLDEN REFERENCE

Composition target:

- water occupies meaningful negative space;
- near bank grass/reeds cluster;
- one major shade tree;
- Darto small in frame;
- motorcycle secondary;
- Market distant but readable;
- road/power pole hint Indonesia without sign overload;
- distant houses/garden low detail.

Golden Afternoon baseline:

- warm sun elevation low-medium;
- soft cream highlights;
- blue-green water;
- green foliage with warm edge light;
- shadows long but not black.

Scene must feel lived-in, not tourist postcard.

## 185.14 HOME SET — GOLDEN REFERENCE

Small modest room:

- floor mat;
- low table;
- old fan;
- phone;
- shoes near doorway;
- fishing gear in corner;
- enough empty space to avoid poverty-porn clutter.

Lighting:

- indirect warm daylight;
- quiet;
- no dramatic darkness.

## 185.15 MARKET SET — GOLDEN REFERENCE

Warung open-front feeling:

- rough wood table;
- scale;
- freezer;
- thermos;
- jars;
- plastic chairs;
- faded price board;
- hanging lamp;
- small fan;
- Bu Yati behind/near counter.

Palette:

warm wood + cream + faded red + olive.

Not a clean supermarket UI environment.

## 185.16 BOXING SET — GOLDEN REFERENCE

Small absurd improvised ring feeling.

- compact rope/mat area;
- warm practical lights;
- lake-world material language retained;
- not professional stadium;
- no crowd wall;
- fish and Darto remain primary focal points.

## 185.17 ARM WRESTLING SET — GOLDEN REFERENCE

- single sturdy table;
- exaggerated elbow pads;
- intimate camera;
- background simple/quiet;
- heroic-comedy framing, not esports arena.

## 185.18 DANCE SET — GOLDEN REFERENCE

- simple warm-lit platform;
- string-light feeling made from generated emissive geometry if performant;
- koplo celebration energy;
- no nightclub/casino neon overload;
- lane UI remains highest readability priority.

## 185.19 SUWIT SET — GOLDEN REFERENCE

- calm table/platform;
- theatrical but understated suspense lighting;
- large readable hand/choice symbols in UI;
- no roulette/casino imagery.

## 185.20 UI GOLDEN REFERENCE

Visual metaphor:

> A tidy handwritten-price-card / warm warung ledger translated into clean digital UI.

Must contain:

- cream/paper panels;
- warm dark text;
- terracotta CTA;
- lake-green calm accent;
- low-opacity shadow;
- rounded but not bubbly corners;
- procedural line icons;
- simple motion.

Must not contain:

- glassmorphism;
- cyber neon;
- glossy mobile-gacha gradients;
- gold coin explosions;
- casino sparkle;
- tiny unreadable text.

## 185.21 REFERENCE SHEET OUTPUT SET

Generator wajib menghasilkan minimal:

```text
generated/references/ref_chr_darto.png
generated/references/ref_chr_rini.png
generated/references/ref_chr_nisa.png
generated/references/ref_chr_bu_yati.png
generated/references/ref_fish_catfish.png
generated/references/ref_fish_tilapia.png
generated/references/ref_fish_gourami.png
generated/references/ref_fish_carp.png
generated/references/ref_fish_snakehead.png
generated/references/ref_fish_arowana.png
generated/references/ref_motor_darto.png
generated/references/ref_set_lake.png
generated/references/ref_set_home.png
generated/references/ref_set_market.png
generated/references/ref_set_boxing.png
generated/references/ref_set_arm.png
generated/references/ref_set_dance.png
generated/references/ref_set_suwit.png
generated/references/ref_ui_master.png
```

Reference render background neutral cream, except environment reference yang memakai final WorldEnvironment.

## 185.22 VISUAL LOCK TEST

Milestone 9 tidak boleh selesai sebelum reference render:

- generated;
- dibandingkan side-by-side dengan Section 185 spec;
- tidak memiliki placeholder primitive look pada hero object;
- silhouette semua fish jelas berbeda;
- Darto/Rini/Nisa/Bu Yati mudah dibedakan;
- environment tetap cozy dan tidak terlalu ramai;
- UI terlihat satu keluarga visual.


---

# 186. APPLICATION IDENTITY & STORE RELEASE BIBLE

Bagian ini mengunci identity product, package naming, store copy, dan release metadata. Persyaratan store yang dapat berubah harus diverifikasi ulang pada Milestone 10.

## 186.1 PRODUCT IDENTITY

Final public title:

> **Mancing Mania: Gelut Edition**

Internal project slug:

`mancing_mania_gelut`

Godot project name:

`Mancing Mania Gelut Edition`

Android application ID baseline:

`com.mancingmania.gelutedition`

Rule:

- sebelum submission pertama, publisher boleh mengganti application ID satu kali jika ada kebutuhan ownership/domain;
- setelah Play Store release pertama, application ID **tidak boleh berubah**;
- semua docs/export presets harus memakai ID yang sama.

## 186.2 VERSIONING

Player-facing version mengikuti Semantic Versioning:

`MAJOR.MINOR.PATCH`

v1.0 release:

`1.0.0`

Android `versionName`:

`1.0.0`

Android `versionCode` formula baseline:

```text
MAJOR * 10000 + MINOR * 100 + PATCH
```

v1.0.0:

`10000`

Pre-release RC tidak dikirim sebagai production final kecuali versionCode meningkat secara valid.

Git tag mengikuti Section 191.

## 186.3 ANDROID PLATFORM BASELINE

Renderer:

**Compatibility**.

Orientation:

**Portrait**.

Minimum OS design baseline:

**Android 7.0 / API 24**, sesuai Compatibility-class minimum target dari Godot 4.7 documentation.

Current Google Play submission baseline pada tanggal dokumen v6:

**target Android 16 / API level 36 atau lebih tinggi** untuk new app/update mulai 31 Agustus 2026.

Production rule:

```text
target_sdk = max(36, current Google Play requirement at release time)
min_sdk = 24 unless selected stable Godot requires higher
```

Milestone 10 wajib memverifikasi kembali requirement Google Play saat tanggal submission. Jika requirement berubah, ikuti requirement store terbaru tanpa mengubah gameplay.

Architecture production:

- `arm64-v8a` wajib;
- architecture tambahan hanya jika ukuran/performance masuk budget dan ada alasan QA.

Permission policy:

- INTERNET hanya jika Godot Web context; Android game tidak memerlukan runtime internet permission untuk gameplay core;
- tidak meminta location;
- tidak meminta camera;
- tidak meminta microphone;
- tidak meminta contacts;
- tidak meminta SMS/call log;
- tidak meminta broad storage;
- tidak meminta advertising ID.

Permission baru otomatis dianggap scope change dan memerlukan privacy review.

## 186.4 ANDROID LAUNCHER IDENTITY

Launcher label:

> Mancing Mania: Gelut Edition

Adaptive icon dibuat programmatically melalui generator project.

Visual icon:

- warm cream/lake background;
- simple low-poly fish silhouette + small boxing glove cue;
- no text kecil;
- no real brand;
- no store badge;
- readable at small size.

Generator outputs required Android launcher layers sesuai format export Godot yang dipakai.

## 186.5 GOOGLE PLAY STORE GRAPHICS

Semua store graphic dibuat dari generated game assets melalui `store_art_generator.gd`; tidak ada stock/internet art.

Add generator:

```text
res://tools/generators/store_art_generator.gd
```

Output:

```text
build/store/google_play/icon_512.png
build/store/google_play/feature_1024x500.png
build/store/google_play/screenshot_01_fishing_1080x1920.png
build/store/google_play/screenshot_02_fish_duel_1080x1920.png
build/store/google_play/screenshot_03_market_1080x1920.png
build/store/google_play/screenshot_04_dance_1080x1920.png
build/store/google_play/screenshot_05_family_or_fishbook_1080x1920.png
```

Current official Play Store baseline:

- store icon: 512×512 PNG, <=1024 KB;
- feature graphic: 1024×500 JPEG/24-bit PNG without alpha;
- minimum two screenshots required;
- project target menyediakan **minimum 4 portrait screenshots** 1080×1920 agar gameplay mudah dibaca.

Store art tidak boleh menampilkan fitur yang tidak ada dalam game.

## 186.6 STORE SCREENSHOT CONTENT

Screenshot 01:

**Fishing calm moment** — lake, Darto, float, warm environment.

Screenshot 02:

**Absurd fish duel** — Bruiser Catfish boxing or Snakehead, readable HUD.

Screenshot 03:

**Market/economy** — Bu Yati + Sell/Debt visual.

Screenshot 04:

**Joget Koplo** — rhythm lanes and fish personality.

Screenshot 05 optional/highly recommended:

**Fish Book / warm family context** without spoiling final ending line.

No screenshot may:

- fake UI;
- use external mockup device frame;
- say `#1`, `BEST`, `SALE`, `DOWNLOAD NOW`;
- imply multiplayer;
- imply real gambling;
- show impossible asset quality not present in build.

## 186.7 GOOGLE PLAY STORE COPY — FINAL ENGLISH

### Short Description

> Catch fish, fight them, sell the catch, and slowly fix Darto's life.

### Full Description

> Darto came to Danau Cempaka for a quiet way to earn honest money.
>
> The fish had other plans.
>
> Cast your line, manage tension, land familiar Indonesian freshwater fish, and then settle the catch through one of four absurd duels: boxing, arm wrestling, koplo dancing, or rock paper scissors.
>
> Win, bring the fish to Bu Yati's small lakeside market, sell your catch, upgrade your gear, and slowly pay down Darto's remaining debt.
>
> Mancing Mania: Gelut Edition is a warm, single-player fishing comedy about small progress, family, and learning to stop looking for shortcuts.
>
> Features:
> • Cozy fishing at Danau Cempaka
> • Six freshwater fish with distinct personalities
> • Four short duel minigames
> • Simple upgrades and debt progression
> • A light narrative about rebuilding trust through consistent effort
> • Endless Free Fishing after the story
> • No ads, no in-app purchases, no loot boxes, and no real-money gambling
> • Playable offline after installation

No marketing superlative yang tidak dapat dibuktikan.

## 186.8 ITCH.IO LISTING COPY — FINAL ENGLISH

Title:

> Mancing Mania: Gelut Edition

Short summary:

> A cozy Sunday-afternoon fishing game where every fish insists on a ridiculous duel before joining the bucket.

Description core:

> Darto is trying to rebuild his life one honest catch at a time. Fish at Danau Cempaka, survive the reel, fight the fish, sell the catch, upgrade your gear, and slowly pay down the debt he left behind.
>
> The lake is calm. The fish are not.

Recommended tags:

```text
Fishing
Cozy
Comedy
3D
Low-poly
Singleplayer
Minigames
Story Rich
Casual
Godot
```

Do not tag:

`Multiplayer`, `Gambling`, `Horror`, `Dating Sim`, atau tag yang tidak menggambarkan game.

## 186.9 WEB PACKAGE RULES — ITCH.IO

Required:

- ZIP;
- `index.html` at ZIP root;
- relative paths;
- case-correct filenames;
- UTF-8 filenames.

Platform limits saat v6 ditulis:

- extracted files <=1000;
- full extracted size <=500 MB;
- individual extracted file <=200 MB;
- path length <=240 characters.

Internal project budgets Section 190 dibuat jauh lebih ketat daripada limit ini.

## 186.10 SUPPORT / PUBLISHER METADATA

Store submission membutuhkan publisher-owned data yang tidak boleh diinvent oleh AI:

```text
publisher_display_name
publisher_support_email
privacy_policy_https_url
optional_support_https_url
```

Values ini disimpan di:

`release/publisher_metadata.example.json`

Actual secret/private contact config tidak boleh dicommit jika owner tidak menginginkannya.

Milestone 10 release validator **harus gagal** jika field wajib masih placeholder.

## 186.11 STORE REQUIREMENT RECHECK

Pada awal Milestone 10, developer wajib mencatat:

```text
Store requirement check date
Google Play target API requirement
Google Play preview asset requirements
Google Play Data Safety requirement
Google Play content rating status
itch.io HTML5 packaging limits
Godot stable version selected
Android export template version
```

Hasil masuk ke:

`docs/store_compliance_report.md`.

---

# 187. PRIVACY, DATA SAFETY & LEGAL RELEASE CONTRACT

Privacy design v1.0 dibuat sengaja sederhana:

> **The game does not collect, transmit, sell, or share personal user data.**

Save, settings, records, Fish Book, dan progression disimpan lokal pada device/browser.

## 187.1 DATA COLLECTION — V1.0

Forbidden v1.0:

- analytics SDK;
- telemetry SDK;
- advertising SDK;
- advertising ID;
- crash reporting cloud SDK;
- account system;
- email collection;
- username/profile collection;
- location;
- contacts;
- photos;
- microphone;
- camera;
- device fingerprinting;
- purchase tracking;
- social graph;
- remote leaderboard;
- cloud save;
- third-party behavioral tracking.

## 187.2 LOCAL DATA

Game may store locally:

- save file;
- settings;
- gameplay statistics;
- Fish Book progress;
- story flags;
- local debug logs on debug builds;
- exported save file only when user explicitly requests export.

Local-only data is not transmitted by the game.

## 187.3 NETWORK BEHAVIOR

Android production game core:

- no backend;
- no API call;
- no analytics endpoint;
- no ad request;
- no remote config;
- no login.

Web build is delivered through itch.io, therefore browser necessarily downloads the game files from the hosting platform, but game code itself does not send gameplay/personal data to a developer backend.

Host platform policies are separate from game code privacy behavior.

## 187.4 GOOGLE PLAY DATA SAFETY

Google Play requires developer to complete Data Safety information for every app and keep it consistent with actual app behavior/privacy policy.

For this v1.0 design, intended declaration is:

- app does not collect developer-controlled user data;
- app does not share developer-controlled user data;
- no account deletion mechanism needed because game has no account;
- no advertising data;
- no financial/payment data;
- no location;
- no personal info.

Final Play Console answers must be checked against actual release binary and any store/platform SDK behavior at submission time.

If any SDK/plugin later collects data, this contract is invalid until GDD, Data Safety, and privacy policy are revised.

## 187.5 PRIVACY POLICY ACCESS

Release requires:

1. privacy policy text accessible **inside the game** from Settings/Credits;
2. publicly accessible HTTPS privacy-policy page linked from Play Console.

Repository contains:

```text
PRIVACY_POLICY.md
release/privacy_policy.html
```

`privacy_policy.html` may be generated from the same source text.

Hosting privacy policy is a publisher submission step and is **not** a runtime game dependency.

## 187.6 FINAL ENGLISH PRIVACY POLICY COPY

Title:

> Privacy Policy — Mancing Mania: Gelut Edition

Body:

> Mancing Mania: Gelut Edition is designed to be played without creating an account and without sending gameplay data to the developer.
>
> **Data collection**
>
> The game does not collect, sell, or share personal information. It does not use advertising SDKs, analytics SDKs, tracking SDKs, location services, camera access, microphone access, contacts, or social login.
>
> **Local save data**
>
> Game progress, settings, records, Fish Book progress, and story progress are stored locally on your device or, for the web version, in browser storage. This information is not transmitted by the game to a developer server.
>
> **Web version**
>
> The web version is hosted by a third-party distribution platform. That platform may process technical information under its own privacy policy when delivering the game files. Mancing Mania: Gelut Edition does not add its own analytics, advertising, or tracking system.
>
> **Save export and import**
>
> If the web build provides manual save export, the save file is created only when you request it. Import reads the file you choose locally in order to restore game progress.
>
> **Children and personal information**
>
> The game does not ask players to provide personal information and does not provide chat, user-generated content, or account features.
>
> **Changes to this policy**
>
> If a future version adds any feature that changes how data is handled, this policy will be updated before that version is released.
>
> **Contact**
>
> For privacy or support questions, contact: [PUBLISHER SUPPORT EMAIL]

Release validator must replace `[PUBLISHER SUPPORT EMAIL]` with verified publisher contact before public submission.

## 187.7 IN-GAME PRIVACY SCREEN

Settings → `PRIVACY` opens scrollable text:

> NO ACCOUNT REQUIRED
> NO ADS
> NO ANALYTICS
> NO PERSONAL DATA COLLECTION BY THE GAME
> SAVE DATA STAYS ON THIS DEVICE/BROWSER

Button:

> READ FULL PRIVACY POLICY

On Android, button may open configured HTTPS policy URL if internet available; privacy summary itself remains available offline.

## 187.8 LEGAL / LICENSE CONTRACT

Because production art/audio/UI is generated internally:

- no third-party asset attribution expected;
- no stock asset license dependency;
- no external music license;
- no external font license.

Godot Engine license/third-party notices required by the engine/export template must remain available as appropriate in `LICENSES.md`/credits.

Any future third-party code dependency requires:

- license review;
- compatible redistribution terms;
- entry in `LICENSES.md`;
- security/release review.

## 187.9 PRIVACY RELEASE GATE

Release blocked if:

- binary requests undeclared permission;
- network endpoint exists without documented reason;
- analytics/ad SDK found;
- privacy policy contradicts binary behavior;
- Data Safety form not completed;
- public privacy URL missing for Play submission;
- publisher contact placeholder remains;
- debug log accidentally includes imported local filenames or sensitive environment path in release UI.

---

# 188. CONTENT RATING & AUDIENCE CONTRACT

Final content rating is assigned through Google Play/IARC and may vary by region. GDD does **not** claim a guaranteed age badge.

Design target:

> **Teen-friendly / intended audience 13+**, while keeping content mild enough to avoid unnecessary mature classification.

## 188.1 CONTENT DISCLOSURE MANIFEST

Accurate release disclosure:

### Violence

Yes, mild stylized/cartoon violence:

- fish boxing Darto;
- Darto counters fish;
- arm wrestling;
- exaggerated KO/exhausted poses.

No:

- blood;
- gore;
- dismemberment;
- realistic injury;
- torture;
- weapon combat;
- human-on-human violence.

### Gambling

Story contains **references to Darto's past online gambling addiction and financial consequences**.

Game does **not** contain:

- simulated betting;
- casino games;
- slots;
- poker;
- roulette;
- wagering currency;
- real-money gambling;
- loot boxes;
- gambling reward loop.

Wheel of Fate only selects one of four minigames, costs no money, and awards no random economic prize.

### Language

No strong profanity.

Mild insults/comedic taunts only.

### Sexual Content

None.

Nisa is a minor and is never sexualized.

### Drugs / Alcohol / Tobacco

None as gameplay/content focus.

`Herbal Tonic` and `Black Coffee` are ordinary fictional/game items and not intoxicant mechanics.

### Fear / Horror

None beyond absurd talking/fighting fish.

No horror imagery.

### User Interaction

None:

- no chat;
- no UGC;
- no user profile;
- no multiplayer.

### Purchases

No IAP.

No ads.

No paid currency.

### Location / Sensitive Data

None.

## 188.2 NARRATIVE SAFETY RULE

Gambling addiction is framed as:

- past harmful behavior;
- source of debt and family strain;
- behavior Darto has stopped;
- something replaced by slow honest work.

Forbidden narrative changes:

- Darto relapses as a playable minigame;
- player receives reward for betting;
- jokes that glamorize loss chasing;
- “win it all back” ending;
- debt collector violence;
- suicide/self-harm implication;
- threats toward family.

## 188.3 STORE QUESTIONNAIRE RULE

Developer must answer IARC/Play content questionnaire **based on actual content**, not desired rating.

At submission:

- disclose mild/cartoon violence truthfully;
- disclose gambling reference if questionnaire wording covers gambling themes/references;
- distinguish reference from simulated gambling where questionnaire allows;
- declare no real-money gambling;
- declare no user interaction;
- declare no IAP if applicable;
- keep questionnaire result/report in `docs/store_compliance_report.md`.

If calculated rating exceeds intended audience target, do not falsify questionnaire. Review the content and decide whether to accept rating or revise content.

## 188.4 AUDIENCE TARGET

Store target audience baseline:

**13+ general audience**, not specifically designed for young children.

Reasons:

- debt/recovery theme;
- past gambling addiction context;
- stylized combat minigames;
- narrative nuance aimed at teens/adults.

Do not market the title as a children's game even though violence is cartoonish.

## 188.5 CONTENT RATING QA

Before release, QA verifies:

- no blood material/particle;
- no strong profanity hidden in dialogue pool;
- no gambling interaction accidentally added;
- no casino-like store UI;
- no IAP button;
- no ad placeholder;
- no sexualized character material/pose;
- content disclosure manifest matches build.


---

# 189. ACCESSIBILITY BIBLE 2.0

Accessibility v1.0 bukan optional polish; ia bagian dari playability contract.

Tujuan:

- game tetap nyaman dibaca;
- input tidak melelahkan secara tidak perlu;
- informasi penting tidak bergantung pada warna/audio saja;
- player dapat mengurangi motion/flash;
- rhythm dapat dikalibrasi;
- mobile layout dapat dipindahkan untuk tangan dominan.

## 189.1 ACCESSIBILITY SETTINGS — REQUIRED

Settings → Accessibility wajib memiliki:

```text
UI SCALE
TEXT SCALE
HIGH CONTRAST HUD
HUD SHAKE
REDUCED MOTION
REDUCED FLASH
RHYTHM BEAT PULSE
RHYTHM CALIBRATION
ARM WRESTLING INPUT MODE
MOBILE HANDEDNESS
DIALOGUE SPEED
HOLD-TO-SKIP DURATION
```

Semua setting disimpan di save/settings dan autosave saat berubah.

## 189.2 UI SCALE

Options:

```text
90%
100% (default)
115%
130%
```

UI scale mengubah container/control scale, bukan render world FOV.

Layout wajib lulus regression test pada:

- 1280×720;
- 1920×1080;
- 720×1280;
- 1080×2400;
- 130% UI scale;
- notch/safe-area simulation.

## 189.3 TEXT SCALE

Options:

```text
100% (default)
115%
130%
150%
```

Text scale tidak boleh memotong button label penting.

Saat 150%:

- dialogue box boleh menjadi lebih tinggi;
- buttons boleh wrap bila perlu;
- scroll container wajib digunakan pada Settings/How To/Credits;
- critical prompt tetap tidak boleh keluar safe area.

## 189.4 HIGH CONTRAST HUD

Default:

`OFF`.

Jika ON:

- HUD panel opacity naik;
- text outline/shadow readability naik;
- tension marker memperoleh shape/border lebih tegas;
- dance lanes memiliki outline + symbol differentiation;
- strike prompt memiliki strong border;
- tidak mengubah world art.

Mode ini bukan sekadar saturation boost.

## 189.5 COLOR-INDEPENDENT INFORMATION

Critical gameplay selalu memakai minimal dua channel:

- color + shape;
- color + text;
- color + motion;
- color + position.

Examples:

- Boxing dodge: arrow/lean direction + optional color;
- Tension: marker position + zone shape;
- Dance: lane position + label/symbol;
- Stress: gauge level + pulse + text warning;
- Suwit: explicit ROCK/SCISSORS/PAPER icon/label.

## 189.6 HUD SHAKE

Options tetap:

```text
ON
REDUCED
OFF
```

`REDUCED` = amplitude 40% baseline.

`OFF` = no HUD shake; other non-shake warning cues remain.

Camera never uses stress shake.

## 189.7 REDUCED MOTION

Default:

`OFF`.

If ON:

- decorative UI overshoot disabled;
- large parallax reduced/disabled;
- camera tween distance/speed reduced;
- Wheel spin may use shorter non-dizzy reveal after first tutorial;
- menu leaf/background decorative motion reduced by ~50%;
- no essential timing mechanic altered;
- fish/gameplay telegraph animation remains readable.

Reduced Motion tidak menghapus animation yang dibutuhkan untuk memahami gameplay.

## 189.8 REDUCED FLASH

Default:

`OFF`.

If ON:

- perfect-dodge flash replaced by border/pose accent;
- full-screen white flash forbidden;
- rapid emissive pulse amplitude reduced;
- warning pulse frequency <=3 Hz;
- rhythm feedback uses outline/scale rather than bright flashing.

Bahkan saat setting OFF, game tidak boleh memakai aggressive strobe effect.

## 189.9 RHYTHM BEAT PULSE

Options:

`ON/OFF`.

Default:

`ON`.

Beat pulse visual berada dekat lane hit line dan tidak memenuhi layar.

Audio bukan satu-satunya timing reference.

## 189.10 RHYTHM CALIBRATION

Settings menyediakan calibration wizard.

Flow:

1. play generated steady click track;
2. player taps 8–16 beats;
3. ignore first 2 warm-up taps;
4. calculate median timing offset;
5. clamp suggested offset to `-150 ms ... +150 ms`;
6. player may accept/reset/manual-adjust.

Stored fields:

```text
rhythm_input_offset_ms
rhythm_visual_offset_ms
```

Default 0.

Calibration does not modify song BPM/chart events; it modifies judgment reference offset consistently.

## 189.11 ARM WRESTLING INPUT MODE

Options:

### MASH

Original gameplay.

### HOLD ASSIST

Holding the action generates accepted virtual pulses at:

`8 presses/sec`.

Rules:

- same stamina cost per generated pulse;
- same stamina recovery after release;
- no score penalty;
- no content/reward difference;
- balance test must keep encounter broadly comparable to manual MASH.

The manual 10 presses/sec cap remains.

Purpose: reduce repetitive strain and enable players unable to mash quickly.

## 189.12 MOBILE HANDEDNESS

Options:

```text
RIGHT-HANDED (default)
LEFT-HANDED
```

Fishing:

- mirror optional Market/action clusters where helpful;
- tension bar may mirror to opposite side;
- core world camera does not mirror.

Boxing:

- control groups can swap left/right screen clusters while labels/actions remain semantically correct.

Suwit/Dance centered layouts need minimal/no mirroring.

## 189.13 DIALOGUE SPEED

Options:

```text
INSTANT
FAST
NORMAL (default)
RELAXED
```

Because dialogue is text-only, this controls reveal animation only.

Any confirm input while line is revealing:

first press → reveal full current line;
second press → advance.

No important line auto-skips due to reveal speed.

## 189.14 SKIP HOLD DURATION

Options:

```text
0.4 sec
0.8 sec (default)
1.2 sec
```

Affects cutscene skip only.

Does not affect long-press gameplay actions.

## 189.15 KEYBOARD REMAPPING — WEB/DESKTOP

Controller/gamepad remains non-goal, but keyboard remapping is required.

Remappable actions:

```text
fish_cast
fish_reel
open_market
open_bucket
pause
box_dodge_left
box_dodge_right
box_jab
box_cross
arm_mash
dance_lane_1
dance_lane_2
dance_lane_3
dance_lane_4
suwit_rock
suwit_scissors
suwit_paper
suwit_charm
ui_confirm
ui_cancel
```

Rules:

- show current binding;
- capture next valid key/button event;
- warn on conflict;
- allow swap or cancel;
- `RESET TO DEFAULTS`;
- never leave `ui_cancel`/pause inaccessible;
- browser-reserved combinations ignored;
- save binding config locally.

## 189.16 TOUCH ACCESSIBILITY

Touch target minimum:

48 logical px.

Preferred critical action:

56–72.

Pressed state visible at touch-down, not only release.

No double-tap requirement for core action.

No swipe gesture required for timing-critical mechanics.

## 189.17 AUDIO ACCESSIBILITY

Separate volume:

```text
MASTER
MUSIC
SFX
AMBIENCE
UI
```

Critical bite cue remains audible under normal mix, but also has visual indicator.

Game must remain mechanically playable with Master volume at 0.

Rhythm mode at volume 0 remains playable via beat pulse + lanes, though audio improves experience.

## 189.18 ACCESSIBILITY QA MATRIX ADDITIONS

Required manual/automated cases:

```text
A11Y-001 150% text no clipped critical button
A11Y-002 130% UI all required screens navigable
A11Y-003 High Contrast HUD differentiates tension/dance states
A11Y-004 HUD Shake OFF produces zero gameplay HUD translation shake
A11Y-005 Reduced Motion removes decorative overshoot but keeps telegraphs
A11Y-006 Reduced Flash has no full-screen flash
A11Y-007 Rhythm calibration persists after reload
A11Y-008 Hold Assist can complete all Arm Wrestling tiers with intended stamina play
A11Y-009 Left-Handed layout respects safe area
A11Y-010 Keyboard remap conflict handling
A11Y-011 Audio muted fishing still provides visual bite state
A11Y-012 Dialogue Instant mode still requires explicit advance
```

---

# 190. HARD PERFORMANCE, MEMORY & PACKAGE BUDGETS

Performance target lama tetap berlaku, tetapi Section 190 memberi **hard production budgets** untuk mencegah AI menambah complexity tanpa batas.

## 190.1 REFERENCE PERFORMANCE TIERS

### Web Reference — Medium

- modern Chromium/Firefox;
- 4-core desktop/laptop CPU class;
- integrated GPU with WebGL2;
- 8 GB system RAM;
- 1280×720 viewport.

Target:

60 FPS.

Minimum acceptable:

30 FPS stable.

### Android Low QA Tier

- Android 7+ capable GLES3 device class;
- 4 GB RAM preferred test floor for this specific 3D game;
- 720×1280;
- LOW preset.

Minimum acceptable:

30 FPS stable during 20-minute session.

### Android Mid QA Tier

- 6 GB RAM modern midrange;
- 1080×2400 or equivalent;
- MEDIUM preset.

Target:

60 FPS with no sustained thermal collapse.

## 190.2 FRAME-TIME BUDGET

60 FPS target:

`16.67 ms/frame`.

30 FPS fallback ceiling:

`33.33 ms/frame`.

Hard rule:

- no sustained >33.33 ms on target Medium device;
- no recurring >100 ms hitch during normal cast/reel/duel loop;
- scene load may exceed one frame but must be hidden behind transition/loading state.

## 190.3 SCENE TRANSITION BUDGET

Reference device warm transition targets:

```text
Fishing -> Wheel <= 1.0 sec perceived
Wheel -> Duel <= 1.5 sec perceived
Duel -> Result <= 1.0 sec perceived
Fishing <-> Market <= 1.5 sec perceived
Main Menu -> Fishing <= 2.5 sec perceived after save loaded
```

Cold startup after executable/Web runtime already loaded:

Main Menu interactive <=5 sec on reference device.

Network download time for first Web visit is reported separately because connection speed is external.

## 190.4 MEMORY BUDGET

Target steady-state memory:

### Web

- preferred <=350 MB;
- soft ceiling 450 MB;
- hard investigation threshold >512 MB.

### Android

- preferred <=400 MB;
- soft ceiling 550 MB;
- hard investigation threshold >700 MB.

A scene transition must not permanently leak memory across 20 repeated transitions.

Leak QA:

Fishing ↔ Market ×20 and Fishing → duel → Result ×20; final memory should return within reasonable cache tolerance of stabilized baseline.

## 190.5 VISIBLE TRIANGLE BUDGET

Existing Section 101 remains authoritative.

Additional target:

- Fishing preferred 120k–220k visible;
- soft ceiling 300k;
- Market preferred <=180k;
- duel set preferred <=160k plus characters/fish;
- Low preset may cull/reduce vegetation aggressively.

## 190.6 DRAW CALL BUDGET

Approximate preferred visible draw calls on MEDIUM:

```text
Fishing <= 220
Market <= 180
Boxing <= 160
Arm Wrestling <= 150
Dance <= 180
Suwit <= 140
Story Home <= 160
```

Soft ceiling:

`300` any normal gameplay scene.

Exceeding preferred budget requires profiler evidence that target performance remains stable.

## 190.7 MATERIAL BUDGET

- hero human: 1–3 materials;
- regular fish: 1–2 plus accessory where needed;
- Arowana: <=3;
- repeated environment props reuse shared materials;
- transparency only when necessary;
- no unique material per grass blade/prop instance.

## 190.8 PROCEDURAL TEXTURE BUDGET

Generated textures:

- most 256–1024;
- 2048 only hero/store/reference output if justified;
- no 4K runtime dependency;
- avoid uncompressed massive ImageTexture retained in RAM after bake unless needed;
- free generator source images after final resource is created.

## 190.9 PARTICLE BUDGET

Gameplay-visible simultaneous particle systems:

- Fishing <=6 active systems;
- duel <=8;
- Market <=4.

Particle count per effect should remain visually modest.

Low preset:

- reduce particle amount 50–70%;
- decorative particles may be disabled;
- gameplay indicator particles remain.

## 190.10 PROCEDURAL AUDIO CPU BUDGET

Maximum simultaneous logical voices:

`32`.

Preferred normal gameplay:

`<=20`.

Breakdown target:

```text
Music generator: <=8 voices/layers
Ambience: <=6
Gameplay SFX: <=8 transient
UI: <=4 transient
Reserve: 6
```

Audio synthesis must not allocate large arrays every audio callback.

Use reusable buffers/ring buffers where appropriate.

Audio generation CPU target:

- average <=2 ms/frame-equivalent on reference Medium hardware;
- no audio-thread starvation;
- no crackle under normal 60/30 FPS render stress.

## 190.11 SAVE SIZE / WRITE BUDGET

Target save JSON:

`<256 KB` typical.

Soft ceiling:

`1 MB`.

Autosave should not create visible >100 ms freeze on reference device.

Do not store screenshots/audio/large logs inside save.

## 190.12 WEB PACKAGE INTERNAL BUDGET

Official itch.io platform limit may be larger, but project budget is:

```text
ZIP target <= 75 MB
Extracted target <= 160 MB
Largest extracted file target <= 120 MB
Extracted file count target <= 500
Path length internal target <= 180 chars
```

Hard release gate:

must also stay within current itch.io official limits verified at Milestone 10.

Because assets are procedural and no external media pack exists, exceeding 75 MB is considered a regression requiring investigation.

## 190.13 ANDROID PACKAGE BUDGET

Release AAB target:

`<=100 MB`.

Preferred:

`<=80 MB`.

If AAB exceeds 100 MB:

- investigate generated textures;
- duplicate resources;
- debug artifacts;
- unnecessary architectures;
- accidental source/reference inclusion.

Do not solve by removing required gameplay content first.

## 190.14 GENERATED REFERENCE ART EXCLUSION

High-resolution reference sheets and store-art intermediates are **not runtime assets** unless explicitly required.

Export preset excludes:

- `generated/references/` development-only source if not runtime required;
- debug screenshots;
- QA captures;
- source generation manifests not required at runtime;
- test fixtures unnecessary in release package.

Source repository may retain them.

## 190.15 BOOT / SHADER STUTTER RULE

Critical shaders/material variants should be warmed at Boot or first calm fishing idle period if profiling shows compile hitch.

No duel should begin with a multi-second shader compilation freeze.

## 190.16 LONG SESSION TEST

Required:

- 30 min Android;
- 30 min Web tab active;
- repeated 20 duel transitions;
- repeated 20 Market transitions;
- audio active throughout;
- save operations throughout.

Fail if:

- progressive FPS degradation >20% without thermal explanation;
- uncontrolled memory growth;
- audio crackle accumulation;
- input delay growth;
- stale scene reference crash.

## 190.17 PERFORMANCE GATE REPORT

`docs/performance_report.md` records:

```text
build version
device/browser
resolution
quality preset
average FPS
1% low or equivalent frame-time observation
peak memory
draw calls
visible triangles
package size
scene transition timings
audio voice peak
known bottleneck
```

Milestone 10 cannot pass with unknown performance on both target platforms.

---

# 191. REPOSITORY, VERSIONING & CHANGE-CONTROL CONTRACT

Repository must support safe incremental AI development across 10 milestones.

## 191.1 VCS

Version control:

**Git**.

Primary branch:

`main`

`main` must always represent the latest milestone state that passed its exit gate, except during explicit release stabilization commits.

## 191.2 BRANCH NAMING

Milestone branches:

```text
milestone/01-foundation
milestone/02-fishing-core
milestone/03-market-progression
milestone/04-boxing
milestone/05-arm-wrestling
milestone/06-dance
milestone/07-suwit
milestone/08-story-save
milestone/09-art-audio-polish
milestone/10-release
```

Fix branches:

`fix/<short-description>`

Release branch only if needed:

`release/1.0.0`

Do not create unnecessary long-lived branches.

## 191.3 MILESTONE TAGS

After exit gate pass and merge to `main`:

```text
v0.1.0-m1
v0.2.0-m2
v0.3.0-m3
v0.4.0-m4
v0.5.0-m5
v0.6.0-m6
v0.7.0-m7
v0.8.0-m8
v0.9.0-m9
v1.0.0-rc1
v1.0.0
```

Additional RC increments:

`v1.0.0-rc2`, etc.

Final tag `v1.0.0` only after Sections 182, 191.17, 192–196 pass dan Gold Master disetujui menurut Section 194.

## 191.4 COMMIT STYLE

Preferred conventional prefixes:

```text
feat:
fix:
test:
refactor:
perf:
docs:
chore:
balance:
artgen:
audiogen:
```

Examples:

```text
feat: implement deterministic fishing encounter state machine
artgen: generate final catfish rig and materials
fix: preserve pending story queue after autosave
balance: tune snakehead boxing telegraph to authoritative value
```

Commit message must describe actual change, not `update stuff`.

## 191.5 COMMIT SIZE RULE

AI should prefer coherent commits that:

- compile/run;
- correspond to one functional change;
- include test changes when behavior changes;
- do not mix unrelated massive formatting changes.

No “one entire milestone in one unreviewable commit” unless environment prevents intermediate commits.

## 191.6 REQUIRED `.gitignore`

Minimum ignore:

```text
.godot/
.import/
export/
build/web/
build/android/
build/tmp/
*.apk
*.aab
*.keystore
*.jks
.env
.env.*
.DS_Store
Thumbs.db
```

Store release images under `build/store/` may be generated artifacts and normally ignored unless owner intentionally wants them versioned.

`project.godot`, `.gd`, `.tscn`, `.tres`, generator source, docs, tests, and authoritative generated runtime resources must be tracked.

## 191.7 SECRET POLICY

Never commit:

- release keystore;
- keystore password;
- Play Console service account key;
- API token;
- personal credentials;
- private signing material.

Use environment/local secure config.

Repository contains only examples:

`release/signing.example.env`.

## 191.8 THIRD-PARTY DEPENDENCY POLICY

Default:

**zero third-party Godot addons required for v1.0**.

`addons/` directory should be empty or contain first-party project code only.

Adding external dependency requires explicit revision because it can change:

- licensing;
- Web compatibility;
- Android compatibility;
- privacy;
- package size;
- maintenance risk.

## 191.9 GENERATED ASSET REPO POLICY

Generator source is authoritative.

Generated runtime output may be committed for fast clean checkout.

Each generated output must have provenance in `generator_manifest.json`.

Do not manually edit generated file if source generator/data can express the change.

Workflow:

1. edit generator/source data;
2. regenerate;
3. run generator validation;
4. inspect reference sheet;
5. commit source + intended generated diff.

## 191.10 BINARY POLICY

Prefer text Godot resources where practical:

- `.tscn`;
- `.tres`.

Use binary `.res` only when materially beneficial.

No Git LFS dependency by default.

If repository size later genuinely requires LFS, that is infrastructure change requiring documentation; release build cannot depend on network LFS fetch at runtime.

## 191.11 SAVE COMPATIBILITY POLICY

From first public v1.0 release onward:

- patch/minor updates must not silently invalidate valid v1.0 save;
- schema migration required when schema changes;
- migration must be tested;
- backup before migration;
- do not reuse old field with new incompatible meaning;
- never decrease `save_version`.

Pre-release milestone saves may be invalidated only if clearly documented before public release.

## 191.12 BALANCE CHANGE CONTROL

Authoritative numeric balance in GDD/resource cannot be changed just because a developer “feels better” without evidence.

Balance change requires:

```text
reason
old value
new value
simulation/manual evidence
affected tests
save compatibility impact if any
```

Record in:

`docs/balance_changes.md`.

## 191.13 DESIGN CHANGE CONTROL

Any proposed feature outside v1.0 scope goes to:

`docs/post_v1_backlog.md`

It must not be implemented “while already touching the code”.

If owner approves a v1.0 design change:

1. update GDD authoritative section;
2. update content manifest if needed;
3. update tests;
4. update save/schema if needed;
5. update milestone scope;
6. then implement.

## 191.14 REGRESSION RULE

A milestone N change may fix milestone <N, but must rerun relevant previous tests.

If core shared service changes:

- SaveManager → rerun save/economy/story tests;
- RNGService → rerun encounter/duel determinism tests;
- InputManager → rerun all duel/fishing input smoke tests;
- AudioManager → rerun all audio/rhythm tests;
- GameState → rerun transactions/save/story progression;
- generator core → regenerate all affected assets + visual QA.

## 191.15 AI HANDOFF PER MILESTONE

Every milestone completion response/report must state:

```text
Milestone
Branch/commit/tag if available
Files added
Files modified
Generated assets changed
Tests run
Tests passed/failed
Manual checks performed
Known issues
Performance observations
Save schema change: yes/no
GDD deviation: yes/no
Next milestone prerequisites
```

If GDD deviation is `yes`, milestone cannot be silently accepted; deviation must be explained.

## 191.16 RELEASE BRANCH HYGIENE

Before `v1.0.0`:

- working tree clean;
- no untracked production-critical files;
- no secrets;
- no debug cheat enabled in release;
- no temporary export preset;
- no placeholder publisher metadata;
- no TODO/FIXME release blocker;
- generated manifest matches committed output;
- full tests pass;
- `CHANGELOG.md` updated;
- `LICENSES.md` updated;
- privacy/store compliance docs complete.

## 191.17 V6 FINAL PRODUCTION GATE

In addition to Section 182, v1.0 release candidate requires:

- Section 183 narrative completeness pass;
- Section 184 zero-internet-asset pass;
- Section 185 reference visual lock pass;
- Section 186 store identity/compliance metadata pass;
- Section 187 privacy/data-safety pass;
- Section 188 content-rating disclosure pass;
- Section 189 accessibility pass;
- Section 190 performance/package budget pass;
- Section 191 repository/release hygiene pass.

Only then project may enter:

# `V1.0 RELEASE CANDIDATE — COMPLETE`

Publication masih dilarang sampai Section 192 Human Playtest, Section 193 Bug Gate, Section 194 Gold Master Contract, Section 195 Master Release Checklist, dan Section 196 Provenance Gate juga lulus. Section 197 mengatur maintenance setelah publish.

---

# V6 PRE-GOLD-MASTER PRODUCTION NORTH STAR

Jika AI/developer ragu terhadap keputusan, gunakan urutan:

1. Apakah sesuai creative north star Section 162?
2. Apakah tetap cozy sebelum chaos?
3. Apakah feature benar-benar berada dalam v1.0 scope?
4. Apakah menjaga tema honest progress dan tidak mengubah gambling menjadi reward?
5. Apakah mengikuti exact content/narrative contract?
6. Apakah asset dapat dibuat ulang **tanpa internet** dari repository?
7. Apakah readable, accessible, dan playable?
8. Apakah menjaga balance authoritative?
9. Apakah memenuhi Web itch.io + Android Google Play constraints saat ini?
10. Apakah dapat diuji dan direproduksi dari clean checkout?

Jika jawabannya tidak jelas, pilih solusi paling sederhana yang patuh GDD dan **jangan menambah fitur baru**.
---

# 192. HUMAN PLAYTEST & USABILITY PROTOCOL

Section ini adalah kontrak final untuk validasi **manusia nyata**. Automated test, simulator, profiler, AI review, dan developer familiarity tidak dapat menggantikan human playtest.

Tujuan utamanya bukan mencari opini sebanyak mungkin, tetapi memastikan game benar-benar:

- mudah dipahami tanpa penjelasan developer;
- nyaman dimainkan pada Web dan Android;
- mempertahankan rasa warm, cozy, Sunday afternoon;
- membuat duel terasa lucu dan readable, bukan melelahkan atau membingungkan;
- menyampaikan tema honest progress tanpa menjadi khutbah atau debt simulator;
- dapat diselesaikan oleh pemain biasa tanpa pengetahuan internal project.

## 192.1 HUMAN-ONLY GATE

Human playtest adalah **manual external validation gate**.

AI/developer boleh:

- menyiapkan build;
- menyiapkan form;
- mengumpulkan metric dari observasi yang diberikan tester;
- merangkum feedback;
- menghubungkan feedback ke bug/test case.

AI/developer tidak boleh:

- mengklaim telah melakukan human playtest jika tidak ada manusia yang benar-benar memainkan build;
- mengarang participant;
- mengarang hasil usability;
- mengganti human observation dengan simulated bot playthrough.

Jika belum ada human playtest, status release tidak boleh melewati:

`V1.0 RELEASE CANDIDATE — HUMAN PLAYTEST PENDING`.

## 192.2 PLAYTEST STAGES

Minimal terdapat lima stage validasi.

### Stage A — Internal Smoke Play

Dilakukan setelah core loop playable.

Tujuan:

- memastikan build cukup stabil untuk diberikan kepada orang lain;
- memastikan tutorial dapat dijalankan;
- menghindari membuang waktu tester karena crash obvious.

Stage ini **bukan** external usability validation.

### Stage B — First-Time Player Test

Tester tidak membaca GDD dan tidak mendapat penjelasan mekanik sebelum bermain.

Target:

- memahami cast;
- memahami strike;
- memahami reel;
- memahami bahwa fish memicu duel;
- memahami Market;
- menjual fish;
- membayar hutang;
- memahami tujuan game.

### Stage C — Duel Readability Test

Menguji seluruh empat duel.

Fokus:

- Boxing telegraph;
- Arm Wrestling stamina/rest rhythm;
- Dance timing/readability;
- Suwit tell/reveal rule;
- touch control dan keyboard parity.

### Stage D — Platform Comfort Test

Dilakukan pada:

- Web keyboard + mouse;
- Android touch portrait.

Fokus:

- touch reachability;
- text readability;
- safe area;
- focus/background behavior;
- control fatigue;
- audio balance pada speaker/headphone biasa.

### Stage E — Release Candidate Full-Flow Test

Tester menggunakan RC build tanpa debug assistance.

Minimal mencakup:

- New Game;
- first 10–15 minutes;
- beberapa Market visit;
- upgrade purchase;
- save/quit/continue;
- beberapa duel berbeda;
- story milestone;
- satu sesi minimum 25–40 menit;
- jika tester tersedia untuk full run: debt completion + ending.

## 192.3 PARTICIPANT TARGET

Target minimum sebelum Gold Master:

- **12 unique human participants total** sepanjang project;
- minimal 6 memainkan Web build;
- minimal 6 memainkan Android build;
- participant boleh overlap platform sehingga total unique tetap 12;
- minimal 8 participant merupakan first-time player yang tidak terlibat langsung dalam implementasi;
- minimal 3 participant memainkan game dengan perangkat Android fisik berbeda;
- minimal 2 participant secara khusus menjalankan accessibility options.

Lebih banyak participant diperbolehkan tetapi bukan alasan untuk menunda perbaikan masalah yang sudah jelas.

## 192.4 PARTICIPANT PROFILE

Tidak perlu gamer hardcore.

Idealnya mencakup campuran:

- casual player;
- pemain game mobile;
- pemain browser/itch.io;
- orang yang jarang bermain rhythm game;
- orang yang tidak familiar dengan project;
- minimal satu orang yang sensitif terhadap motion/flash bila tersedia secara sukarela.

Tidak meminta atau menyimpan sensitive demographic data yang tidak relevan.

## 192.5 PRIVACY & CONSENT

Playtest manual mengikuti prinsip privacy Section 187.

Gunakan participant ID anonim:

```text
T01
T02
T03
...
```

Jangan menyimpan:

- nama lengkap jika tidak diperlukan;
- alamat;
- nomor telepon;
- account credential;
- health data;
- rekaman audio/video tanpa izin eksplisit.

Jika screen recording digunakan:

- participant harus tahu;
- recording hanya untuk QA;
- hapus ketika tidak lagi dibutuhkan;
- jangan upload public tanpa izin.

## 192.6 TEST SETUP RULE

Tester mendapat:

1. build;
2. instruksi cara launch/install saja;
3. tidak diberi penjelasan gameplay kecuali benar-benar stuck setelah observation dicatat.

Developer observer tidak boleh berkata:

- “tekan tombol itu”;
- “seharusnya kamu pergi ke Market”;
- “ikan ini caranya begini”;

sebelum usability failure tercatat.

Jika tester meminta bantuan, catat:

```text
HELP_REQUESTED = yes
context = ...
time_from_start = ...
```

baru bantu seperlunya.

## 192.7 FIRST 12-MINUTE OBSERVATION

Untuk first-time test, ukur:

```text
T_cast_understood
T_first_successful_strike
T_first_fish_landed
T_first_duel_understood
T_market_found
T_first_sale
T_first_debt_payment
```

Juga catat:

- jumlah premature strike;
- jumlah tutorial retry;
- apakah tester mencoba tombol salah berulang;
- apakah tester menyadari fish harus dilawan;
- apakah tester memahami fish masuk Bucket hanya setelah menang;
- apakah tester memahami uang berasal dari menjual catch;
- apakah tester memahami hutang adalah progression utama.

## 192.8 SUCCESS THRESHOLDS

Sebelum Gold Master, target usability minimum:

- >=90% first-time tester dapat menjelaskan core loop dengan benar setelah 12 menit;
- >=80% dapat menyelesaikan first fishing tutorial tanpa intervention developer;
- >=80% dapat menemukan/menyelesaikan first sale tanpa intervention;
- >=80% memahami fungsi debt payment setelah tutorial Market;
- tidak ada satu critical control yang membingungkan >20% tester;
- tidak ada repeated reports bahwa text terlalu kecil pada supported reference device;
- tidak ada repeated reports bahwa Panco membutuhkan mash yang menyakitkan setelah Hold Assist tersedia;
- tidak ada repeated reports bahwa flash/motion tetap mengganggu setelah accessibility option diaktifkan.

Threshold adalah release signal, bukan alasan mengabaikan feedback individual yang serius.

## 192.9 SUBJECTIVE EXPERIENCE QUESTIONS

Setelah sesi, gunakan skala 1–5 untuk:

```text
Fishing felt relaxing
Fishing controls felt understandable
Duels felt readable
Duels felt fair
Market/economy felt understandable
Upgrades felt meaningful
Game felt warm/cozy
Humor felt natural
Story felt sincere rather than preachy
I understood what Darto was trying to accomplish
I would willingly play another session
```

Jangan mengejar skor sempurna.

Investigasi jika median salah satu item berikut <4:

- controls understandable;
- duels readable;
- Market/economy understandable;
- warm/cozy identity.

## 192.10 OPEN QUESTIONS

Tanyakan singkat:

- “What confused you most?”
- “What felt best?”
- “What felt slow or annoying?”
- “Was any joke repeated too much?”
- “Did any duel feel unfair?”
- “What did you think the goal of the game was?”
- “Was there any moment you wanted to stop playing?”

Jangan leading question seperti:

> “The fishing felt cozy, right?”

## 192.11 FEEDBACK CLASSIFICATION

Setiap feedback diklasifikasikan:

```text
BUG
USABILITY
ACCESSIBILITY
BALANCE
PACING
NARRATIVE
VISUAL
AUDIO
PREFERENCE_ONLY
OUT_OF_SCOPE_REQUEST
```

`OUT_OF_SCOPE_REQUEST` tidak otomatis menjadi fitur.

Contoh:

> “It would be cool if there were multiplayer boats.”

masuk backlog post-v1, bukan perubahan v1.0.

## 192.12 REPEATED SIGNAL RULE

Jika dua atau lebih first-time tester secara independen gagal pada titik yang sama:

- treat as design/usability signal;
- jangan langsung menyalahkan player;
- buat issue;
- investigasi prompt/layout/timing/control;
- retest setelah fix.

Satu feedback tetap dapat menjadi P0/P1 jika menyebabkan crash, data loss, motion sickness serius, atau accessibility blocker.

## 192.13 PLAYTEST BUILD RULE

Playtest build:

- berasal dari tagged/identified commit;
- mempunyai build version visible di debug/about;
- debug cheat hidden kecuali test session memang memerlukannya;
- memakai save schema release-compatible;
- tidak boleh memakai fake result untuk first-time usability test.

Seeded debug encounter diperbolehkan untuk Duel Readability Test.

## 192.14 PLAYTEST REPORT

Wajib dibuat:

`docs/playtest_report.md`

Format minimal:

```text
Build/commit:
Date:
Participant IDs:
Platforms/devices:
Test stage:
Tasks attempted:
Task success rates:
Median subjective ratings:
Top confusion points:
Accessibility observations:
Bugs discovered:
Changes made:
Retest status:
Open release blockers:
```

## 192.15 HUMAN PLAYTEST RELEASE GATE

Gold Master blocked jika:

- minimum participant target belum tercapai;
- first-12-minute core loop comprehension <90%;
- first tutorial completion <80%;
- repeated P1 usability blocker belum diperbaiki;
- accessibility blocker diketahui tetapi belum ditangani;
- report belum dibuat.

Owner dapat menerima subjective preference disagreement, tetapi tidak boleh waive crash/data-loss/core-control blocker sebagai “selera”.

---

# 193. BUG TRIAGE & SEVERITY CONTRACT

Semua defect menggunakan satu severity system yang konsisten.

Tujuan:

- release decision tidak berdasarkan mood;
- bug kritis tidak tenggelam oleh cosmetic issue;
- AI/developer tidak boleh menandai issue selesai tanpa verification.

## 193.1 SEVERITY LEVELS

### BLOCKER

Release/build process tidak dapat dilanjutkan sama sekali.

Contoh:

- project tidak parse/open;
- Web export gagal total;
- Android export tidak dapat dibuat karena project config rusak;
- generator mandatory gagal sehingga asset utama tidak ada;
- automated suite tidak dapat berjalan karena test infrastructure rusak;
- repository kehilangan production-critical source.

Release status:

**STOP IMMEDIATELY.**

### P0 — CRITICAL

Game dapat dibuild tetapi player berisiko kehilangan progression atau core game tidak dapat diselesaikan.

Contoh:

- reproducible crash pada normal core flow;
- save corruption;
- valid save tidak dapat dimuat setelah patch;
- debt menjadi negatif/invalid;
- story softlock;
- duel tidak pernah dapat selesai;
- player terjebak scene;
- purchase menghapus cash tanpa memberikan upgrade;
- ending tidak dapat dicapai;
- privacy/security violation aktual;
- release build mengandung secret.

Release status:

**NO RC/GM.**

### P1 — MAJOR

Tidak menghancurkan seluruh game tetapi secara material merusak pengalaman utama, platform utama, accessibility, atau correctness.

Contoh:

- input utama kadang tidak register pada supported device;
- Market tab utama unusable pada common resolution;
- one duel sangat unfair karena telegraph rusak;
- audio rhythm desync besar;
- serious performance drop di bawah minimum target;
- touch controls overlap pada common Android aspect;
- story event penting tidak muncul tetapi progression masih mungkin;
- accessibility setting tidak berfungsi;
- major visual asset hilang tetapi game tidak crash.

Release status:

Target **zero known P1 core issue** untuk Gold Master.

### P2 — NORMAL

Defect nyata tetapi mempunyai workaround mudah atau tidak mengganggu core flow secara material.

Contoh:

- animation clipping sesekali;
- minor layout overflow pada uncommon viewport;
- ambience event terlalu sering;
- noncritical stat label salah format;
- small lighting pop;
- rare cosmetic state mismatch.

Release status:

Boleh masuk known issues jika terdokumentasi dan owner menerima.

### P3 — COSMETIC / POLISH

Tidak memengaruhi correctness/playability.

Contoh:

- tiny prop intersection;
- minor spacing inconsistency;
- subtle animation pop;
- harmless punctuation typo;
- decorative visual imperfection.

Release status:

Tidak memblokir release.

## 193.2 SEVERITY IS IMPACT, NOT DIFFICULTY

Bug mudah diperbaiki belum tentu rendah severity.

Bug sulit diperbaiki belum tentu tinggi severity.

Severity ditentukan dari:

- player impact;
- data loss risk;
- progression impact;
- platform reach;
- accessibility impact;
- legal/privacy/release impact.

## 193.3 ISSUE REQUIRED FIELDS

Setiap issue minimal berisi:

```text
ID
Title
Severity
Status
Build version
Commit
Platform
Device/browser
Save state
Repro steps
Expected
Actual
Reproduction rate
Screenshot/log/repro state if available
Related test IDs
Owner/assignee if applicable
Fix commit
Verification result
```

## 193.4 ISSUE STATUS

Allowed:

```text
NEW
TRIAGED
IN_PROGRESS
FIX_READY
VERIFYING
CLOSED
CANNOT_REPRODUCE
DUPLICATE
DEFERRED_POST_V1
WONT_FIX_APPROVED
```

`CLOSED` hanya setelah verification.

## 193.5 REPRODUCTION RATE

Catat:

```text
ALWAYS = 100%
FREQUENT = >=50%
INTERMITTENT = 10–49%
RARE = <10%
UNKNOWN
```

Rare crash/data loss tetap dapat P0.

## 193.6 BUG REPORT REPRO STATE

Jika memungkinkan gunakan DebugService `COPY REPRO STATE`.

Attach:

- session seed;
- encounter seed;
- fish ID;
- duel type;
- story state;
- relevant upgrade levels;
- cash/debt summary;
- viewport class;
- platform;
- build version.

Jangan attach personal credential.

## 193.7 TRIAGE ORDER

Default triage:

1. BLOCKER;
2. P0;
3. P1 core/save/platform/accessibility;
4. P1 other;
5. P2;
6. P3.

Within same severity prioritize:

- higher reproduction rate;
- more common platform/device;
- earlier core loop;
- regression introduced by recent change.

## 193.8 FIX CONTRACT

Setiap fix harus:

1. reproduce issue sebelum fix bila possible;
2. identify root cause;
3. implement minimal safe fix;
4. add/extend automated regression test jika automatable;
5. rerun related tests;
6. verify pada platform relevan;
7. close issue hanya setelah verification.

Jangan memperbaiki cosmetic bug dengan refactor besar menjelang Gold Master jika risikonya lebih tinggi.

## 193.9 REGRESSION ESCALATION

Bug yang sebelumnya fixed lalu kembali:

- label `REGRESSION`;
- severity minimal sama dengan impact current;
- investigate why test failed to catch it;
- add regression protection.

## 193.10 CANNOT REPRODUCE

`CANNOT_REPRODUCE` bukan sinonim `CLOSED`.

Harus mencatat:

- build yang diuji;
- platform;
- attempts;
- logs/repro state yang tersedia.

P0/P1 cannot-reproduce tetap dipantau sampai cukup evidence atau owner explicitly resolves.

## 193.11 WONT FIX / DEFERRED RULE

BLOCKER/P0:

- tidak boleh WONT_FIX untuk v1.0.

P1 core:

- tidak boleh WONT_FIX untuk Gold Master.

P1 non-core:

- hanya dengan owner written waiver di `docs/qa_release_report.md`.

P2/P3:

- boleh deferred dengan alasan.

## 193.12 KNOWN ISSUES FILE

Release candidate membuat:

`docs/known_issues.md`

Setiap issue mencantumkan:

- severity;
- player impact;
- workaround jika ada;
- target fix/deferred status.

File kosong diperbolehkan jika tidak ada known issue.

## 193.13 RELEASE BUG GATE

Gold Master requires:

- zero BLOCKER;
- zero known P0;
- zero known P1 core-flow/save/platform/accessibility issue;
- setiap remaining P1 non-core memiliki explicit owner waiver;
- remaining P2/P3 documented;
- regression suite pass.

---

# 194. RELEASE CANDIDATE, CONTENT FREEZE & GOLD MASTER CONTRACT

Section ini membedakan tiga hal yang sebelumnya sering tercampur:

- implementation selesai;
- release candidate valid;
- build benar-benar disetujui untuk publish.

## 194.1 RELEASE STATES

Allowed project status:

```text
MILESTONE IN PROGRESS
IMPLEMENTATION COMPLETE — QA NOT YET PASSED
V1.0 RELEASE CANDIDATE — HUMAN PLAYTEST PENDING
V1.0 RELEASE CANDIDATE — COMPLETE
V1.0 GOLD MASTER — APPROVED
V1.0 PUBLISHED
V1.0.x MAINTENANCE
```

Tidak menggunakan `DONE` secara informal sebagai pengganti state ini.

## 194.2 FEATURE COMPLETE

Project menjadi feature complete ketika:

- Milestone 1–9 exit gate lulus;
- seluruh v1.0 content manifest ada;
- no required placeholder;
- Section 183 narrative complete;
- Section 184 generation complete.

Feature complete **bukan release candidate**.

## 194.3 RC1 ENTRY

RC1 hanya dibuat jika:

- Milestone 10 implementation selesai;
- all automated P0 suite pass;
- full story path dapat selesai;
- Web export dibuat;
- Android validation build dibuat;
- privacy/store metadata draft final;
- no BLOCKER/P0 known at creation time.

Tag:

`v1.0.0-rc1`

RC berikut:

`v1.0.0-rc2`, `rc3`, dan seterusnya.

## 194.4 CONTENT FREEZE

**Content Freeze dimulai saat RC1.**

Setelah freeze, dilarang tanpa explicit owner approval:

- menambah fish;
- menambah upgrade;
- menambah duel;
- menambah story scene;
- menulis ulang dialog hanya karena selera;
- mengubah art direction;
- mengubah UI hierarchy besar;
- mengubah economy/balance tanpa bug/balance evidence;
- refactor architecture besar;
- mengganti generator technology;
- menambah dependency.

## 194.5 ALLOWED POST-FREEZE CHANGES

Setelah RC1 hanya boleh:

- fix BLOCKER/P0/P1;
- fix P2 yang low-risk dan jelas;
- legal/privacy/store compliance correction;
- accessibility blocker correction;
- performance fix untuk memenuhi minimum budget;
- typo/error data yang unambiguous;
- release metadata correction;
- regression-test addition.

P3 polish tidak boleh menyebabkan high-risk code churn.

## 194.6 RC CHANGE RULE

Setiap code/content change setelah RC tag:

1. commit fix;
2. rerun affected tests;
3. run release smoke;
4. increment RC number;
5. generate new manifests/checksums;
6. invalidate prior RC approval.

Tidak patch binary manual setelah tag.

## 194.7 FULL REGRESSION TRIGGERS

Full regression wajib jika menyentuh:

- GameState;
- SaveManager/schema;
- RNGService;
- SceneRouter;
- InputManager;
- AudioManager/rhythm clock;
- generator core;
- story arbitration;
- transaction/economy;
- export config;
- platform lifecycle.

## 194.8 GOLD MASTER DEFINITION

Gold Master adalah **exact source commit + generated assets + configuration + release artifacts** yang disetujui untuk publication.

Gold Master tidak berarti “latest local folder”.

## 194.9 GOLD MASTER ENTRY GATES

`V1.0 GOLD MASTER — APPROVED` hanya boleh diberikan jika:

- Section 182 complete;
- Section 191.17 pass;
- Section 192 human playtest pass;
- Section 193 bug gate pass;
- Section 195 release checklist critical items checked;
- Section 196 provenance manifest complete;
- privacy/support email finalized;
- IARC/content rating process ready/completed as applicable;
- Web final package exists;
- Android final signed AAB exists jika signing credential tersedia pada owner environment;
- all P0 pass;
- zero known P1 core;
- working tree clean;
- tag prepared;
- release notes final.

## 194.10 GOLD MASTER TAG

Final source tag:

`v1.0.0`

Tag menunjuk tepat ke commit Gold Master.

Tag tidak dipindahkan setelah publication.

Jika masalah ditemukan setelah tag sebelum publish:

- jangan retag existing `v1.0.0` diam-diam;
- jika belum public dan repository policy memungkinkan, gunakan documented replacement candidate sebelum final release tag dibuat;
- setelah `v1.0.0` dipublish, fix menjadi `v1.0.1`.

## 194.11 GOLD MASTER ARTIFACT SET

Archive:

```text
release/v1.0.0/
  source_commit.txt
  build_manifest.json
  release_manifest.json
  generator_manifest.json
  checksums.sha256
  web/
    mancing-mania-gelut-edition-web-v1.0.0.zip
  android/
    MancingManiaGelut-v1.0.0.aab
  store/
    play/
    itch/
  docs/
    qa_release_report.md
    playtest_report.md
    known_issues.md
    privacy_policy.md
    content_rating_disclosure.md
    balance_simulation_report.md
```

Secret/keystore tidak masuk archive repository.

## 194.12 FINAL RELEASE NOTES

`CHANGELOG.md` v1.0.0 minimal menyebut:

- initial release;
- platforms;
- core gameplay summary;
- save behavior;
- known issues bila ada;
- privacy/no-data-collection summary;
- support contact.

## 194.13 NO LAST-MINUTE FEATURE RULE

Setelah Gold Master candidate dipilih:

> **No “small feature” is small enough to bypass the release process.**

Ide baru masuk `docs/post_v1_backlog.md`.

## 194.14 GOLD MASTER FINAL STATUS

Hanya ketika semua gate di Section 194.9 terpenuhi:

# `V1.0 GOLD MASTER — APPROVED`

Status ini adalah otorisasi teknis untuk publication.

---

# 195. MASTER RELEASE CHECKLIST

Checklist ini harus dicopy ke:

`docs/release_checklist_v1.0.md`

untuk final release dan diisi dengan `[x]`, nama/initial verifier bila relevan, build, dan tanggal verification.

Critical item bertanda **[CRITICAL]** memblokir Gold Master jika belum checked.

## 195.1 SOURCE & REPOSITORY

- [ ] **[CRITICAL]** working tree clean.
- [ ] **[CRITICAL]** correct release branch checked out.
- [ ] **[CRITICAL]** all intended commits pushed/backed up.
- [ ] no production-critical untracked files.
- [ ] no unresolved merge conflict.
- [ ] no release-critical TODO/FIXME.
- [ ] no debug-only hack required for normal boot.
- [ ] `.gitignore` matches Section 191.
- [ ] `CHANGELOG.md` updated.
- [ ] `LICENSES.md` updated.
- [ ] `docs/implementation_decisions.md` current.
- [ ] `docs/known_issues.md` current.

## 195.2 SECRETS & SECURITY

- [ ] **[CRITICAL]** repository secret scan clean.
- [ ] **[CRITICAL]** no `.keystore`/`.jks` committed.
- [ ] **[CRITICAL]** no password/token/service-account key committed.
- [ ] production signing material exists only in owner-secure location.
- [ ] third-party dependency count is zero or every exception documented.

## 195.3 GENERATED ASSETS

- [ ] **[CRITICAL]** `generate_all` completes from clean project.
- [ ] **[CRITICAL]** generator manifest complete.
- [ ] no internet-downloaded production asset.
- [ ] all required characters generated.
- [ ] all six fish generated.
- [ ] motorcycle generated.
- [ ] Lake/Market/Home/duel set assets generated.
- [ ] UI icons/shapes generated.
- [ ] audio fully procedural.
- [ ] reference sheets regenerated from final assets.
- [ ] reference visual lock pass.
- [ ] no hero placeholder cube/debug material.

## 195.4 CONTENT COMPLETENESS

- [ ] **[CRITICAL]** 4 named human characters complete.
- [ ] **[CRITICAL]** 6 fish complete.
- [ ] **[CRITICAL]** 3 trash complete.
- [ ] **[CRITICAL]** 4 duel modes complete.
- [ ] **[CRITICAL]** 5×3 upgrade steps complete.
- [ ] all Section 183 narrative events complete.
- [ ] all fish dialogue complete.
- [ ] all Fish Book copy complete.
- [ ] all tutorials complete.
- [ ] all menus/settings/help copy English.
- [ ] ending complete.
- [ ] post-game complete.
- [ ] no player-visible Indonesian placeholder.

## 195.5 GAMEPLAY & ECONOMY

- [ ] **[CRITICAL]** fishing core loop smoke pass.
- [ ] **[CRITICAL]** Boxing pass.
- [ ] **[CRITICAL]** Arm Wrestling pass.
- [ ] **[CRITICAL]** Dance pass.
- [ ] **[CRITICAL]** Suwit pass.
- [ ] Wheel 25/25/25/25 configuration verified.
- [ ] sale values verified.
- [ ] Don Arowana effective sale Rp300,000 verified.
- [ ] upgrade prices/effects verified.
- [ ] debt starts Rp1,800,000.
- [ ] debt never negative.
- [ ] debt can finish without Arowana.
- [ ] no gambling-money gameplay.
- [ ] no IAP/ad code.

## 195.6 SAVE & STORY

- [ ] **[CRITICAL]** fresh save pass.
- [ ] **[CRITICAL]** autosave pass.
- [ ] **[CRITICAL]** close/reopen/Continue pass.
- [ ] **[CRITICAL]** corrupt-save recovery path pass.
- [ ] **[CRITICAL]** migration tests pass where applicable.
- [ ] background/suspend save behavior pass Android.
- [ ] Web storage warning present.
- [ ] story event arbitration one-per-Market-visit verified.
- [ ] story skip preserves state.
- [ ] full debt milestone chain pass.
- [ ] ending unlock pass.
- [ ] post-game transition pass.

## 195.7 ACCESSIBILITY

- [ ] text scale presets pass.
- [ ] UI scale pass.
- [ ] High Contrast HUD pass.
- [ ] Reduced Flash pass.
- [ ] Reduced Motion pass.
- [ ] HUD Shake ON/REDUCED/OFF pass.
- [ ] Panco Hold Assist pass.
- [ ] rhythm calibration pass.
- [ ] visual beat pulse pass.
- [ ] left-handed mobile layout pass.
- [ ] keyboard remapping pass.
- [ ] skip-hold duration setting pass.
- [ ] no critical info color-only.

## 195.8 PERFORMANCE

- [ ] **[CRITICAL]** Web minimum FPS target pass.
- [ ] **[CRITICAL]** Android minimum FPS target pass on required physical devices.
- [ ] no thermal collapse during required long session.
- [ ] RAM within Section 190 budget.
- [ ] draw call/triangle budget reviewed.
- [ ] procedural audio CPU/voice budget pass.
- [ ] boot/load/transition budget pass or approved documented exception.
- [ ] Web package budget pass.
- [ ] Android package budget pass.
- [ ] long-session memory leak check pass.

## 195.9 HUMAN PLAYTEST

- [ ] **[CRITICAL]** minimum 12 unique participants reached.
- [ ] **[CRITICAL]** >=90% core-loop comprehension after 12 min.
- [ ] **[CRITICAL]** >=80% first tutorial completion without intervention.
- [ ] **[CRITICAL]** >=80% first sale completion without intervention.
- [ ] repeated usability blockers fixed/retested.
- [ ] accessibility observations reviewed.
- [ ] `docs/playtest_report.md` finalized.

## 195.10 BUG TRIAGE

- [ ] **[CRITICAL]** zero BLOCKER.
- [ ] **[CRITICAL]** zero known P0.
- [ ] **[CRITICAL]** zero known P1 core/save/platform/accessibility.
- [ ] remaining P1 non-core explicitly waived if any.
- [ ] P2/P3 known issues documented.
- [ ] regression suite pass.

## 195.11 WEB / ITCH.IO

- [ ] **[CRITICAL]** Web export succeeds from clean checkout.
- [ ] `index.html` at ZIP root.
- [ ] Chromium smoke pass.
- [ ] Firefox smoke pass.
- [ ] WebKit/Safari result documented when available.
- [ ] keyboard actions do not trigger harmful browser behavior.
- [ ] focus loss/resume behavior pass.
- [ ] responsive portrait/compact layout pass.
- [ ] fullscreen button behavior verified.
- [ ] ZIP/extracted limits within Section 190 budget.
- [ ] itch title final.
- [ ] itch description final.
- [ ] itch cover/screenshots final generated from game.
- [ ] tags/category correct.

## 195.12 ANDROID / GOOGLE PLAY

- [ ] **[CRITICAL]** Android export succeeds.
- [ ] **[CRITICAL]** final release AAB signed with owner production key.
- [ ] **[CRITICAL]** versionCode incremented correctly.
- [ ] versionName correct.
- [ ] current required target API rechecked at release time.
- [ ] min SDK/device policy documented.
- [ ] arm64-v8a included as required architecture.
- [ ] portrait orientation correct.
- [ ] back gesture behavior pass.
- [ ] clean install physical Android pass.
- [ ] install/update over previous validation build tested where meaningful.
- [ ] adaptive icon verified.
- [ ] no unnecessary permission.
- [ ] no debug signing on production artifact.

## 195.13 STORE METADATA

- [ ] app title final.
- [ ] package/application ID final.
- [ ] short description final.
- [ ] full description final.
- [ ] Play Store icon final generated asset.
- [ ] feature graphic final generated asset.
- [ ] required phone screenshots final.
- [ ] all store images reflect real game visual.
- [ ] no misleading feature shown.
- [ ] support email real and monitored by owner.
- [ ] privacy policy link/page ready.

## 195.14 PRIVACY / DATA SAFETY

- [ ] **[CRITICAL]** runtime behavior matches no-collection contract.
- [ ] **[CRITICAL]** Data Safety answers match actual build.
- [ ] **[CRITICAL]** privacy policy contains no placeholder.
- [ ] in-game Privacy screen accessible.
- [ ] no analytics SDK.
- [ ] no advertising ID access.
- [ ] no ad SDK.
- [ ] no account/login.
- [ ] no hidden network request except platform-required hosting/store behavior.

## 195.15 CONTENT RATING

- [ ] content disclosure manifest reviewed.
- [ ] cartoon/fantasy fighting disclosed accurately.
- [ ] past gambling-addiction reference disclosed accurately where questionnaire asks.
- [ ] zero real-money gambling/simulated betting incorrectly implied.
- [ ] no user interaction/chat.
- [ ] questionnaire answers match actual content.
- [ ] final IARC/store rating recorded; do not self-invent rating.

## 195.16 DOCUMENTATION

- [ ] README current.
- [ ] build instructions current.
- [ ] test instructions current.
- [ ] signing prerequisite current.
- [ ] generator instructions current.
- [ ] balance report current.
- [ ] QA report current.
- [ ] playtest report current.
- [ ] privacy policy current.
- [ ] content rating disclosure current.
- [ ] known issues current.

## 195.17 RELEASE PROVENANCE

- [ ] **[CRITICAL]** build manifest generated.
- [ ] **[CRITICAL]** release manifest generated.
- [ ] **[CRITICAL]** SHA-256 checksums generated.
- [ ] Godot exact version recorded.
- [ ] source commit recorded.
- [ ] generator seed/version recorded.
- [ ] save schema recorded.
- [ ] export preset hash/config recorded.
- [ ] final artifact paths recorded.

## 195.18 GOLD MASTER & BACKUP

- [ ] **[CRITICAL]** Gold Master source commit chosen.
- [ ] **[CRITICAL]** `v1.0.0` tag points to exact Gold Master commit.
- [ ] **[CRITICAL]** Web final ZIP archived.
- [ ] **[CRITICAL]** Android final AAB archived securely.
- [ ] release docs archived.
- [ ] checksum file archived.
- [ ] previous RC artifacts kept until publication sanity checks complete.

## 195.19 POST-PUBLISH SANITY

Immediately after platform publication/visibility:

- [ ] itch.io page launches actual final Web build.
- [ ] New Game works from public itch page.
- [ ] save/reload works from public itch page.
- [ ] Google Play listing metadata correct when live.
- [ ] install from Play track/build tested by owner where available.
- [ ] support/privacy links work.
- [ ] version displayed matches published build.

If critical mismatch ditemukan, follow Section 197 maintenance/emergency procedure.

---

# 196. REPRODUCIBLE BUILD & PROVENANCE CONTRACT

Project harus dapat menjawab pertanyaan:

> “Build yang dipublish ini berasal dari source apa, generator apa, config apa, dan bagaimana kita membuktikannya?”

## 196.1 REPRODUCIBILITY LEVELS

Dibedakan dua level.

### LOGICAL REPRODUCIBILITY — REQUIRED

Dari source commit, Godot version, generator seed/config, dan build config yang sama:

- generated gameplay resources sama;
- generated meshes/material parameters sama secara authoritative;
- game constants sama;
- content sama;
- save schema sama;
- exported game behavior equivalent.

### BIT-FOR-BIT REPRODUCIBILITY — BEST EFFORT

Binary export/ZIP byte-identical tidak diwajibkan jika engine/exporter memasukkan timestamp/platform metadata yang tidak mudah dinormalisasi.

Namun payload/provenance harus dapat dibandingkan.

## 196.2 AUTHORITATIVE BUILD INPUTS

Build hanya boleh bergantung pada:

```text
repository source commit
project.godot
tracked .gd/.tscn/.tres/resources
tracked generator code/data
exact Godot engine version
exact export templates version
explicit build configuration
owner signing credential for production Android signing
```

Tidak boleh bergantung pada:

- random file di Desktop/Downloads;
- internet asset;
- hidden editor state yang tidak direkam;
- developer-specific absolute path;
- untracked texture/model/audio;
- global machine plugin yang project tidak deklarasikan.

## 196.3 TOOLCHAIN LOCK

Gold Master mencatat exact:

```text
godot_version
godot_commit/build identifier if available
export_templates_version
host_os
android_sdk_version
android_build_tools_version
java_runtime_version if relevant to export
```

Current supported engine policy tetap Godot 4.7+ stable, tetapi Gold Master menggunakan satu exact tested stable version.

## 196.4 GENERATOR DETERMINISM

Programmatic asset generator wajib:

- mempunyai explicit root seed;
- tidak memakai global nondeterministic RNG untuk authored shape;
- sort dictionary/list input sebelum serialization bila order berpengaruh;
- menghindari dependence pada current wall-clock time;
- tidak membaca network;
- menghasilkan manifest output.

Root release generator seed default:

`MGGE_V1_RELEASE_2026`

Boleh direpresentasikan sebagai hash/int internal tetapi string canonical disimpan di manifest.

Jika seed diganti, itu dianggap art/content change dan wajib reference-sheet regression.

## 196.5 GENERATED ASSET MANIFEST

`generated/generator_manifest.json` minimal:

```json
{
  "manifest_version": 1,
  "generator_version": "...",
  "root_seed": "MGGE_V1_RELEASE_2026",
  "source_commit": "...",
  "godot_version": "...",
  "outputs": [
    {
      "path": "res://generated/...",
      "generator": "...",
      "source_config": "...",
      "sha256": "..."
    }
  ]
}
```

## 196.6 BUILD MANIFEST

`build/release/build_manifest.json` minimal:

```text
product_name
version_name
version_code
source_commit
source_tag
godot_version
export_template_version
save_schema_version
generator_manifest_sha256
root_generator_seed
build_profile
build_timestamp_utc
host_platform
web_export_preset
android_export_preset
privacy_contract_version
content_manifest_version
```

`build_timestamp_utc` adalah provenance only dan tidak boleh memengaruhi gameplay/generated asset output.

## 196.7 RELEASE MANIFEST

`build/release/release_manifest.json` mencatat artifact final:

```text
artifact_path
artifact_type
sha256
file_size_bytes
source_commit
version
signed: true/false
signing_key_id/fingerprint reference if owner chooses to record non-secret fingerprint
smoke_test_status
```

Jangan menyimpan private key/password.

## 196.8 CHECKSUM STANDARD

Gunakan SHA-256.

Output:

`build/release/checksums.sha256`

Minimal mencakup:

- Web ZIP;
- Android AAB;
- build manifest;
- release manifest;
- generator manifest snapshot.

Godot implementation dapat menggunakan `HashingContext` atau trusted platform tooling pada release machine.

## 196.9 CLEAN REBUILD PROCEDURE

Verification rebuild:

1. clean checkout Gold Master commit;
2. install exact tested Godot stable + matching templates;
3. do not copy generated asset dari machine lama kecuali repository intentionally tracks them;
4. run generator validation/regeneration;
5. compare generated manifest;
6. run tests;
7. export Web;
8. export Android validation/release sesuai credential availability;
9. create manifests;
10. compare authoritative checksums/semantic outputs;
11. smoke test.

## 196.10 REBUILD ACCEPTANCE

Pass jika:

- no missing asset/dependency;
- generated asset manifest output set identical;
- authoritative config/resources equal;
- automated tests same pass state;
- save schema unchanged;
- Web/Android behavior smoke-equivalent;
- any binary byte difference explained by known packaging/signing/timestamp metadata.

## 196.11 BUILD SCRIPT CONTRACT

Repository menyediakan Godot-native/headless entry points semisal:

```text
res://tools/build/generate_all.gd
res://tools/build/validate_project.gd
res://tests/run_all.gd
res://tools/build/write_build_manifest.gd
res://tools/build/write_checksums.gd
```

Platform shell wrapper boleh ada untuk convenience tetapi business logic validation tetap dapat dijalankan tanpa proprietary CI service.

## 196.12 NO NETWORK BUILD RULE

Normal clean build v1.0 setelah Godot/export templates/Android SDK tersedia:

**tidak memerlukan download runtime asset dari internet.**

No package manager fetch untuk game dependency karena v1.0 tidak mempunyai third-party addon requirement.

## 196.13 EXPORT PRESET CHANGE CONTROL

Perubahan `export_presets.cfg` setelah RC1 dianggap release-sensitive.

Wajib:

- review diff;
- rerun platform smoke;
- regenerate build manifest;
- increment RC.

## 196.14 SOURCE / ARTIFACT TRACEABILITY

Setiap final artifact harus dapat ditelusuri:

`artifact -> release_manifest -> source commit/tag -> generator manifest -> generated assets/config`.

Jika traceability putus, artifact tidak dianggap Gold Master.

## 196.15 PROVENANCE RELEASE GATE

Gold Master blocked jika:

- source commit unknown;
- generator seed/version unknown;
- final artifact checksum unknown;
- build manifest missing;
- release manifest missing;
- build memakai untracked production asset;
- clean rebuild gagal karena hidden local dependency.

---

# 197. POST-LAUNCH PATCH & MAINTENANCE CONTRACT

Publication bukan akhir dari engineering responsibility.

Section ini mengatur semua release setelah `v1.0.0` tanpa mengubah scope asli secara diam-diam.

## 197.1 VERSION POLICY

Gunakan format:

`MAJOR.MINOR.PATCH`

### `1.0.x` — PATCH

Untuk:

- bug fix;
- crash fix;
- save fix/migration;
- performance fix;
- accessibility correction;
- compatibility/store-policy fix;
- typo/copy correction;
- low-risk balance correction dengan evidence.

### `1.x.0` — MINOR

Hanya jika owner sengaja menambahkan fitur/content setelah v1.0 dan GDD/post-v1 specification diperbarui.

### `2.0.0` — MAJOR

Untuk perubahan besar yang dapat mengubah product/scope secara material.

## 197.2 ANDROID VERSION CODE

Setiap AAB yang diupload ke Google Play menggunakan `versionCode` lebih tinggi dari semua build sebelumnya pada package yang sama.

Rollback source tidak boleh berarti menurunkan versionCode.

## 197.3 PATCH SCOPE DEFAULT

Patch v1.0.x tidak boleh diam-diam menambah:

- multiplayer;
- IAP;
- ads;
- new fish roster;
- new duel;
- account/login;
- telemetry;
- cloud save;
- internet dependency.

Fitur baru masuk minor/major planning.

## 197.4 SAVE COMPATIBILITY AFTER PUBLIC RELEASE

Semua v1.0.x patch wajib:

- load valid save v1.0.0;
- preserve cash/debt/bucket/upgrades/story completion;
- never silently reset player;
- migrate forward jika schema berubah;
- backup sebelum migration;
- include regression fixture save dari v1.0.0.

Jika schema tidak perlu berubah, jangan bump schema hanya karena patch version berubah.

## 197.5 PUBLIC SAVE FIXTURE SET

Saat v1.0.0 publish, archive synthetic test saves:

```text
fixtures/save_v1_fresh.json
fixtures/save_v1_early.json
fixtures/save_v1_mid.json
fixtures/save_v1_almost_paid.json
fixtures/save_v1_postgame.json
```

Tidak menggunakan save personal tester yang mengandung data tidak perlu.

Setiap patch load-test semua fixture.

## 197.6 ISSUE INTAKE WITHOUT TELEMETRY

Karena game tidak memiliki analytics/crash SDK, issue dapat masuk melalui:

- support email;
- itch.io comments/community jika enabled oleh owner;
- Play Store review/manual reports;
- direct tester report.

Jangan menambah telemetry hanya demi maintenance tanpa privacy/GDD revision.

## 197.7 USER BUG REPORT TEMPLATE

Support dapat meminta:

```text
Game version
Platform
Android device / browser
What happened
What you expected
Steps if known
Screenshot if comfortable
Does it happen every time?
```

Jangan meminta:

- password;
- financial account data;
- government ID;
- unrelated personal information.

## 197.8 PATCH TRIAGE

Bug setelah release tetap menggunakan Section 193 severity.

Emergency priority:

1. data loss/save corruption;
2. launch crash;
3. progression softlock;
4. widespread input/platform break;
5. privacy/security/store compliance;
6. other P1;
7. P2/P3.

## 197.9 HOTFIX BRANCH

Contoh:

`hotfix/v1.0.1-save-corruption`

Hotfix berasal dari release tag/branch relevan, bukan dari experimental future feature branch.

## 197.10 PATCH WORKFLOW

1. reproduce issue;
2. assign severity;
3. branch from maintained release line;
4. implement minimal fix;
5. add regression test;
6. run relevant + core regression;
7. test v1.0 save fixtures;
8. update changelog;
9. update version/versionCode;
10. recheck store requirement yang berubah;
11. export;
12. run release checklist subset/full according risk;
13. tag patch;
14. archive manifests/checksums;
15. publish.

## 197.11 FULL CHECKLIST REQUIRED FOR HIGH-RISK PATCH

Full Section 195 rerun jika patch menyentuh:

- save schema;
- GameState;
- transaction/economy;
- story progression;
- InputManager;
- rhythm/audio clock;
- generator core;
- export/platform configuration;
- privacy/network behavior;
- Android target/min SDK;
- package identity/signing.

Low-risk typo-only patch dapat menggunakan reduced checklist tetapi tetap harus build/smoke/provenance pass.

## 197.12 BALANCE PATCH RULE

Jangan nerf/buff berdasarkan satu review marah.

Balance patch membutuhkan:

- repeated player signal atau simulation evidence;
- target metric;
- old/new value;
- effect simulation;
- relevant manual retest;
- `docs/balance_changes.md` entry.

Tema honest progress dan debt completion target harus tetap utuh.

## 197.13 WEB ROLLBACK

Untuk itch.io/Web:

- archive previous known-good ZIP;
- jika new build catastrophic dan platform workflow memungkinkan, owner dapat restore/reupload known-good Web artifact;
- preserve support notice if saves may have been written by newer schema;
- jangan rollback ke build yang tidak dapat membaca save baru jika newer build sudah public menulis incompatible schema.

## 197.14 ANDROID ROLLBACK REALITY

Google Play release tidak boleh “rollback” dengan menurunkan versionCode.

Jika v1.0.1 buruk:

- buat v1.0.2 dengan higher versionCode;
- revert problematic source change;
- preserve any save migration compatibility;
- release corrected build.

## 197.15 FORWARD-COMPATIBLE SAVE CAUTION

Sebelum patch menulis schema baru ke public save:

- migration path harus stable;
- downgrade consequence dipahami;
- previous Web artifact tidak dianggap safe rollback jika tidak bisa membaca schema baru.

Karena itu hindari schema bump untuk fix yang tidak membutuhkannya.

## 197.16 STORE POLICY RECHECK EACH RELEASE

Setiap public update wajib recheck current:

- Google Play target API requirement;
- Data Safety requirements;
- privacy policy requirement;
- content rating requirement;
- Android signing/package rules;
- itch.io HTML5 hosting/package constraints relevan.

Nilai yang tercantum di GDD adalah baseline tanggal dokumen, bukan izin untuk mengabaikan policy terbaru.

## 197.17 PRIVACY REGRESSION RULE

Patch tidak boleh memperkenalkan:

- analytics;
- tracker;
- advertising ID;
- account system;
- network endpoint baru;

secara diam-diam.

Jika feature masa depan memerlukan data collection:

- revise privacy contract;
- revise Data Safety;
- revise GDD;
- obtain owner approval;
- release as deliberate product change.

## 197.18 DEPENDENCY MAINTENANCE

v1.0 baseline mempunyai zero third-party addon requirement.

Jika maintenance benar-benar membutuhkan dependency:

- license review;
- security review;
- Web/Android test;
- privacy review;
- package-size review;
- explicit repository documentation.

## 197.19 SUPPORT STATUS

Selama line v1.x dinyatakan maintained:

- P0 regressions diprioritaskan;
- supported platform tetap Web itch.io + Android Google Play;
- current maintained Godot patch/stable upgrade dapat dilakukan hanya setelah regression.

Jika owner suatu saat mengakhiri maintenance:

- archive final source tag/artifacts;
- keep privacy/support page accurate selama distribution tetap live;
- jangan menjanjikan support yang tidak ada.

## 197.20 MAINTENANCE ARCHIVE

Setiap public release archive:

```text
version
source tag
source commit
Web ZIP
Android AAB if applicable
build manifest
release manifest
checksums
changelog
known issues
QA summary
save schema version
```

## 197.21 POST-LAUNCH SUCCESS PRINCIPLE

Maintenance tidak boleh mengubah game menjadi live-service.

Tidak ada obligation untuk:

- daily content;
- seasonal battle pass;
- engagement streak;
- endless monetization;
- analytics optimization.

Game tetap merupakan finite cozy single-player title dengan optional endless Free Fishing post-game.

## 197.22 FINAL DOCUMENT FREEZE

Dokumen ini adalah **final v1.0 production specification**.

Setelah Version 6.0 disetujui:

- jangan menambahkan section baru hanya karena muncul ide kecil;
- ide non-bug masuk `docs/post_v1_backlog.md`;
- implementation clarification dicatat di `docs/implementation_decisions.md` selama tidak mengubah authoritative rule;
- perubahan desain v1.0 setelah freeze memerlukan explicit owner-approved GDD amendment;
- fitur post-v1 yang material memerlukan specification/version baru terpisah.

Tujuannya adalah menghentikan endless planning dan mulai shipping.

---

# V6 FINAL RELEASE & MAINTENANCE NORTH STAR

Dokumen final ini mempunyai satu urutan keputusan terakhir:

1. **Build only what v1.0 promises.**
2. **Make every required asset from the repository itself.**
3. **Keep the game warm, cozy, readable, and quietly funny.**
4. **Protect player progress above developer convenience.**
5. **Test with machines, then validate with humans.**
6. **Do not ship known critical defects.**
7. **Freeze content before release.**
8. **Know exactly which source produced every published artifact.**
9. **Publish only the Gold Master.**
10. **Patch carefully without turning the game into a live service.**

Jika sebuah ide tidak membantu v1.0 menjadi lebih playable, stable, accessible, reproducible, atau publishable, ide tersebut menunggu setelah release.

# `THIS DOCUMENT IS THE FINAL AUTHORITATIVE V1.0 SPECIFICATION.`

