# BlueMart Retail

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.22+-0EA5E9?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.4+-3B82F6?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Provider-6.1+-3B82F6?style=for-the-badge" alt="Provider" />
  <img src="https://img.shields.io/badge/SQLite-1E3A8A?style=for-the-badge" alt="SQLite" />
  <img src="https://img.shields.io/badge/Firebase-Firestore-F97316?style=for-the-badge" alt="Firebase" />
</p>

**Aplikasi E-Commerce Gadget & Elektronik Modern**  
🏆 Project Akhir Pemrograman Piranti Bergerak — Kelompok 04  
Teknologi Informasi — Semester IV | TI253311

---

## 📋 Identitas Project

| **Nama Aplikasi** | BlueMart Retail |
|:---|:---|
| **Kelompok** | Kelompok 04 |
| **Mata Kuliah** | Pemrograman Piranti Bergerak (TI253311) |

### Anggota Kelompok

| Nama | NIM |
|:---|:---|
| Fiji Firmanda | 240040099 |
| Kadek Novan Suhaliem Chandra | 240040107 |
| I Gede Sandi Pujanta | 240040129 |

---

## 📝 Deskripsi

BlueMart Retail merupakan aplikasi mobile e-commerce yang dikembangkan untuk memfasilitasi belanja gadget dan elektronik secara digital. Aplikasi ini menerapkan arsitektur multi-role dengan dua tipe pengguna, yaitu User untuk konsumen dan Admin untuk manajemen toko.

---

## 🎯 Permasalahan

Belanja gadget dan elektronik online masih menghadapi masalah dalam hal:
- Ketersediaan informasi produk yang terpercaya dan harga kompetitif
- Kemudahan proses transaksi dari browsing hingga checkout
- Manajemen inventori dan pesanan yang efisien bagi penjual
- Kurangnya integrasi teknologi mobile yang memudahkan pengguna

---

## 💡 Solusi

Pengembangan aplikasi mobile e-commerce dengan:

1. **Antarmuka Intuitif** — Desain UI/UX modern dengan navigasi yang mudah dipahami
2. **Sistem Role-Based** — Pemisahan hak akses antara User dan Admin
3. **Fitur Terintegrasi** — browsing, keranjang, checkout, tracking pesanan dalam satu aplikasi
4. **Teknologi Mobile** — Implementasi kamera, sensor, dan layanan lokasi
5. **Offline-First Architecture** — Kombinasi SQLite lokal dan cloud sync untuk ketersediaan data

---

## ⚡ Fitur Utama

### Fitur Wajib Mata Kuliah

| Fitur | Deskripsi |
|:---|:---|
| **Login & Session** | Autentikasi username/password dengan SharedPreferences untuk persistensi session |
| **CRUD Data** | Operasi Create, Read, Update, Delete pada data produk, kategori, dan transaksi |
| **Multi Halaman** | Navigasi antar 10+ halaman (login, home, detail, cart, checkout, orders, profile, admin panel) |
| **Kamera** | Barcode/QR scanner dan image picker untuk foto produk |
| **Peta & Lokasi** | OpenStreetMap untuk menampilkan lokasi supplier dengan marker |
| **Sensor** | Magnetometer (compass) untuk navigasi dan accelerometer (shake gesture) |
| **API/Web Service** | Integrasi dengan REST API untuk data kurs mata uang |
| **Cloud Database** | Firebase Firestore untuk sinkronisasi data antar device |

### Modul Aplikasi

**Authentication Module**
- Login/logout dengan validasi form
- Role-based access control (User/Admin)
- Session management dengan SharedPreferences

**Product & Shopping Module**
- Home screen dengan auto-scrolling banner dan search bar
- Kategori produk dalam horizontal scroll
- Grid produk dengan filter dan sort
- Product detail dengan image gallery
- Sistem favorit/wishlist

**Shopping Cart**
- Manajemen item dengan quantity controls
- Order summary (subtotal, shipping, tax, grand total)
- Swipe to delete dengan konfirmasi
- Empty state handling

**Checkout & Payment**
- Alamat pengiriman dengan multiple address support
- Pilihan shipping method (JNE, J&T, GoSend)
- Payment methods: QRIS, Transfer Bank, E-Wallet, COD
- Promo/voucher system
- Order processing dengan timeline tracking

**Order History**
- Filter berdasarkan status (Pending, Processing, Shipped, Completed, Cancelled)
- Pull-to-refresh
- Order detail dengan payment information
- Re-order functionality

**Notification System**
- Real-time notifications untuk User dan Admin
- Tab filter (Semua, Pesanan, Promo)
- Unread count badge
- Mark as read / broadcast (Admin)

**Admin Panel**
- Dashboard statistik (produk, pesanan, revenue, pelanggan)
- Manajemen Produk & Kategori (CRUD + image upload)
- Kelola Pesanan (update status, cancel)
- Statistik Penjualan dengan chart
- Manajemen Promo & Voucher
- Sales Report dengan filter tanggal

**Advanced Features**
- **Barcode Scanner**: Real-time scanning dengan mobile_scanner
- **Map Screen**: OpenStreetMap dengan supplier locations dan geolocation
- **Compass Widget**: Navigasi menggunakan magnetometer sensor
- **Currency API**: Kurs mata uang dari exchangerate-api.com
- **Cloud Sync**: Firestore integration untuk backup data

---

## 🛠️ Teknologi

### Core Framework
- **Flutter** SDK 3.22+ (Dart 3.4+)
- **State Management**: Provider Pattern
- **Local Database**: SQLite (sqflite package)
- **Cloud Database**: Firebase Cloud Firestore
- **Session Storage**: SharedPreferences

### Dependencies

| Kategori | Package | Fungsi |
|:---|:---|:---|
| **UI/UX** | `google_fonts`, `flutter_svg`, `cached_network_image` | Typography, SVG, image caching |
| **Features** | `mobile_scanner`, `image_picker`, `permission_handler`, `path_provider`, `fl_chart`, `intl` | Scanner, camera, permissions, charts, formatting |
| **Cloud & Network** | `flutter_map`, `latlong2`, `geolocator`, `sensors_plus`, `http`, `firebase_core`, `cloud_firestore` | Maps, location, sensors, API, Firebase |

---

## 🏗️ Arsitektur Project

```
lib/
├── main.dart
├── utils/
│   └── constants.dart
├── models/                      # Data models (8 models)
├── database/
│   └── db_helper.dart           # SQLite operations
├── services/                    # Business logic (10 services)
│   ├── auth_service.dart
│   ├── product_service.dart
│   ├── cart_service.dart
│   ├── transaction_service.dart
│   ├── image_service.dart
│   ├── location_service.dart
│   ├── sensor_service.dart
│   ├── api_service.dart
│   ├── firestore_service.dart
│   └── notification_service.dart
├── screens/                     # UI Screens (10+ screens)
│   ├── login_screen.dart
│   ├── map_screen.dart
│   ├── profile_screen.dart
│   ├── admin/
│   └── user/
└── widgets/                     # Reusable components
    ├── product_card.dart
    └── compass_widget.dart
```

**Design Pattern**: Repository Pattern + Service Layer + Provider State Management

---

## 📦 Instalasi

### Prasyarat
- Flutter SDK ^3.12.2
- Android Studio / VS Code dengan Flutter extension
- Emulator Android atau perangkat fisik

### Langkah Implementasi

```bash
# 1. Kloning repository
git clone https://github.com/UG244/PPB2026_Kelompok04_BlueMart.git
cd PPB2026_Kelompok04_BlueMart

# 2. Instalasi dependensi
flutter pub get

# 3. Konfigurasi Firebase (opsional untuk cloud sync)
#    - Buat project di Firebase Console
#    - Download google-services.json ke android/app/
#    - Jalankan: flutterfire configure

# 4. Eksekusi aplikasi
flutter run
```

---

## 👥 Pembagian Tugas

Penugasan anggota kelompok disusun berdasarkan kompetensi dan spesialisasi masing-masing:

| No | Nama | NIM | Area Tanggung Jawab |
|:---:|:---|:---|:---|
| 1 | **Fiji Firmanda** | 240040099 | **Sistem Notifikasi** — Implementasi notification service layer, helper functions, dan integrasi antar komponen UI. Mengembangkan sistem real-time notification dengan tab filtering, badge management, dan read/unread status tracking. |
| 2 | **Kadek Novan S. Chandra** | 240040107 | **Layanan Peta & Lokasi** — Pengembangan map screen dengan OpenStreetMap integration, address selection dengan geolocation support, dan lokasi supplier management. Bertanggung jawab atas struktur project dan organisasi file. |
| 3 | **I Gede Sandi Pujanta** | 240040129 | **Sensor & Database** — Implementasi SensorService (magnetometer compass dan accelerometer shake detection), fondasi screens untuk User dan Admin flows, sistem checkout lengkap dengan payment/shipping integration, serta desain dan implementasi database schema dengan operasi CRUD. |

---

## 📊 Evaluasi

Aplikasi ini telah memenuhi seluruh kriteria penilaian:

- ✅ Kelengkapan fitur: 8 fitur wajib + fitur tambahan
- ✅ Kesesuaian solusi dengan permasalahan
- ✅ Implementasi teknologi mobile (Flutter, sensors, camera, location)
- ✅ Kualitas UI/UX dengan Material Design 3
- ✅ Dokumentasi lengkap dan struktur project yang baik
- ✅ Kontribusi anggota terverifikasi melalui Git history

---

## 📄 Lisensi

**© 2026 Kelompok 04 — Teknologi Informasi**  
Program Studi Teknologi Informasi — Universitas [Nama Universitas]  
Project ini disubmit untuk memenuhi tugas akhir mata kuliah Pemrograman Piranti Bergerak (TI253311)

**Kontak:**
- Fiji Firmanda — 240040099
- Kadek Novan Suhaliem Chandra — 240040107
- I Gede Sandi Pujanta — 240040129

---

## 🔗 Repository

**GitHub**: https://github.com/UG244/PPB2026_Kelompok04_BlueMart

---

*Dokumentasi ini disusun sesuai dengan standar PROJECT.md mata kuliah Pemrograman Piranti Bergerak, Semester IV, Tahun Akademik 2025/2026.*