# Licenses

Catch and Brawl tidak memakai aset, musik, atau kode pihak ketiga selain Godot Engine dan dua font berlisensi terbuka di bawah (GDD Section 184.12, 187.8). Semua model, tekstur, UI, ikon, dan suara dibuat oleh generator di `tools/generators/` dan kode di repository ini.

Di dalam game, teks lisensi engine, daftar komponennya, dan lisensi lengkap kedua font bisa dibuka lewat **Settings → PRIVACY AND LICENSES → LICENSES**.

## Font

Revisi Font 6.3 (2026-11-15). Kedua font gratis, boleh dipakai di game komersial, boleh di-embed di build, dan tidak meminta royalti. Syaratnya hanya membawa teks lisensinya bersama font. File lisensi ada di sebelah font (`assets/fonts/`), ikut dipaketkan di setiap preset export (`include_filter` `assets/fonts/*.txt`), dan ditampilkan lengkap di layar LICENSES.

| Font | Dipakai untuk | Pembuat | Lisensi | File di repo | SHA-256 |
|---|---|---|---|---|---|
| Fredoka (variable, sumbu `wdth` + `wght`) | semua teks berjalan: badan, tombol, header, HUD (bobot 500 dan 600) | Milena Brandão, Hafontia. Copyright 2016 The Fredoka Project Authors | SIL Open Font License 1.1, tanpa Reserved Font Name | `assets/fonts/Fredoka-Variable.ttf` + `Fredoka-OFL.txt` | `2ba02e68b152868aef9ba28e24b3648c7d457fe6f25c761f2c2c53fb61a73fc8` |
| Chewy | judul besar dan teks "cat papan": logo, banner duel, PERFECT/MISS, Result, Wheel, credits, tanda gigitan "!" | Font Diner (Sideshow). Copyright (c) 2010 by Font Diner, Inc DBA Sideshow | Apache License 2.0 | `assets/fonts/Chewy-Regular.ttf` + `Chewy-LICENSE.txt` | `7cf75ea288f82fd20badea8ab4da7a656a96a7277c170811e813b3d3d6294147` |

Sumber: repository resmi Google Fonts (`github.com/google/fonts`, `ofl/fredoka/` dan `apache/chewy/`), tanpa modifikasi. File `Fredoka[wdth,wght].ttf` hanya diganti namanya menjadi `Fredoka-Variable.ttf`. Mengganti nama file tidak termasuk modifikasi font menurut OFL.

Catatan lisensi:

- **OFL 1.1**: font boleh dipakai, di-embed, dan didistribusikan bersama software komersial. Yang dilarang hanya menjual file font itu sendiri secara terpisah. Salinan copyright dan lisensi wajib ikut.
- **Apache 2.0**: boleh dipakai komersial. Salinan lisensi wajib ikut. Chewy tidak punya file NOTICE.
- `tools/validation/asset_policy_scan.gd` hanya mengizinkan dua file font ini, dan hanya jika file lisensinya ada. Font lain tetap ditolak. Menambah font berarti revisi GDD, review lisensi, dan entri baru di tabel ini serta di `AssetPolicyScan.LICENSED_FONTS`.

## Godot Engine

Game dibuat dan diekspor dengan Godot Engine 4.7.2 (template export resmi).

```text
Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Komponen pihak ketiga di dalam Godot Engine

Template export Godot membawa komponen berikut dengan lisensinya sendiri. Teks lengkapnya ada di file `COPYRIGHT.txt` rilis Godot 4.7.2 dan di layar LICENSES di dalam game. Font bawaan engine di daftar ini tetap ikut di template export, tetapi teks game tidak lagi memakainya.

| Komponen | Lisensi |
|---|---|
| Godot Engine | Expat |
| Bullet Continuous Collision Detection and Physics Library | Expat and Zlib, Expat and Zlib, Expat and Zlib |
| Linux AppStream Metadata File | CC0-1.0 |
| Godot Engine logo | CC-BY-4.0 |
| Betsy | Expat |
| Chipmunk2D Joint Constraints | Expat |
| Open Dynamics Engine | BSD-3-clause |
| Jolt Physics | Expat, Expat |
| Joint Non-Local Means (JNLM) denoiser | Expat |
| The Android Open Source Project | Apache-2.0 |
| ProcessPhoenix | Apache-2.0 |
| Robert Penner's Easing Functions | Expat |
| NVidia's FXAA 3.11, simplified by Simon Rodriguez | BSD-3-clause and Expat |
| Intel ASSAO and related files | Expat |
| Temporal Anti-Aliasing resolve implementation | Expat |
| Subpixel Morphological Antialiasing | Expat |
| AccessKit | Expat |
| AMD FidelityFX Super Resolution | Expat |
| AMD FidelityFX Super Resolution 2 | Expat |
| ANGLE | BSD-3-clause |
| Arm ASTC Encoder | Apache-2.0 |
| Basis Universal | Apache-2.0 |
| Brotli | Expat |
| CA certificates | MPL-2.0 |
| Clipper2 | BSL-1.0 |
| Convection Texture Tools Stand-Alone Kernels | Expat |
| D3D12 Memory Allocator | Expat |
| DirectX Headers | Expat |
| doctest | Expat |
| dr_libs | Unlicense or MIT-0 |
| Embree | Apache-2.0 |
| ENet | Expat |
| etcpak | BSD-3-clause |
| DroidSans font | Apache-2.0 |
| Inter font | OFL-1.1 |
| JetBrains Mono font | OFL-1.1 |
| Noto Sans font | OFL-1.1 |
| Open Sans font | OFL-1.1 |
| Vazirmatn font | OFL-1.1 |
| The FreeType Project | FTL |
| GamepadMotionHelpers | Expat |
| glad | CC0-1.0 and Apache-2.0 |
| glslang | glslang |
| Graphite engine | Expat |
| Grisu2 float serialization algorithm | Expat and Apache-2.0 |
| HarfBuzz text shaping library | HarfBuzz |
| International Components for Unicode | Unicode |
| libbacktrace | BSD-3-clause |
| libjpeg-turbo | BSD-3-clause and IJG |
| KTX | Apache-2.0 |
| OggVorbis | BSD-3-clause, BSD-3-clause |
| libpng | Zlib |
| OggTheora | BSD-3-clause |
| WebP codec | BSD-3-clause |
| Manifold | Apache-2.0 |
| Mbed TLS | Apache-2.0 |
| meshoptimizer | Expat |
| metal-cpp | Apache-2.0 |
| mingw-std-threads | BSD-2-clause |
| MiniUPnP Project | BSD-3-clause |
| MiniZip | Zlib |
| bcdec | Expat |
| Fast Filtering of Reflection Probes | Expat |
| FastLZ | Expat |
| FastNoise Lite | Expat |
| libjingle | BSD-3-clause |
| Tangent Space Normal Maps implementation | Zlib |
| NVIDIA NVAPI (minimal excerpt) | Expat |
| OK Lab color space | Expat |
| Minimal PCG32 implementation | Apache-2.0 |
| PolyPartition / Triangulator | Expat |
| Quite OK Audio Format | Expat |
| r128 library | Unlicense |
| SMAZ | BSD-3-clause |
| SMOL-V | Unlicense or Expat |
| stb libraries | Unlicense or Expat |
| YUV2RGB | BSD-2-clause |
| Multi-channel signed distance field generator | Expat |
| OpenXR Loader | Apache-2.0 |
| PCRE2 | BSD-3-clause |
| Recast | Zlib |
| RVO2 | Apache-2.0 |
| SDL | Zlib |
| hidapi | BSD-3-clause |
| SPIRV-Cross | Apache-2.0 or Expat |
| SPIRV-Headers | Expat |
| SPIRV-Reflect | Apache-2.0 |
| Swappy | Apache-2.0 |
| ThorVG | Expat |
| TinyEXR | BSD-3-clause |
| ufbx | Expat |
| V-HACD | BSD-3-clause |
| volk | Expat |
| Vulkan Headers | Apache-2.0 |
| Vulkan Memory Allocator | Expat |
| Wayland core protocol | Expat |
| Wayland protocols | Expat |
| Mesa Wayland protocols | X11 |
| Wslay | Expat |
| xatlas | Expat |
| zlib | Zlib |
| Zstandard | BSD-3-clause |

## Dependency tambahan

Selain dua font di atas, tidak ada. Setiap dependency baru memerlukan review lisensi dan entri di file ini (Section 187.8, 191.8).
