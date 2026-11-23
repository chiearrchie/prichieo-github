# PRICHIEO - Play Store Listing

## Identitas

- Nama aplikasi: PRICHIEO
- Kategori: Business / Productivity
- Short description: Smart Tools for Small Business
- Tagline: Manage Better, Grow Smarter.
- Developer: Created by Chiearrchie
- Package: `com.chiearrchie.prichieo`
- Versi: 1.0.0 (kode 1)

## Deskripsi lengkap

PRICHIEO adalah kalkulator bisnis untuk usaha kecil. Hitung Harga Pokok Penjualan, pisahkan uang modal dan laba, lalu tentukan target penjualan harian.

Kalkulator HPP menghitung biaya bahan, tenaga kerja, overhead, kemasan, potongan platform, harga jual per unit, dan jumlah produk yang dihasilkan. Nama produk dan satuan bisa diatur sendiri, misalnya porsi, biji, box, atau unit. Persentase modal terisi otomatis dari hasil HPP dan harga jual.

Pemisah Kas membagi omset menjadi uang modal dan laba kotor. Target Penjualan menghitung jumlah unit yang harus terjual dari target omset harian.

Semua hitungan tersimpan di perangkat sebagai riwayat, maksimal 50 entri. Riwayat bisa dihapus kapan saja. Aplikasi ini tidak memerlukan akun dan tidak mengirim data hitungan ke server.

## Yang perlu disiapkan di Play Console

- Ikon 512x512: `prichieo-512.png`
- Feature graphic 1024x500: `feature-graphic-1024x500.png`
- Screenshot dari build Flutter asli, minimal 2 dan maksimal 8. Panduan lengkap ada di `SCREENSHOT_CHECKLIST.md`.
- Kebijakan privasi: siap unggah di `privacy-policy.html` atau `PRIVACY_POLICY.md`. File HTML perlu di-hosting dulu, lalu URL-nya ditempel di Play Console.
- Data safety: nyatakan data aplikasi tidak dikumpulkan atau dibagikan. Tautan Instagram di tab About membuka browser atau aplikasi Instagram di luar aplikasi.
- Release: unggah AAB dari `build/app/outputs/bundle/release/app-release.aab`.
- Uji internal terlebih dahulu dengan APK dari `build/app/outputs/flutter-apk/app-release.apk`.

## Catatan rilis

Build release ditandatangani dengan upload key yang dibuat lokal. Simpan file `prichieo-keystore/prichieo-release.jks` dan isi `android/key.properties` di tempat aman. Jika keduanya hilang, aplikasi tidak bisa diperbarui dengan kunci yang sama.
