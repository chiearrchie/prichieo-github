# Tema PRICHIEO

Pilihan tema ada di tab **About**. Dua tema yang tersedia: **Default** dan **GTA6**. Preferensi tersimpan di perangkat lewat `shared_preferences` dengan kunci `prichieo.theme.v1`, jadi tetap aktif setelah aplikasi dibuka ulang. `ThemeMode.system` tetap dipakai, sehingga tiap tema punya versi terang dan gelap.

## Default

Merah dan putih seperti rilis sebelumnya. Tidak ada perubahan warna pada tema ini. App bar memakai `Colors.redAccent`, tombol HPP merah, tombol Pemisah Kas hitam, dan tombol Target biru.

## GTA6

Tema ini berasal dari salinan percobaan `prichieo-gradient` yang sudah digabung ke aplikasi utama. Nama GTA6 adalah nama tema, bukan nama aplikasi.

Gradien yang dipakai:

| Stop | Warna | Peran |
| --- | --- | --- |
| 0 persen | `#1e0338` | ungu tua, awal gradien |
| 25 persen | `#6a0572` | ungu, juga aksen teks |
| 45 persen | `#e1007a` | magenta |
| 68 persen | `#f74c52` | merah muda |
| 85 persen | `#ff8c1a` | oranye |
| 100 persen | `#ffb800` | kuning, akhir gradien |

Arah gradien kira-kira 120 derajat. Di Flutter, `begin: Alignment(-0.866, -0.5)` dan `end: Alignment(0.866, 0.5)`.

### Kontras

Teks putih tidak diletakkan langsung di atas stop kuning karena kontrasnya hanya `1,73:1`. Lapisan hitamnya bertahap, bukan seragam: `alpha 0` pada ungu tua dan ungu, lalu naik sampai `alpha 0,40` pada kuning. Kontras teks putih minimum menjadi `4,58:1`, lolos WCAG AA untuk teks biasa.

Aksen teks di atas permukaan terang memakai `#6a0572`, kontras `10,26:1` terhadap `#f5f5f5`.

Oranye pada kartu modal dan hijau pada kartu laba tetap dipakai sebagai penanda fungsional. Teks angkanya memakai aksen ungu supaya terbaca di kedua mode.

### Letak kode

Definisi warna, gradien, lapisan kontras, dan helper tombol ada di bagian atas `usr/lib/main.dart`:

- `_warnaGradasi`, `_posisiGradasi`, `_gradasiPrichieo`
- `_lapisanKontras`, `_lapisanGelap`
- `_tombolUtama`
- `_GayaTema` dan `_gayaGta6`

`_GayaTema` adalah `ThemeExtension`, jadi semua widget yang memakai `Theme.of(context)` otomatis mengikuti tema aktif. Saat menambah tema baru, cukup tambahkan `ThemeData` dan nilai `_GayaTema`-nya, lalu daftarkan di `PrichieoApp.build` dan di tab About.
