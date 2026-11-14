# Laporan Playtest — 1.0.0-rc.1

Status: **V1.0 RELEASE CANDIDATE — HUMAN PLAYTEST PENDING** (GDD Section 192.1).

Belum ada manusia yang memainkan build ini selain pengembang. Bot, test otomatis, dan screenshot tidak menggantikan playtest (Section 192.1), jadi tidak ada hasil usability di file ini. Bagian di bawah adalah protokol dan formulir yang siap dipakai.

## Build untuk playtest

- Web: `build/itch/mancing-mania-gelut-edition-web-1.0.0-rc.1.zip`, atau upload ke halaman itch.io draft/restricted. Jalankan lokal dengan `python -m http.server` di `build/web`.
- Android: belum tersedia (lihat `README_BUILD.md`).
- Gunakan release build: tool debug (F10, argumen `--mm-*`) mati di release.

## Target peserta (Section 192.3)

12 peserta unik, minimal 6 Web dan 6 Android, minimal 8 pemain baru, minimal 3 perangkat Android berbeda, minimal 2 yang mencoba setting aksesibilitas. Pakai ID anonim T01, T02, … Jangan simpan nama lengkap, kontak, atau rekaman tanpa izin (Section 192.5).

## Aturan pengamat (Section 192.6)

Beri build dan cara membukanya saja. Jangan menjelaskan mekanik. Bila peserta minta bantuan, catat dulu `HELP_REQUESTED`, konteks, dan menit ke berapa, baru bantu seperlunya.

## Formulir per peserta

```text
Peserta: T__        Platform: Web / Android (perangkat: ______)   Tanggal: ____
Stage: B (pemain baru) / C (duel) / D (kenyamanan platform) / E (alur penuh RC)

12 menit pertama (menit:detik sejak mulai)
  T_cast_understood        ____
  T_first_successful_strike ____
  T_first_fish_landed      ____
  T_first_duel_understood  ____
  T_market_found           ____
  T_first_sale             ____
  T_first_debt_payment     ____
  Premature strike: __   Retry tutorial: __   Tombol salah berulang: ya/tidak
  Paham ikan harus dilawan: ya/tidak     Paham ikan masuk Bucket hanya jika menang: ya/tidak
  Paham uang dari menjual tangkapan: ya/tidak    Paham hutang adalah progres utama: ya/tidak
  HELP_REQUESTED: ya/tidak   konteks: ________   menit: ____

Skala 1–5
  Fishing felt relaxing ___                 Fishing controls felt understandable ___
  Duels felt readable ___                   Duels felt fair ___
  Market/economy felt understandable ___    Upgrades felt meaningful ___
  Game felt warm/cozy ___                   Humor felt natural ___
  Story felt sincere rather than preachy ___
  I understood what Darto was trying to accomplish ___
  I would willingly play another session ___

Pertanyaan terbuka
  What confused you most?
  What felt best?
  What felt slow or annoying?
  Was any joke repeated too much?
  Did any duel feel unfair?
  What did you think the goal of the game was?
  Was there any moment you wanted to stop playing?

Waktu sesi total: ____   Market dikunjungi: __   Upgrade dibeli: __   Hutang terbayar: Rp ______
```

## Ambang lulus (Section 192.8)

- ≥90% pemain baru bisa menjelaskan loop inti setelah 12 menit.
- ≥80% menyelesaikan tutorial memancing pertama tanpa bantuan.
- ≥80% menemukan dan menyelesaikan penjualan pertama tanpa bantuan.
- ≥80% paham fungsi pembayaran hutang setelah tutorial Market.
- Tidak ada kontrol penting yang membingungkan >20% peserta.
- Median skala "controls understandable", "duels readable", "Market/economy understandable", dan "warm/cozy" minimal 4.

## Yang perlu diukur khusus untuk build ini

- **Lama sesi dan jumlah tangkapan per jam**: data ini menggantikan perkiraan waktu di `docs/balance_report.md` dan menentukan apakah usulan harga jual (KI-001) perlu diterapkan.
- **Tinju**: apakah peserta menemukan sendiri bahwa menekan JAB terus menang (KI-002).
- **Panco dengan dan tanpa Hold Assist**: kelelahan tangan dan apakah istirahat pernah dipakai (KI-003).
- **Joget di Web**: apakah input terasa tepat waktu tanpa kalibrasi.

## Hasil

Belum ada.
