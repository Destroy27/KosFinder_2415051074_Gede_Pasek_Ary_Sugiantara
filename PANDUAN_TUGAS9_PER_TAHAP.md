# Panduan Tugas 9 — KosFinder (Per Tahap)

Panduan ini mengikuti urutan bagian pada `Worksheet_9_Authentication_Authorization_Push_Notifications-yuda.docx`. Kerjakan berurutan; setiap tahap punya bukti (screenshot) dan commit sendiri.

**Identitas:** Gede Pasek Ary Sugiantara — 2415051074 — PTI 5C

**Project:** `D:\Gede  Pasek Ary Sugiantara\Kuliah\Pemrograman Mobile\Tugas 9\kosfinder`

---

## Tahap 0 — Persiapan

1. Buka terminal di folder project.

   ```bash
   cd "D:\Gede  Pasek Ary Sugiantara\Kuliah\Pemrograman Mobile\Tugas 9\kosfinder"
   flutter pub get
   ```

2. Pastikan project sehat:

   ```bash
   flutter analyze     # harus "No issues found!"
   flutter test        # harus "All tests passed!"
   ```

3. Cek repository:

   ```bash
   git status
   git log --oneline
   git branch
   ```

4. Buat branch pengerjaan:

   ```bash
   git checkout -b feature/auth-notification
   ```

**Isi worksheet:** Repository URL, Nama branch.

---

## Tahap 1 — Supabase (wajib sebelum menjalankan aplikasi)

1. Buka [Supabase Dashboard](https://supabase.com/dashboard) → **New project**.
   - Nama: `kosfinder`
   - Region: Singapore (terdekat)
   - Simpan database password.
2. Tunggu project selesai provisioning (±2 menit).
3. Buka **SQL Editor** → **New query** → copy seluruh isi `tugas9_supabase.sql` → **Run**.
   - Pesan sukses: `Success. No rows returned`.
4. Buka **Project Settings → API Keys**:
   - Salin **Project URL**.
   - Salin **publishable key** (atau `anon` key).
5. Buka `lib/config/supabase_config.dart`, ganti:

   ```dart
   static const String url = 'https://xxxxxxxx.supabase.co';
   static const String publishableKey = 'sb_publishable_xxxxxxxxxxxx';
   ```

6. (Disarankan) **Authentication → Providers → Email** → matikan **Confirm email**.
   Dengan begitu, registrasi langsung mendapat session dan bisa masuk ke Home.
7. Jalankan aplikasi:

   ```bash
   flutter run
   ```

8. Bila kredensial salah, aplikasi menampilkan halaman **"Siapkan backend dulu"**, bukan crash.

**Bukti:** screenshot SQL Editor setelah Run + tabel `kos` di Table Editor.

---

## Tahap 2 — Praktik 1: Authentication Flow (Tugas 1)

Halaman yang sudah tersedia:

| File | Isi |
| --- | --- |
| `lib/pages/register_page.dart` | Nama, email, password, konfirmasi password, pilihan role |
| `lib/pages/login_page.dart` | Email, password, tombol masuk |
| `lib/pages/home_page.dart` | Halaman utama setelah login |
| `lib/services/auth_service.dart` | `register`, `login`, `logout`, cek session |

Yang harus kamu lakukan:

1. Jalankan aplikasi.
2. **Daftar** akun pemilik kos:
   - Nama: `Pemilik A`
   - Email: `owner.a@kosfinder.test`
   - Password: `rahasia123`
   - Daftar sebagai: **Pemilik kos**
3. Setelah berhasil, aplikasi masuk ke Home dan menampilkan nama, email, serta role.
4. Logout, lalu **daftar akun kedua** (`owner.b@kosfinder.test`) dan satu akun pencari kos (`seeker@kosfinder.test`).
5. Uji login salah:
   - Password salah → snackbar "Email atau password salah."
   - Email tidak terdaftar → pesan yang sama (Supabase tidak membocorkan email mana yang ada).
   - Field kosong → validasi form muncul di bawah field.

**Screenshot wajib:** Register, Login, login berhasil, login gagal.

**Isi tabel pengujian** di worksheet (kolom Hasil) setelah mencoba.

**Commit:**

```bash
git add .
git commit -m "feat: implement user authentication"
```

Salin hash commit ke worksheet:

```bash
git log --oneline -1
```

---

## Tahap 3 — Praktik 2: Logout dan Session (Tugas 2)

1. **Skenario A — session bertahan**
   - Login → Home.
   - Tutup aplikasi dari recent apps (jangan uninstall).
   - Buka lagi → langsung Home tanpa login.
2. **Skenario B — logout**
   - Home → ikon logout kanan atas → konfirmasi → Login Page.
3. Cek di kode:
   - `main.dart` → `AuthService.instance.isLoggedIn ? HomePage : LoginPage`
   - `AuthService.listenAuthChanges()` menangani `AuthChangeEvent.signedOut`.

**Jawaban pertanyaan "Mengapa session perlu diperiksa saat aplikasi pertama kali dijalankan?"**

> Session adalah bukti bahwa pengguna sudah terautentikasi. Supabase menyimpan session di perangkat dan memulihkannya saat `Supabase.initialize()`. Tanpa pemeriksaan session, pengguna yang sudah login harus memasukkan email dan password setiap kali membuka aplikasi, dan aplikasi tidak tahu identitas mana yang harus dipakai untuk mengambil data. Pemeriksaan ini juga mencegah tampilan Home muncul untuk pengguna yang session-nya sudah berakhir atau dicabut.

**Commit:**

```bash
git add .
git commit -m "feat: implement authentication session and logout"
```

---

## Tahap 4 — Praktik 3: Role Pengguna (Tugas 3)

Role dibuat otomatis oleh trigger `public.handle_new_user()`:

| Role | Arti |
| --- | --- |
| `seeker` | Pencari kos: melihat daftar dan detail kos |
| `owner` | Pemilik kos: menambah, mengubah, menghapus kos miliknya |
| `admin` | Mengelola seluruh data |

Yang ditampilkan Home:

- Nama dan email dari tabel `profiles`.
- Badge role di kanan atas kartu profil.
- Baris statistik: jumlah kos tersedia, kos milik saya, role.

Uji:

1. Login sebagai owner → badge **Pemilik kos**.
2. Login sebagai seeker → badge **Pencari kos** dan info bahwa menu tambah kos tidak tersedia.

Jadikan akun admin (setelah akun terdaftar):

```sql
update public.profiles
set role = 'admin'
where email = 'admin@kosfinder.test';
```

Login ulang akun tersebut → badge **Admin** dan menu **Admin** muncul.

**Screenshot:** halaman Home yang memperlihatkan Nama, Email, Role.

**Commit:**

```bash
git add .
git commit -m "feat: implement user roles"
```

---

## Tahap 5 — Praktik 4: Authorization pada UI (Tugas 4)

Perbedaan tampilan berdasarkan role:

| Role | Yang terlihat |
| --- | --- |
| Seeker | Daftar kos, detail kos, pencarian. Tanpa tombol tambah/ubah/hapus |
| Owner | Tambah Kos (FAB), menu **Kos Saya**, ubah/hapus pada kos miliknya |
| Admin | Semua di atas + menu **Admin** untuk verifikasi dan hapus data |

Implementasi:

- `lib/widgets/role_guard.dart` — menampilkan child hanya untuk role tertentu.
- `home_page.dart` — FAB hanya dirender bila `profile.canManageKos`.
- `my_kos_page.dart` — hanya memuat `owner_id = auth.uid()`.
- `admin_page.dart` — jika role bukan admin, menampilkan **Akses ditolak**.

Uji:

1. Login seeker → FAB dan menu **Kos Saya** tidak ada.
2. Login owner → tambah satu kos → kartu menampilkan label **Milik saya**.
3. Login admin → menu **Admin** muncul → verifikasi kos.

**Screenshot:** tampilan sebagai seeker, sebagai owner, dan sebagai admin.

**Commit:**

```bash
git add .
git commit -m "feat: implement role based interface authorization"
```

---

## Tahap 6 — Praktik 5 & 6: RLS dan Security Testing (Tugas 5)

RLS sudah dibuat oleh `tugas9_supabase.sql`:

| Operasi | Policy |
| --- | --- |
| SELECT | `kos_select_authenticated` — semua user login |
| INSERT | `kos_insert_owner` — `owner_id = auth.uid()` dan role owner/admin |
| UPDATE | `kos_update_own` — hanya pemilik |
| DELETE | `kos_delete_own` — hanya pemilik |
| ALL (admin) | `kos_admin_all` — `is_admin()` |

Cek policy:

```sql
select tablename, policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'kos';

select relname, relrowsecurity
from pg_class
where relname = 'kos';   -- harus true
```

### Pengujian dua akun

1. Login User A (owner) → tambah kos "Kos A".
2. Buka detail kos, salin **Owner ID** atau id kos dari Table Editor.
3. Logout → login User B (owner).
4. Buka **Kos Saya** → kos A tidak muncul.
5. Di daftar semua kos, kos A tetap terlihat (SELECT diizinkan) tetapi tanpa menu ubah/hapus.
6. Uji lewat SQL Editor (paling meyakinkan):

```sql
begin;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"UUID_USER_B","role":"authenticated"}',
  true
);
update public.kos set name = 'HACK' where id = 'UUID_KOS_USER_A'; -- UPDATE 0
delete from public.kos where id = 'UUID_KOS_USER_A';              -- DELETE 0
rollback;
```

Hasil `UPDATE 0` dan `DELETE 0` membuktikan policy menolak operasi, bukan hanya tombolnya disembunyikan.

**Jawaban analisis "Apa yang terjadi bila authorization hanya pada UI?"**

> Aplikasi Flutter dapat dibongkar atau dihubungi ulang melalui HTTP client. Jika database tidak memiliki policy, penyerang dapat memakai anon key yang sama untuk memanggil REST API Supabase dan mengubah atau menghapus data milik pengguna lain. Menyembunyikan tombol hanya mengubah tampilan, bukan hak akses. Karena itu aturan kepemilikan harus ditegakkan di database melalui RLS agar berlaku untuk semua jalur akses.

**Screenshot:** daftar policy, operasi yang diizinkan, operasi yang ditolak.

**Commit:**

```bash
git add .
git commit -m "security: implement row level security policies"
```

---

## Tahap 7 — Praktik 7: Konfigurasi Firebase (wajib untuk FCM)

> Bagian ini tidak bisa dikerjakan tanpa akun Google/Firebase milikmu.

1. Buka [Firebase Console](https://console.firebase.google.com) → **Add project** → nama `kosfinder` → matikan Google Analytics (opsional).
2. Install tools:

   ```bash
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```

3. Dari root project:

   ```bash
   flutterfire configure
   ```

   Pilih project `kosfinder`, platform **android** (dan `web` bila ingin uji di Chrome).
   Perintah ini membuat `lib/firebase_options.dart`, mengunduh `android/app/google-services.json`, dan menambahkan plugin Google Services.

4. Cek `android/app/build.gradle.kts` sudah memuat:

   ```kotlin
   plugins {
       id("com.google.gms.google-services")
   }
   ```

   (FlutterFire menambahkannya otomatis. Bila tidak, tambahkan manual.)

5. Jalankan:

   ```bash
   flutter run
   ```

   Log akan menampilkan status inisialisasi Firebase. Bila `google-services.json` belum ada, aplikasi tetap berjalan tanpa notifikasi (tidak crash).

**Screenshot:** halaman Firebase Console project + file `google-services.json` (sensor bagian tertentu bila perlu).

**Commit:**

```bash
git add .
git commit -m "chore: configure firebase cloud messaging"
```

---

## Tahap 8 — Praktik 8 & 9: Permission dan Token (Tugas 6 & 7)

1. Jalankan di **HP Android** (USB debugging) atau emulator dengan Google Play Services.
2. Saat Home terbuka, aplikasi meminta izin notifikasi (Android 13+).
3. Status permission tampil pada kartu **Notifikasi**:
   - `authorized` — diizinkan
   - `denied` — ditolak
   - `notDetermined` — belum dipilih
4. Tekan **Ambil token** → token tampil dan otomatis disimpan ke tabel `device_tokens`.
5. Cek log terminal:

   ```text
   FCM Token: dQw4w9...
   Notification permission: authorized
   ```

6. Cek database:

   ```sql
   select token, platform, updated_at
   from public.device_tokens
   order by updated_at desc;
   ```

**Jawaban "Mengapa token tidak boleh dianggap selalu sama?"**

> Token FCM mewakili satu instalasi aplikasi pada satu perangkat, bukan satu orang. Token dapat berubah ketika aplikasi di-install ulang, data aplikasi dihapus, aplikasi dipulihkan ke perangkat lain, atau FCM melakukan rotasi. Karena itu aplikasi harus mendengarkan `onTokenRefresh` dan memperbarui baris di `device_tokens`. Jika backend menyimpan token lama, notifikasi akan dikirim ke target yang tidak valid dan pengguna tidak menerimanya.

**Screenshot:** dialog izin notifikasi, status permission, token pada log/aplikasi (sensor sebagian).

---

## Tahap 9 — Praktik 10 & 11: Menerima dan Mengirim Notifikasi (Tugas 8)

### Kirim test notification

1. Jalankan aplikasi, salin token.
2. Firebase Console → **Cloud Messaging** → **Create notification**:
   - Title: `KosFinder`
   - Text: `Kos baru tersedia di sekitar kampus.`
3. **Send test message** → tempel token → **Test**.

### Uji tiga kondisi

| Kondisi | Langkah | Yang diharapkan |
| --- | --- | --- |
| Foreground | Aplikasi terbuka | Snackbar di dalam aplikasi + log `[FOREGROUND]` |
| Background | Tekan Home | Notifikasi muncul di status bar |
| Terminated | Tutup dari recent apps | Notifikasi tetap masuk ke status bar |

### Bonus — notifikasi membuka detail kos

1. Di **Additional options → Custom data**, tambahkan:

   ```text
   Key   : kos_id
   Value : <uuid kos dari tabel kos>
   ```

2. Kirim notifikasi, lalu **tap** notifikasi tersebut.
3. Aplikasi terbuka pada **Detail Kos** sesuai `kos_id`.

**Screenshot:** Firebase Console, notifikasi pada perangkat, log `[FOREGROUND]`/`[BACKGROUND]`, detail kos setelah tap.

**Commit:**

```bash
git add .
git commit -m "feat: implement push notification with FCM"
git push -u origin feature/auth-notification
```

---

## Tahap 10 — Bukti Akhir dan Worksheet

1. Ambil semua screenshot pada daftar **U. Bukti Akhir** di worksheet.
2. Isi worksheet:
   - Identitas, URL repository, branch, latest commit hash.
   - Kolom **Hasil** pada tabel pengujian (isi sesuai hasil nyata).
   - Pertanyaan analisis (1–5), refleksi, dan bagian penggunaan AI.
   - Centang checklist **Definition of Done** hanya untuk yang benar-benar sudah diuji.
3. Pastikan repository berisi minimal 7 commit dengan pesan sesuai worksheet.
4. Kumpulkan worksheet dan tautan repository.

---

## Daftar Periksa Cepat

- [ ] `flutter analyze` bersih
- [ ] `flutter test` lulus
- [ ] SQL `tugas9_supabase.sql` sudah dijalankan
- [ ] `supabase_config.dart` sudah diisi URL + publishable key
- [ ] Registrasi, login, logout, session berjalan
- [ ] Role tampil dan membedakan menu
- [ ] Dua akun diuji; update/delete lintas akun ditolak
- [ ] `flutterfire configure` selesai dan `google-services.json` ada
- [ ] Izin notifikasi diminta dan statusnya tercatat
- [ ] Token FCM tampil dan tersimpan di `device_tokens`
- [ ] Notifikasi diterima pada foreground, background, terminated
- [ ] Semua screenshot terkumpul
- [ ] Commit bertahap + push ke GitHub

---

## Troubleshooting

| Gejala | Penyebab | Solusi |
| --- | --- | --- |
| Halaman "Siapkan backend dulu" | Config masih placeholder atau URL/key salah | Isi `supabase_config.dart`, hot restart (`R`) |
| `relation "public.kos" does not exist` | SQL belum dijalankan | Jalankan `tugas9_supabase.sql` |
| Registrasi berhasil tetapi tidak masuk Home | Confirm email aktif | Cek email, atau nonaktifkan Confirm email |
| `new row violates row-level security policy` saat tambah kos | Role masih `seeker` | Jadikan `owner` lewat SQL, lalu login ulang |
| `profiles` kosong setelah registrasi | Trigger belum ada saat akun dibuat | Jalankan ulang bagian trigger + backfill pada SQL |
| Tombol ubah/hapus tidak muncul untuk admin | Cache profil lama | Logout lalu login ulang |
| Token FCM `null` | Firebase belum dikonfigurasi / tanpa Google Play Services | Jalankan `flutterfire configure`, pakai HP/emulator Play Store |
| Notifikasi tidak muncul di foreground | Normal di Android | Aplikasi menampilkan snackbar; cek log `[FOREGROUND]` |
| Notifikasi tidak muncul di background/terminated | Izin ditolak | Aktifkan izin notifikasi di pengaturan aplikasi |
