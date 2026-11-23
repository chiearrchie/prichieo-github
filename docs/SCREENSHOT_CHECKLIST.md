# Checklist screenshot PRICHIEO

Ambil screenshot dari aplikasi Flutter yang berjalan di BlueStacks, bukan dari preview HTML.

## Aturan umum

- Format PNG.
- Minimal 2 screenshot, maksimal 8.
- Sisi terpendek minimal 320 px, sisi terpanjang maksimal 3840 px.
- Pakai tampilan ponsel portrait di BlueStacks, misalnya 720x1280 atau 1080x1920.
- Potong sampai hanya konten aplikasi yang terlihat. Jangan sertakan toolbar BlueStacks, bezel, atau jendela emulator.
- Jangan menambahkan teks, panah, atau bingkai di luar aplikasi.
- Simpan di folder `playstore/screenshots` dengan nama sesuai daftar di bawah.

## Isi yang disarankan

### 01-hpp.png

Buka tab **HPP**, isi:

- Nama Produk: `Kopi Susu`
- Satuan Produk: `gelas`
- Total Biaya Bahan Baku: `100000`
- Biaya Tenaga Kerja: `20000`
- Biaya Overhead: `10000`
- Total Biaya Kemasan: `5000`
- Harga Jual per Unit: `20000`
- Potongan Platform: `10`
- Jumlah Produk Dihasilkan: `10`

Yang terlihat di layar: **HPP per gelas: Rp 15.500** dan keterangan persentase modal **77,5%**. Tekan **HITUNG HPP** sebelum screenshot supaya entri masuk riwayat.

### 02-pemisah-kas.png

Buka tab **Pemisah Kas**, isi omset `500000` dan persentase `77,5`. Tekan **PISAHKAN UANG**.

Yang terlihat: **Uang Modal Rp 387.500** dan **Laba Kotor Rp 112.500**.

### 03-target.png

Buka tab **Target**, isi target omset `500000` dan harga jual `3500`. Tekan **HITUNG TARGET**.

Yang terlihat: **Anda HARUS menjual minimal: 143 gelas**.

### 04-riwayat.png

Buka tab **Riwayat** setelah tiga hitungan di atas disimpan.

Yang terlihat: tiga kartu entri dengan timestamp, tombol **HAPUS RIWAYAT**, dan tidak ada pesan empty state.

### 05-about.png

Buka tab **About**.

Yang terlihat: logo, **PRICHIEO**, tagline **Manage Better, Grow Smarter.**, identitas aplikasi, dan tombol **Buka Instagram @chiearrchie**.

## Urutan upload di Play Console

1. `01-hpp.png`
2. `02-pemisah-kas.png`
3. `03-target.png`
4. `04-riwayat.png`
5. `05-about.png`
