# Laporan Balance — Simulasi GDD Section 179

Dibuat di Milestone 10. Alat: `tools/sim/balance_sim.gd` (runner) dan `tools/sim/balance_model.gd` (model).

```text
godot --headless --path . --script res://tools/sim/balance_sim.gd -- --out=<file.json> --runs=10000
godot --headless --path . --script res://tools/sim/balance_sim.gd -- --out=<file.json> --runs=2000 --value-scale=0.22
```

## Ringkasan

- **Distribusi encounter, sampah, dan Wheel lulus** semua toleransi Section 179.2. Angka ini memakai kode game sendiri (`EncounterRoller`, `WheelController`) pada rentang seed tetap, jadi pasti untuk build ini.
- **Ekonomi jauh lebih cepat dari target Section 179.4–179.5.** Dengan angka GDD apa adanya, pemain rata-rata melunasi hutang dalam ~1.8 jam (target 5–8 jam) dan mendapat ~Rp1192rb per jam (target Rp180–450rb). Penyebabnya bukan bug: dengan waktu tunggu gigitan 4,5–9,5 detik (Section 25) dan duel 18–42 detik, satu putaran tangkapan ~1–1,5 menit, sementara target pendapatan per jam mengandaikan hanya ~8–10 ikan terjual per jam. Dua bagian GDD ini tidak cocok satu sama lain.
- **Tidak ada angka yang diubah.** Section 179.9 dan 191.12 meminta perubahan angka authoritative dicatat di GDD; itu keputusan pemilik project. Usulan ada di bawah.
- Dua temuan lama tetap terbuka dan juga menunggu keputusan pemilik: D-058 (tinju bisa dimenangkan dengan JAB terus-menerus melawan empat ikan pertama) dan D-068 (istirahat di panco tidak pernah lebih menguntungkan).

## Bagian 1 — Distribusi (kode game, 100.000 lemparan)

### Encounter (Section 179.2)

| Hasil | Target | Simulasi | Toleransi | Status |
|---|---|---|---|---|
| Sampah | 16.00% | 15.988% | ±0.50 | lulus |
| Bruiser Catfish | 25.20% | 25.007% | ±0.50 | lulus |
| Gym-Rat Tilapia | 20.16% | 20.215% | ±0.50 | lulus |
| Shady Gourami | 16.80% | 16.885% | ±0.50 | lulus |
| Golden Carp | 11.76% | 11.864% | ±0.50 | lulus |
| Snakehead Sergeant | 7.56% | 7.497% | ±0.50 | lulus |
| Don Arowana | 2.52% | 2.544% | ±0.20 | lulus |

### Jenis sampah

| Item | Target | Simulasi | Status (±0,75) |
|---|---|---|---|
| trash_sandal | 45% | 44.825% | lulus |
| trash_can | 40% | 40.025% | lulus |
| trash_tyre | 15% | 15.150% | lulus |

### Wheel (setelah Wheel tutorial)

| Duel | Target | Simulasi | Status (±0,50) |
|---|---|---|---|
| arm_wrestle | 25% | 24.900% | lulus |
| boxing | 25% | 25.252% | lulus |
| dance | 25% | 24.822% | lulus |
| suwit | 25% | 25.026% | lulus |

## Bagian 2 — Model ekonomi

### Asumsi

Peluang menang per profil memakai titik tengah rentang Section 179.3 (pemula: awal 66%, tengah 55%, Snakehead 45%, Arowana 40%; rata-rata: 76/66/59/52%; terampil: 91,5/85/77/70%). Waktu per langkah adalah perkiraan dari timing game:

| Langkah | Detik |
|---|---|
| Lempar dan gigitan | 1,6 + waktu tunggu dari `EncounterRoller.wait_time` (Bait ikut dihitung) + 1,6 |
| Reel | pemula 11, rata-rata 9, terampil 7,5 |
| Dialog mendarat, Wheel, Result | 5 + 4,5 + 7 |
| Duel | tinju 24, panco 26, joget 42, Suwit 18 |
| Market | 50 detik setiap 6 lemparan |

Peluang strike berhasil 80/90/97%, reel berhasil 66/78/90% (+4% per level Rod, −3% per tier ikan). Setiap level upgrade yang relevan menambah 3% peluang menang duel itu. Harga jual dari data game. Angka-angka ini **perkiraan**; data waktu nyata dari playtest manusia (Section 192) harus menggantikannya.

### Lama melunasi hutang (jam, median; 10.000 run per baris untuk data asli, 2.000 untuk usulan)

| Profil | Strategi | Data asli | P10–P90 asli | Usulan ×0,22 | Usulan ×0,25 |
|---|---|---|---|---|---|
| novice | debt_first | 2.52 | 1.95–3.04 | 7.74 | 7.10 |
| novice | balanced | 2.31 | 1.82–2.80 | 6.94 | 6.48 |
| novice | completionist | 2.59 | 2.10–3.06 | 7.61 | 7.15 |
| average | debt_first | 1.76 | 1.38–2.14 | 5.01 | 4.79 |
| average | balanced | 1.67 | 1.31–2.02 | 4.70 | 4.39 |
| average | completionist | 1.92 | 1.57–2.25 | 5.36 | 5.13 |
| skilled | debt_first | 1.26 | 0.99–1.51 | 3.40 | 3.23 |
| skilled | balanced | 1.22 | 0.97–1.46 | 3.36 | 3.10 |
| skilled | completionist | 1.44 | 1.18–1.69 | 3.90 | 3.62 |

Target Section 179.4: rata-rata 5–8 jam, completionist 7–11 jam, terampil tidak konsisten di bawah 3,5 jam, pemula median tidak lebih dari 12 jam. Strategi: `debt_first` membayar semua uang ke hutang, `balanced` membeli Bait/Rod/Tonic dulu, `completionist` membeli kelima upgrade sampai level 3 dulu.

### Pacing milestone, pemain rata-rata, bayar hutang dulu (jam)

| Hutang terbayar | Target | Data asli | Usulan ×0,22 |
|---|---|---|---|
| 100k | 0,25–0,58 | 0.16 | 0.50 |
| 300k | 0,75–1,5 | 0.36 | 1.24 |
| 600k | 1,5–2,7 | 0.64 | 1.66 |
| 1000k | 2,7–4,3 | 1.01 | 3.00 |
| 1400k | 3,7–5,8 | 1.39 | 3.98 |
| 1650k | 4,5–7,0 | 1.62 | 4.74 |
| 1800k | 5,0–8,0 | 1.76 | 5.01 |

### Tanpa Don Arowana (Section 179.6)

Pemain rata-rata yang tidak pernah memenangkan Arowana: data asli 2.04 jam; usulan ×0,22: 8.92 jam (syarat ≤ 9,5 jam). Hutang selalu bisa lunas tanpa Arowana.

### Sesi 20 menit (25.000 sesi per profil)

| Profil | Encounter (median) | Pendapatan per jam asli | Usulan ×0,22 |
|---|---|---|---|
| novice | 33 | Rp842rb | Rp190rb |
| average | 28 | Rp1192rb | Rp267rb |
| skilled | 25 | Rp1678rb | Rp374rb |

Section 179.8 mengharapkan 4–10 encounter per sesi 10–25 menit; model menghasilkan ~25–33 encounter per 20 menit. Ini sejalan dengan temuan utama: satu putaran tangkapan jauh lebih singkat daripada yang diandaikan target ekonomi.

## Usulan untuk pemilik project (belum diterapkan)

Section 179.9: satu keluarga parameter per putaran tuning. Keluarga yang paling sedikit menyentuh hal lain adalah **harga jual ikan biasa** (`sale_base` lima ikan non-boss):

- Kalikan `sale_base` Catfish, Tilapia, Gourami, Golden Carp, dan Snakehead dengan sekitar **0,22** (dibulatkan ke Rp500): 18.000 → 4.000, 26.000 → 5.500, 34.000 → 7.500, 52.000 → 11.500, 78.000 → 17.000.
- **Don Arowana tetap Rp300.000.** Dialog dan Section 179.6 menyebut angka itu.
- Hasil model: pemain rata-rata 4.7–5.4 jam, pemula 7.6–7.7 jam, tanpa Arowana 8.9 jam, pacing milestone masuk rentang. Completionist rata-rata (~5.4 jam) dan pemain terampil (~3.4 jam) masih sedikit di bawah target; keduanya bisa disetel di putaran kedua (misalnya harga upgrade), setelah data playtest ada.
- Yang ikut berubah: tutorial Market pertama tetap bisa membayar Rp10.000 (8.430 + 4.000 dari lele = 12.430); harga upgrade tetap; naskah tidak menyebut harga ikan biasa. Test `data` yang mengunci harga GDD harus diperbarui bersama GDD.
- Alternatif yang tidak disarankan: menaikkan hutang (angka Rp1.800.000 dipakai di naskah), atau memperpanjang waktu tunggu gigitan (bertentangan dengan Section 25).

## D-058 — Tinju: JAB terus-menerus

Masih berlaku (lihat `docs/implementation_decisions.md`): empat ikan pertama kalah dari pemain yang hanya menekan JAB tanpa menghindar. Section 41 menyebut "player tidak diminta spam attack", tetapi angkanya (block 40%, tanpa hukuman lain) mengizinkannya. Pilihan untuk pemilik: (a) pukulan terblokir beruntun memberi stagger singkat pada Darto, (b) ikan langsung menyerang balik setelah beberapa pukulan terblokir, (c) block untuk pukulan beruntun naik dari 40% ke ~70%. Semuanya revisi GDD.

## D-068 — Panco: istirahat

Dengan angka GDD, terus menekan selalu memberi dorongan lebih besar daripada berhenti untuk memulihkan stamina, sehingga petunjuk "stop briefly to recover" tidak pernah menguntungkan. Hold Assist tetap bisa mengalahkan setiap ikan (`a11y.test_hold_assist_beats_every_fish_with_the_same_costs`). Pilihan untuk pemilik: naikkan pemulihan stamina saat istirahat, atau turunkan batas tenaga minimum 42%. Revisi GDD.

## Revisi 6.12 — Utang Rp 2.000.000

Utang awal naik dari Rp 1.800.000 ke Rp 2.000.000 (+11%). Milestone digeser sebanding: 100k, 350k, 700k, 1.100k, 1.500k, 1.850k, lunas. Harga ikan, upgrade, dan perlengkapan tidak berubah. Model yang sama (hanya Danau Cempaka, tanpa batas ember), 2.000 run per baris:

| Profil | Strategi | Utang Rp 1,8 jt (jam) | Utang Rp 2 jt (jam) | Selisih |
|---|---|---|---|---|
| novice | debt_first | 2.53 | 2.80 | +11% |
| novice | completionist | 2.58 | 2.78 | +8% |
| average | debt_first | 1.75 | 1.94 | +11% |
| average | balanced | 1.67 | 1.84 | +10% |
| average | completionist | 1.92 | 2.06 | +8% |
| average | tanpa Arowana | 2.04 | 2.26 | +11% |
| skilled | debt_first | 1.26 | 1.39 | +11% |

Bagian permainan saat setiap milestone tercapai (pemain rata-rata, bayar utang dulu), dari lama melunasi:

| Milestone | Utang Rp 1,8 jt | Utang Rp 2 jt |
|---|---|---|
| 1 (100k) | 9% | 8% |
| 2 (300k → 350k) | 21% | 21% |
| 3 (600k → 700k) | 37% | 38% |
| 4 (1.000k → 1.100k) | 58% | 57% |
| 5 (1.400k → 1.500k) | 78% | 76% |
| 6 (1.650k → 1.850k) | 92% | 93% |

Adegan cerita tetap muncul di titik permainan yang sama. Lama melunasi naik 8–11%, masih jauh di bawah target Section 179.4 (temuan utama di atas tetap berlaku), jadi harga tidak perlu dinaikkan.
