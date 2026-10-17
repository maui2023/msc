# MotoSewa — Platform SaaS Marketplace Sewaan Motosikal

[![Laravel](https://img.shields.io/badge/Laravel-13.x-red.svg)](https://laravel.com)
[![PHP](https://img.shields.io/badge/PHP-8.2%2B%20%7C%208.3%20%7C%208.5-blue.svg)](https://php.net)
[![Database](https://img.shields.io/badge/Database-MariaDB%20%7C%20SQLite3-orange.svg)](https://mariadb.org)
[![Payment](https://img.shields.io/badge/Payment-AffanPay%20%7C%20Manual%20Cash%2FQR-green.svg)](#)

**MotoSewa** ialah platform SaaS marketplace berbilang pemilik (*multi-vendor*) yang memudahkan operasi penyewaan motosikal. Sistem ini menghubungkan penyewa dengan pengusaha motosikal sewa tempatan (contoh: Cameron Highlands dan seluruh Malaysia).

Platform ini dibina secara modular dan berperingkat, memastikan **pengurusan tempahan (booking lifecycle)** dipisahkan sepenuhnya (*decoupled*) daripada **enjin pembayaran (payment & settlement)**.

---

## 📑 1. Pembahagian Modul PRD (Dokumentasi Tempatan)

Spesifikasi sistem telah dipecahkan kepada dokumen modular bagi membolehkan pembangunan dilakukan fasa demi fasa secara teratur:

| Modul | Dokumen PRD | Skop & Tanggungjawab Utama |
|---|---|---|
| **Modul 1: Auth** | [`PRD-module-auth.md`](file:///home/miqa/github/msc/PRD-module-auth.md) | Pendaftaran, log masuk, kawalan peranan (`renter`, `owner`, `admin`), keselamatan sesi, rate limiting, dan lejar audit sistem. |
| **Modul 2: Owner** | [`PRD-module-owner.md`](file:///home/miqa/github/msc/PRD-module-owner.md) | Profil perniagaan kedai, lokasi premis, waktu operasi, langganan SaaS pemilik (Trial 30 hari / RM15 sebulan per motor / RM1 per tempahan), dan papan pemuka pemilik. |
| **Modul 3: Motorcycles** | [`PRD-module-motorcycles.md`](file:///home/miqa/github/msc/PRD-module-motorcycles.md) | Katalog motosikal, galeri imej, kategori CC, pakej harga fleksibel (12j, 24j, 36j, 48j, hari biasa vs hujung minggu), dan lejar audit harga (`rental_price_ledger`). |
| **Modul 4: Booking** | [`PRD-module-booking.md`](file:///home/miqa/github/msc/PRD-module-booking.md) | Kitaran hayat tempahan, semakan pertindihan tarikh (*concurrency-safe*), pegangan sementara 10 minit (*temporary hold*), muat naik lesen memandu bagi setiap motosikal yang ditempah, dan serahan/pemulangan fizikal. |
| **Modul 5: Payment** | [`PRD-module-payment.md`](file:///home/miqa/github/msc/PRD-module-payment.md) | Integrasi gerbang dalam talian AffanPay, pengesahan webhook pelayan-ke-pelayan dengan kawalan *idempotency*, rekod pembayaran manual tunai/QR oleh pemilik, pemulangan wang (*refund*), dan saluran pelepasan dana 48 jam (*settlement*). |

> 🔒 **Nota Privasi Repositori:** Mengikut ketetapan fail [`.gitignore`](file:///home/miqa/github/msc/.gitignore), semua fail dokumentasi markdown (`*.md`) kekal selamat dalam repositori tempatan pemaju dan tidak dimuat naik ke git awam, kecuali fail `README.md` ini.

---

## 🎨 2. Prototaip & Mockup Interaktif (`docs/`)

Bagi melihat aliran skrin sistem secara langsung, prototaip berasaskan **HTML5 + Bootstrap 5.3** telah disediakan di dalam folder [`docs/`](file:///home/miqa/github/msc/docs):

| Peranan / Komponen | Fail Mockup | Reka Bentuk & Paparan Sasaran | Ciri Utama Diuji |
|---|---|---|---|
| **Pusat Navigasi** | [`docs/index.html`](file:///home/miqa/github/msc/docs/index.html) | Desktop & Mobile | Peta aliran keseluruhan sistem, pengenalan persona, dan suis peranan pantas. |
| **Penyewa (Renter)** | [`docs/renter.html`](file:///home/miqa/github/msc/docs/renter.html) | **PWA Mobile-Only** (Tanpa Desktop) | Carian motosikal, pemasa *Hold 10 Minit* masa nyata, pecahan harga (Deposit RM50 + Caj RM2), muat naik lesen per motor, pas QR serahan, dan kalkulator refund. |
| **Pemilik (Owner)** | [`docs/owner.html`](file:///home/miqa/github/msc/docs/owner.html) | **Desktop + Mobile Responsive** | Papan pemuka serahan/pulang, modal *Tempahan Walk-In* pantas (Tunai/QR manual), pengurusan armada & pakej 12j/24j/36j/48j, lejar audit harga, status langganan SaaS, dan penyata *settlement 48 jam*. |
| **Admin Platform** | [`docs/admin.html`](file:///home/miqa/github/msc/docs/admin.html) | **Desktop-Focused** (Minimal Mobile) | Pemantauan multi-vendor berketumpatan tinggi, kelulusan pendaftaran kedai, audit tempahan global, konsol pelepasan dana, dan penjelajah `audit_logs`. |
| **Gateway Mock** | [`docs/affanpay.html`](file:///home/miqa/github/msc/docs/affanpay.html) | Checkout Sandbox | Simulasi pembayaran online FPX / Kad dengan pencetus *server webhook callback* automatik. |

Buka fail [`docs/index.html`](file:///home/miqa/github/msc/docs/index.html) dalam pelayar web anda untuk memulakan demonstrasi.

---

## 🏛️ 3. Senibina Pemisahan Tempahan & Pembayaran (Decoupled Architecture)

Bagi memastikan kod kekal bersih, mudah diuji, dan boleh diubah suai pada masa hadapan:

```
┌────────────────────────────────┐         ┌────────────────────────────────┐
│         MODUL TEMPAHAN         │         │        MODUL PEMBAYARAN        │
│        (Booking Domain)        │         │        (Payment Domain)        │
├────────────────────────────────┤         ├────────────────────────────────┤
│ • Status: pending_payment,     │         │ • Status: pending, paid,       │
│   confirmed, ready_for_pickup, │         │   failed, refund_pending,      │
│   ongoing, completed, dll.     │  Events │   partially_refunded, refunded │
│ • Tarikh & Masa Sewaan         │ ──────> │ • Provider: AffanPay / Manual  │
│ • Snapshot Harga & Polisi      │ <────── │ • Kaedah: Online / Tunai / QR  │
│ • Semakan Pertindihan Inventori│         │ • Webhook Signature & Idem.    │
│ • Rekod Lesen per Motosikal    │         │ • Penyata Pelepasan (48 Jam)   │
└────────────────────────────────┘         └────────────────────────────────┘
```

### Mengapa Logik Ini Dipisahkan?
1. **Bebas Daripada Gateway Tertentu (*Gateway Agnostic*):** Modul Tempahan tidak mengandungi sebarang kolum gateway seperti token API, secret, payload AffanPay, atau nombor kad. Jika pembekal pembayaran bertukar, domain tempahan tidak terjejas.
2. **Kitaran Transaksi Berbilang:** Satu rekod tempahan boleh mempunyai sifar bayaran (jika terbatal/tamat tempoh hold), satu bayaran penuh, atau pelbagai rekod transaksi kewangan (contoh: bayaran sewaan asal, pelepasan deposit keselamatan, atau pemulangan wang separa).
3. **Pembangunan & Ujian Berperingkat:** Pembangun boleh membangunkan dan menguji modul tempahan sepenuhnya menggunakan *Mock/Fake Payment Gateway* tanpa memerlukan talian internet atau kelulusan akaun peniaga sebenar daripada AffanPay.

---

## 📊 4. Gambaran Pangkalan Data (Database Schema)

Sistem ini dilengkapi dengan dua kaedah penyediaan skema pangkalan data:
1. **[`schema.sql`](file:///home/miqa/github/msc/schema.sql):** Skrip SQL penuh (MariaDB / MySQL) sedia untuk dijalankan terus ke dalam database.
2. **Laravel Migrations ([`database/migrations/`](file:///home/miqa/github/msc/database/migrations)):** 5 fail migrasi berstruktur untuk Laravel 13 mengikut urutan fasa pembangunan:
   - `2026_10_17_000001_create_users_and_auth_tables.php`
   - `2026_10_17_000002_create_owner_profiles_and_subscriptions_tables.php`
   - `2026_10_17_000003_create_motorcycles_and_rates_tables.php`
   - `2026_10_17_000004_create_bookings_and_licenses_tables.php`
   - `2026_10_17_000005_create_payments_settlements_and_refunds_tables.php`

### Ringkasan Entiti Utama

```
users (Pengguna: Renter / Owner / Admin)
 ├── owner_profiles (Profil Kedai Pemilik)
 │    ├── owner_subscriptions (Langganan SaaS Kedai)
 │    ├── motorcycles (Katalog Motosikal)
 │    │    ├── motorcycle_images (Galeri Gambar)
 │    │    ├── rental_rates (Pakej Harga: 12j, 24j, 36j, 48j)
 │    │    └── rental_price_ledger (Sejarah Perubahan Harga)
 │    └── settlements (Penyata Payout Pemilik)
 └── bookings (Tempahan Kenderaan)
      ├── renter_licenses (Lesen Memandu bagi Setiap Motosikal)
      ├── booking_status_histories (Jejak Peralihan Status Tempahan)
      ├── payments (Rekod Transaksi Kewangan AffanPay / Tunai / QR)
      │    └── payment_webhook_events (Idempotensi Webhook)
      └── refunds (Rekod Pemulangan Wang)
```

---

## 💼 5. Keputusan Perniagaan Utama (Key Business Decisions)

1. **Pegangan Sementara (10-Minute Hold):** Apabila penyewa memulakan tempahan di marketplace, motosikal dikunci selama 10 minit bagi mengelakkan dua pelanggan membayar unit yang sama secara serentak. Jika bayaran tidak disahkan dalam tempoh ini, inventori dilepaskan secara automatik.
2. **Deposit Keselamatan:** Tetapan lalai ialah **RM50 per tempahan** (bukan per motosikal). Pemilik bebas mengubah atau mematikan deposit ini. Deposit disimpan secara berasingan daripada hasil sewaan.
3. **Caj Transaksi Tambahan:** Surcharge lalai sebanyak **RM2.00** dikenakan kepada penyewa semasa checkout (RM1 kos gateway AffanPay + RM1 fi platform). Caj ini tidak dipulangkan semasa pembatalan biasa.
4. **Polisi Pembatalan & Kuasa Pemilik:**
   - Pembatalan **≥ 24 jam sebelum mula:** Refund 75% daripada sewaan layak.
   - Pembatalan **12 hingga 24 jam sebelum mula:** Refund 50%.
   - Pembatalan **< 12 jam sebelum mula:** 0% refund secara lalai.
   - Pemilik motosikal mempunyai kata putus dalam meluluskan sebarang permohonan pembatalan.
5. **Lesen Memandu per Motosikal:** Jika satu akaun menempah tiga (3) motosikal untuk kumpulannya, sistem mewajibkan muat naik tiga rekod lesen berbeza untuk memastikan pematuhan undang-undang jalan raya Malaysia.
6. **Pelepasan Dana (Settlement 48 Jam):** Dana online masuk ke akaun platform terlebih dahulu. Sasaran aliran pelepasan ialah AffanPay melepaskan kepada platform dalam 24 jam, dan platform melepaskan kepada pemilik dalam 24 jam berikutnya (jumlah sasaran: 48 jam).

---

## 🚀 6. Panduan Pemasangan & Pembangunan (Development Setup)

### Keperluan Sistem
- PHP 8.2 atau lebih terkini (disokong penuh pada PHP 8.3 & 8.5)
- Composer 2.x
- MariaDB 10.6+ (Production / Staging) atau SQLite 3 (Development Tempatan)

### Langkah Pemasangan

1. **Klon Repositori:**
   ```bash
   git clone git@github.com:your-org/msc.git
   cd msc
   ```

2. **Tetapkan Fail Persekitaran (`.env`):**
   ```bash
   cp .env.example .env
   ```
   Untuk pembangunan pantas menggunakan SQLite:
   ```env
   DB_CONNECTION=sqlite
   # Pangkalan data SQLite akan disimpan di database/database.sqlite
   ```
   Untuk pengujian MariaDB:
   ```env
   DB_CONNECTION=mariadb
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=motosewa_db
   DB_USERNAME=root
   DB_PASSWORD=your_password
   ```

3. **Jalankan Migrasi Pangkalan Data:**
   ```bash
   php artisan migrate
   ```
   *Atau, sekiranya menggunakan SQL mentah secara terus pada MariaDB:*
   ```bash
   mariadb -u root -p motosewa_db < schema.sql
   ```

4. **Konfigurasi Gateway AffanPay (Ujian Sandbox):**
   ```env
   AFFANPAY_BASE_URL=https://sandbox.affanpay.com/api/v1
   AFFANPAY_MERCHANT_ID=sandbox_merchant_id
   AFFANPAY_API_KEY=sandbox_api_key
   AFFANPAY_SECRET=sandbox_secret
   AFFANPAY_WEBHOOK_SECRET=sandbox_webhook_secret
   AFFANPAY_MODE=sandbox
   ```

---

## 📝 7. Lesen & Hak Cipta
Hak cipta terpelihara © 2026 MotoSewa. Dibangunkan untuk kegunaan pengusaha dan penyewa motosikal di Malaysia.
